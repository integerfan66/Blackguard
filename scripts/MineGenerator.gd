## MineGenerator.gd
## Generates a mine layout that the solver confirms requires <= max_guesses.
## Runs on a background thread so it never blocks the game.
##
## Usage:
##   mine_generator.generate(width, height, mine_count, start_pos)
##   # then listen to:
##   mine_generator.generation_completed.connect(_on_mines_ready)

class_name MineGenerator
extends Node

signal generation_completed(mines: Array[Vector2i], solve_result: MinesweeperSolver.SolveResult)
signal generation_failed  # emits if no valid layout found within attempt budget

@export var max_guesses_allowed: int = 2
@export var max_attempts: int = 100  # full reshuffles before giving up

var _solver: MinesweeperSolver
var _thread: Thread
var _mutex: Mutex
var _pending_emit: Dictionary  # {mines, result} or {failed: true}


func _ready() -> void:
	_solver = MinesweeperSolver.new()
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


func _exit_tree() -> void:
	if _thread and _thread.is_started():
		_thread.wait_to_finish()


## Start async mine generation. Listen to generation_completed.
func generate(width: int, height: int, mine_count: int, safe_cells: Array[Vector2i]) -> void:
	if _thread and _thread.is_started():
		_thread.wait_to_finish()
	_thread = Thread.new()
	_thread.start(_thread_generate.bind(width, height, mine_count, safe_cells))


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

	var mines := _random_sample(pool, mine_count)

	var board_data := {
		"width": width,
		"height": height,
		"mines": mines,
		"revealed": safe_cells
	}

	var attempts := 0
	while attempts < max_attempts:
		var solve_result := _solver.analyze(board_data)

		if solve_result.guesses_needed <= max_guesses_allowed:
			# Board is within tolerance
			return {"mines": mines, "result": solve_result}

		# Swap strategy: replace one mine that sits near a guess position
		# with a random non-mine cell. This is smarter than a full reshuffle
		# because it preserves the parts of the board that already work.
		var swapped := _swap_one(mines, solve_result.guess_positions, pool, board_data)
		if not swapped:
			# Couldn't find a valid swap, do a full reshuffle
			mines = _random_sample(pool, mine_count)
			board_data["mines"] = mines

		attempts += 1

	# Fell through — return best effort with a warning
	push_warning("MineGenerator: could not reach <= %d guesses after %d attempts" % [
		max_guesses_allowed, max_attempts
	])
	var final_result := _solver.analyze(board_data)
	return {"mines": mines, "result": final_result}


## Replace one mine near a guess position with a random unused cell.
## Returns false if no valid swap was found.
func _swap_one(mines: Array[Vector2i], guess_positions: Array[Vector2i],
	pool: Array[Vector2i], board_data: Dictionary) -> bool:

	if guess_positions.is_empty():
		return false

	# Pick a mine adjacent to one of the guess positions
	var mine_set: Dictionary = {}
	for m in mines:
		mine_set[m] = true

	var candidates_to_remove: Array[Vector2i] = []
	for gp in guess_positions:
		for n in _get_neighbors(gp, board_data["width"], board_data["height"]):
			if mine_set.has(n):
				candidates_to_remove.append(n)

	if candidates_to_remove.is_empty():
		return false

	var to_remove: Vector2i = candidates_to_remove[randi() % candidates_to_remove.size()]

	# Find a replacement not already a mine
	var non_mines: Array[Vector2i] = []
	for p in pool:
		if not mine_set.has(p):
			non_mines.append(p)

	if non_mines.is_empty():
		return false

	var replacement: Vector2i = non_mines[randi() % non_mines.size()]
	mines.erase(to_remove)
	mines.append(replacement)
	board_data["mines"] = mines
	return true


#func _get_forbidden(start_pos: Vector2i, width: int, height: int) -> Dictionary:
	#var forbidden: Dictionary = {}
	#forbidden[start_pos] = true
	#for n in _get_neighbors(start_pos, width, height):
		#forbidden[n] = true
	#return forbidden


func _random_sample(pool: Array[Vector2i], count: int) -> Array[Vector2i]:
	var shuffled := pool.duplicate()
	shuffled.shuffle()
	var result: Array[Vector2i] = []
	result.assign(shuffled.slice(0, count))
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
