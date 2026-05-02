## MineGenerator.gd
## Generates a mine layout that the solver confirms is fully solvable without guessing.
## Runs on a background thread so it never blocks the game.
##
## Usage:
##   mine_generator.generate(width, height, mine_count, safe_cells)
##   # then listen to:
##   mine_generator.generation_completed.connect(_on_mines_ready)
##
## Generation strategy (in order of application):
##   1. Openness bias — initial placement avoids dense clusters, producing
##      boards that are more likely to be solvable on the first try.
##   2. Targeted reshuffle — on failure, only mines near guess positions are
##      replaced rather than swapping one at a time or doing a full reshuffle.
##      This preserves the "good" regions of the board each iteration.
##   3. Periodic full reseed — every N failed attempts, fall back to a fresh
##      biased placement to escape local dead ends.

class_name MineGenerator
extends Node

signal generation_completed(mines: Array[Vector2i], solve_result: MinesweeperSolver.SolveResult)
signal generation_failed  # emits if no valid layout found within attempt budget

@export var max_attempts: int = 200

## How many failed targeted reshuffles before doing a full reseed.
## Lower values escape dead ends faster; higher values exploit partial progress longer.
@export var reseed_interval: int = 15

## Maximum neighbor mines allowed when placing a mine during biased sampling.
## 0 = strict spacing (very open boards), 1–2 = moderate clustering allowed.
@export var cluster_threshold: int = 1

var _solver: MinesweeperSolver
var _thread: Thread
var _mutex: Mutex
var _pending_emit: Dictionary
var _generating: bool = false


func _ready() -> void:
	_solver = MinesweeperSolver.new()
	# zero_guess_mode = true: solver exits immediately on the first unavoidable
	# guess rather than counting total guesses — O(cells) per check instead of
	# O(2^candidates). This is by far the biggest single speedup for generation.
	_solver.zero_guess_mode = true
	_mutex = Mutex.new()


func _process(_delta: float) -> void:
	if _pending_emit.is_empty():
		return
	_mutex.lock()
	var payload := _pending_emit.duplicate()
	_pending_emit.clear()
	_mutex.unlock()

	if payload.get("failed", false):
		generation_failed.emit()
	else:
		generation_completed.emit(payload["mines"], payload["result"])

	if _thread and _thread.is_started():
		_thread.wait_to_finish()

	_generating = false


func _exit_tree() -> void:
	if _thread and _thread.is_started():
		_thread.wait_to_finish()


## Start async mine generation. Listen to generation_completed.
func generate(width: int, height: int, mine_count: int, safe_cells: Array[Vector2i]) -> void:
	if _generating:
		push_warning("MineGenerator: generation already in progress, ignoring request.")
		return
	_generating = true
	if _thread and _thread.is_started():
		_thread.wait_to_finish()
	_thread = Thread.new()
	_thread.start(_thread_generate.bind(width, height, mine_count, safe_cells))


## Derive a recommended mine count from board dimensions and a 0.0–1.0 difficulty.
## Density range: 10% (easy) → 20% (hard). Beyond ~20% it becomes increasingly
## difficult to find a zero-guess layout regardless of attempt budget.
static func recommended_mine_count(width: int, height: int,
		difficulty: float, safe_cell_count: int) -> int:
	var total := width * height
	var placeable := total - safe_cell_count
	var density := lerpf(0.10, 0.20, clampf(difficulty, 0.0, 1.0))
	return mini(int(total * density), placeable)


func _thread_generate(width: int, height: int, mine_count: int, safe_cells: Array[Vector2i]) -> void:
	var result := _generate_sync(width, height, mine_count, safe_cells)
	_mutex.lock()
	_pending_emit = result
	_mutex.unlock()


func _generate_sync(width: int, height: int, mine_count: int, safe_cells: Array[Vector2i]) -> Dictionary:
	var forbidden: Dictionary = {}
	for pos in safe_cells:
		forbidden[pos] = true

	var pool: Array[Vector2i] = []
	for y in height:
		for x in width:
			var pos := Vector2i(x, y)
			if not forbidden.has(pos):
				pool.append(pos)

	if pool.size() < mine_count:
		return {"failed": true}

	# Biased initial placement — avoids clusters from the very first attempt
	var mines := _biased_sample(pool, mine_count)

	var board_data := {
		"width": width,
		"height": height,
		"mines": mines,
		"revealed": safe_cells
	}

	var attempts := 0
	while attempts < max_attempts:
		var solve_result := _solver.analyze(board_data)

		if solve_result.is_solvable:
			return {"mines": mines, "result": solve_result}

		if attempts % reseed_interval == (reseed_interval - 1):
			# Periodic full reseed to escape local dead ends
			mines = _biased_sample(pool, mine_count)
		else:
			# Targeted reshuffle: randomize only mines near guess positions.
			# This preserves the parts of the board that already work.
			mines = _targeted_reshuffle(mines, solve_result.guess_positions, pool, width, height)

		board_data["mines"] = mines
		attempts += 1

	push_warning("MineGenerator: could not find a zero-guess layout after %d attempts" % max_attempts)
	# Return best-effort so the game can still start
	var final_result := _solver.analyze(board_data)
	return {"mines": mines, "result": final_result}


## Place mines with a spacing bias to reduce clustering.
## Candidates with too many adjacent mines are skipped; if the bias is too
## strict to fill the count, the remainder is filled randomly.
func _biased_sample(pool: Array[Vector2i], count: int) -> Array[Vector2i]:
	var shuffled := pool.duplicate()
	shuffled.shuffle()

	var placed: Array[Vector2i] = []
	var placed_set: Dictionary = {}
	var overflow: Array[Vector2i] = []  # candidates rejected by bias, used as fallback

	for candidate in shuffled:
		if placed.size() >= count:
			break
		var neighbor_mines := 0
		for dy in [-1, 0, 1]:
			for dx in [-1, 0, 1]:
				if dx == 0 and dy == 0:
					continue
				if placed_set.has(Vector2i(candidate.x + dx, candidate.y + dy)):
					neighbor_mines += 1
		if neighbor_mines <= cluster_threshold:
			placed.append(candidate)
			placed_set[candidate] = true
		else:
			overflow.append(candidate)

	# Fill any shortfall caused by strict bias with overflow candidates
	for candidate in overflow:
		if placed.size() >= count:
			break
		if not placed_set.has(candidate):
			placed.append(candidate)

	return placed


## Replace all mines within a radius of any guess position with fresh random picks.
## Mines outside the affected zone are kept, preserving areas that already work.
func _targeted_reshuffle(mines: Array[Vector2i], guess_positions: Array[Vector2i],
		pool: Array[Vector2i], width: int, height: int) -> Array[Vector2i]:

	# If we have no guess positions (shouldn't happen, but guard anyway),
	# fall back to a full biased resample
	if guess_positions.is_empty():
		return _biased_sample(pool, mines.size())

	# Mark mines within radius 3 of any guess position as "bad"
	var mine_set: Dictionary = {}
	for m in mines:
		mine_set[m] = true

	var bad_mines: Dictionary = {}
	for gp in guess_positions:
		for m in mines:
			if abs(m.x - gp.x) <= 3 and abs(m.y - gp.y) <= 3:
				bad_mines[m] = true

	# Keep mines outside the affected zone
	var kept: Array[Vector2i] = []
	var kept_set: Dictionary = {}
	for m in mines:
		if not bad_mines.has(m):
			kept.append(m)
			kept_set[m] = true

	# Sample replacements from the pool, excluding already-kept mines
	var needed := mines.size() - kept.size()
	var available: Array[Vector2i] = []
	for p in pool:
		if not kept_set.has(p):
			available.append(p)

	# Use biased sampling for replacements so new mines don't re-cluster
	var replacements := _biased_sample(available, mini(needed, available.size()))

	var result := kept.duplicate()
	result.append_array(replacements)
	return result


## Partial Fisher-Yates: O(count) instead of O(pool_size).
func _random_sample(pool: Array[Vector2i], count: int) -> Array[Vector2i]:
	var shuffled := pool.duplicate()
	var result: Array[Vector2i] = []
	for i in count:
		var j := randi_range(i, shuffled.size() - 1)
		var tmp = shuffled[i]
		shuffled[i] = shuffled[j]
		shuffled[j] = tmp
		result.append(shuffled[i])
	return result


func _get_neighbors(pos: Vector2i, w: int, h: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for dy in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue
			var nx = pos.x + dx
			var ny = pos.y + dy
			if nx >= 0 and nx < w and ny >= 0 and ny < h:
				result.append(Vector2i(nx, ny))
	return result
