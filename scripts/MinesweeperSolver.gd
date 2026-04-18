## MinesweeperSolver.gd
## Analyzes a minesweeper board and determines:
##   - Whether it can be solved without guessing
##   - If guesses are required, the minimum number needed
##
## Usage:
##   var solver = MinesweeperSolver.new()
##   var result = solver.analyze(board_data)
##   # result is a SolveResult object
##
## Board format expected:
##   board_data = {
##     "width": int,
##     "height": int,
##     "mines": Array[Vector2i],          # positions of all mines
##     "revealed": Array[Vector2i],       # initially revealed cells
##   }

class_name MinesweeperSolver
extends RefCounted
const INF_INT := 999999
var max_guess_depth: int

## Returned by analyze(). Check .is_solvable and .guesses_needed.
class SolveResult:
	var is_solvable: bool = false       # True if board can be solved with zero guesses
	var guesses_needed: int = 0         # Minimum guesses required (0 if fully solvable)
	var guess_positions: Array[Vector2i] = []  # Example positions where guesses were made
	var steps: Array[Dictionary] = []   # Step-by-step solve log (for debugging/visualisation)

	func _to_string() -> String:
		if is_solvable:
			return "Solvable with no guesses (%d steps)" % steps.size()
		return "Requires %d guess(es) at: %s" % [guesses_needed, guess_positions]


# ── Internal cell states ──────────────────────────────────────────────────────
const STATE_UNKNOWN  := 0
const STATE_SAFE     := 1   # logically deduced safe
const STATE_MINE     := 2   # logically deduced mine
const STATE_REVEALED := 3   # open, number known


# ── Public API ────────────────────────────────────────────────────────────────

## Main entry point.  Pass a board_data dict (see header) and receive a SolveResult.
func analyze(board_data: Dictionary) -> SolveResult:
	var w: int = board_data["width"]
	var h: int = board_data["height"]
	var mine_set: Dictionary = {}          # Vector2i -> true, fast lookup
	for m in board_data["mines"]:
		mine_set[m] = true

	# Build initial knowledge state
	var state := _make_state(w, h, mine_set, board_data["revealed"])
	var result := SolveResult.new()
	
	var guesses := _solve(state, mine_set, result.steps, 0)
	result.guesses_needed = guesses
	result.is_solvable = (guesses == 0)

	# Collect guess positions from the step log
	for step in result.steps:
		if step.get("type") == "guess":
			result.guess_positions.append(step["pos"])

	return result

func _debug_dump_state(state: Dictionary) -> void:
	var w: int = state["width"]
	var h: int = state["height"]
	var cells: Array = state["cells"]
	var row := ""
	for y in h:
		row = ""
		for x in w:
			match cells[y * w + x]:
				STATE_UNKNOWN:  row += "?"
				STATE_SAFE:     row += "S"
				STATE_MINE:     row += "M"
				STATE_REVEALED: row += "."
		print(row)

# ── Internal solver ───────────────────────────────────────────────────────────

## Recursive solver. Returns the number of guesses made in the best path found.
## Returns INF_INT if the board is contradictory on this branch.
func _solve(state: Dictionary, mine_set: Dictionary, log: Array, depth: int) -> int:
	# Guard against runaway recursion on pathological boards
	if depth > max_guess_depth:
		return INF_INT

	# Apply constraint propagation until no more progress
	var iteration := 0
	var progress := true
	while progress:
		iteration += 1
		print("depth=%d  iteration=%d" % [depth, iteration])
		progress = _propagate(state, mine_set, log)
		if(depth>max_guess_depth): break

	# Check contradiction first — propagation may have exposed one
	if _has_contradiction(state, mine_set):
		return INF_INT

	# Check completion
	if _is_complete(state):
		return 0

	# Find border-unknown candidates for guessing
	var candidates := _get_guess_candidates(state)

	# If no border candidates exist but board isn't complete, all remaining unknowns
	# are isolated (no adjacent revealed numbers). Pick any one to break the deadlock.
	if candidates.is_empty():
		candidates = _get_any_unknown(state)
		if candidates.is_empty():
			return 0  # nothing left, effectively complete

	# Try each candidate on a CLONE. Pick whichever leads to the fewest total guesses.
	# We try both assumptions (safe AND mine) per candidate because we don't know which
	# is true — a real player must guess, so both branches must be survivable.
	var best_cost: int = INF_INT
	var best_log: Array = []

	for candidate in candidates:
		# ── Branch A: assume this cell is SAFE (it isn't a mine) ──
		var s_safe := _clone_state(state)
		_force_reveal(s_safe, candidate, mine_set)
		var log_safe: Array = []
		var cost_safe := _solve(s_safe, mine_set, log_safe, depth + 1)
		# ── Branch B: assume this cell is a MINE ──
		var s_mine := _clone_state(state)
		s_mine["cells"][candidate.y * s_mine["width"] + candidate.x] = STATE_MINE
		var log_mine: Array = []
		var cost_mine := _solve(s_mine, mine_set, log_mine, depth + 1)

		# Both branches must be solvable; take the worse of the two
		# (a guess is only "free" if BOTH outcomes lead to a solution)
		var worst := maxi(cost_safe, cost_mine)

		if worst < best_cost:
			best_cost = worst
			best_log = log_safe  # log the safe-path steps for tracing
			if best_cost == 0:
				break  # optimal — stop searching

	if best_cost == INF_INT:
		# No candidate led to a valid solution — board is unsolvable from here
		return INF_INT

	# Commit: record this guess in the main log and count it
	log.append({"type": "guess", "pos": candidates[0], "depth": depth})
	log.append_array(best_log)
	return 1 + best_cost


## Constraint propagation pass. Returns true if any cell state changed.
func _propagate(state: Dictionary, mine_set: Dictionary, log: Array) -> bool:
	var changed := false
	var w: int = state["width"]
	var h: int = state["height"]
	var cells: Array = state["cells"]
	for i in cells.size():
		if cells[i] == STATE_SAFE:
			var pos := Vector2i(i % w, i / w)
			_force_reveal(state, pos, mine_set)
			changed = true
	
	for y in h:
		for x in w:
			var idx := y * w + x
			if cells[idx] != STATE_REVEALED:
				continue

			var pos := Vector2i(x, y)
			var number: int = _get_number(pos, mine_set, w, h)
			var neighbors := _get_neighbors(pos, w, h)

			var unknown_neighbors: Array[Vector2i] = []
			var flagged_count := 0

			for n in neighbors:
				var nidx := n.y * w + n.x
				match cells[nidx]:
					STATE_MINE:
						flagged_count += 1
					STATE_UNKNOWN:
						unknown_neighbors.append(n)

			var remaining := number - flagged_count

			# Rule 1: if remaining mines == unknown neighbors → all unknowns are mines
			if remaining == unknown_neighbors.size() and remaining > 0:
				for n in unknown_neighbors:
					var nidx := n.y * w + n.x
					if cells[nidx] == STATE_UNKNOWN:
						cells[nidx] = STATE_MINE
						log.append({"type": "deduce_mine", "pos": n})
						changed = true

			# Rule 2: if remaining == 0 → all unknowns adjacent to this cell are safe
			if remaining == 0 and unknown_neighbors.size() > 0:
				for n in unknown_neighbors:
					var nidx := n.y * w + n.x
					if cells[nidx] == STATE_UNKNOWN:
						cells[nidx] = STATE_SAFE
						# Auto-reveal safe cells and propagate their numbers
						log.append({"type": "deduce_safe", "pos": n})
						changed = true

	# ── Subset / superset rule (more advanced) ────────────────────────────────
	changed = _subset_rule(state, mine_set, log) or changed

	return changed


## Subset rule: if constraint A's unknowns ⊆ constraint B's unknowns,
## we can derive new mine/safe deductions on the difference set.
func _subset_rule(state: Dictionary, mine_set: Dictionary, log: Array) -> bool:
	var changed := false
	var w: int = state["width"]
	var h: int = state["height"]
	var cells: Array = state["cells"]

	# Collect active constraints: (remaining_mines, unknown_neighbor_set)
	var constraints: Array[Dictionary] = []
	for y in h:
		for x in w:
			var idx := y * w + x
			if cells[idx] != STATE_REVEALED:
				continue
			var pos := Vector2i(x, y)
			var number: int = _get_number(pos, mine_set, w, h)
			var neighbors := _get_neighbors(pos, w, h)
			var unknowns: Array[Vector2i] = []
			var flagged := 0
			for n in neighbors:
				match cells[n.y * w + n.x]:
					STATE_MINE:    flagged += 1
					STATE_UNKNOWN: unknowns.append(n)
			var remaining := number - flagged
			if unknowns.size() > 0:
				constraints.append({"remaining": remaining, "unknowns": unknowns})

	# Compare each pair
	for i in constraints.size():
		for j in constraints.size():
			if i == j:
				continue
			var a: Dictionary = constraints[i]
			var b: Dictionary = constraints[j]
			# Check if a.unknowns ⊆ b.unknowns
			if _is_subset(a["unknowns"], b["unknowns"]):
				var diff_remaining: int = b["remaining"] - a["remaining"]
				var diff_unknowns: Array[Vector2i] = _set_difference(b["unknowns"], a["unknowns"])
				if diff_unknowns.is_empty():
					continue
				if diff_remaining == 0:
					# All diff cells are safe
					for n in diff_unknowns:
						if cells[n.y * w + n.x] == STATE_UNKNOWN:
							cells[n.y * w + n.x] = STATE_SAFE
							_force_reveal(state, n, mine_set)
							log.append({"type": "deduce_safe_subset", "pos": n})
							changed = true
				elif diff_remaining == diff_unknowns.size():
					# All diff cells are mines
					for n in diff_unknowns:
						if cells[n.y * w + n.x] == STATE_UNKNOWN:
							cells[n.y * w + n.x] = STATE_MINE
							log.append({"type": "deduce_mine_subset", "pos": n})
							changed = true

	return changed


# ── State helpers ─────────────────────────────────────────────────────────────

func _make_state(w: int, h: int, mine_set: Dictionary, revealed: Array) -> Dictionary:
	var cells := []
	cells.resize(w * h)
	cells.fill(STATE_UNKNOWN)

	var state := {"width": w, "height": h, "cells": cells}

	for pos in revealed:
		if not mine_set.has(pos):
			_force_reveal(state, pos, mine_set)

	return state


func _force_reveal(state: Dictionary, pos: Vector2i, mine_set: Dictionary) -> void:
	var w: int = state["width"]
	var h: int = state["height"]
	var cells: Array = state["cells"]
	var idx := pos.y * w + pos.x
	if cells[idx] == STATE_REVEALED:
		return
	if mine_set.has(pos):
		cells[idx] = STATE_MINE
		return
	cells[idx] = STATE_REVEALED
	# Auto-open zero cells (flood fill)
	if _get_number(pos, mine_set, w, h) == 0:
		for n in _get_neighbors(pos, w, h):
			var nidx := n.y * w + n.x
			if cells[nidx] == STATE_UNKNOWN:
				_force_reveal(state, n, mine_set)


func _clone_state(state: Dictionary) -> Dictionary:
	return {
		"width": state["width"],
		"height": state["height"],
		"cells": state["cells"].duplicate()
	}


func _is_complete(state: Dictionary) -> bool:
	var cells: Array = state["cells"]
	for c in cells:
		if c == STATE_UNKNOWN:
			return false
	return true


func _has_contradiction(state: Dictionary, mine_set: Dictionary) -> bool:
	var w: int = state["width"]
	var h: int = state["height"]
	var cells: Array = state["cells"]
	for y in h:
		for x in w:
			if cells[y * w + x] != STATE_REVEALED:
				continue
			var pos := Vector2i(x, y)
			var number := _get_number(pos, mine_set, w, h)
			var neighbors := _get_neighbors(pos, w, h)
			var mines := 0
			var unknowns := 0
			for n in neighbors:
				match cells[n.y * w + n.x]:
					STATE_MINE:    mines += 1
					STATE_UNKNOWN: unknowns += 1
			if mines > number:
				return true
			if mines + unknowns < number:
				return true
	return false


func _get_guess_candidates(state: Dictionary) -> Array[Vector2i]:
	## Returns unknown cells adjacent to at least one revealed cell (border unknowns).
	## These are the only cells worth guessing — interior unknowns are constrained later.
	var w: int = state["width"]
	var h: int = state["height"]
	var cells: Array = state["cells"]
	var candidates: Array[Vector2i] = []
	var seen: Dictionary = {}

	for y in h:
		for x in w:
			if cells[y * w + x] != STATE_REVEALED:
				continue
			for n in _get_neighbors(Vector2i(x, y), w, h):
				if cells[n.y * w + n.x] == STATE_UNKNOWN and not seen.has(n):
					candidates.append(n)
					seen[n] = true

	return candidates


# ── Grid utilities ────────────────────────────────────────────────────────────

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


func _get_number(pos: Vector2i, mine_set: Dictionary, w: int, h: int) -> int:
	var count := 0
	for n in _get_neighbors(pos, w, h):
		if mine_set.has(n):
			count += 1
	return count


func _is_subset(a: Array, b: Array) -> bool:
	for item in a:
		if not b.has(item):
			return false
	return true


func _set_difference(a: Array, b: Array) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for item in a:
		if not b.has(item):
			result.append(item)
	return result





## Returns up to one completely isolated unknown cell (no revealed neighbor).
## Used as a last resort when no border candidates exist.
func _get_any_unknown(state: Dictionary) -> Array[Vector2i]:
	var w: int = state["width"]
	var h: int = state["height"]
	var cells: Array = state["cells"]
	for y in h:
		for x in w:
			if cells[y * w + x] == STATE_UNKNOWN:
				return [Vector2i(x, y)]
	return []
