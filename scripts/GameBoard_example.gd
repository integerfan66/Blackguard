## GameBoard.gd  (example — adapt to your own board script)
## Shows how to wire MinesweeperSolver into a real game board.

extends Node2D

# ── Scene references ──────────────────────────────────────────────────────────
@onready var solver_scene: SolverScene = $SolverScene   # add as child node
@onready var result_label: Label       = $HUD/ResultLabel/DebugMenu/GuessPointResult


# ── Called when the player first opens a cell ─────────────────────────────────
func on_board_generated(width: int, height: int,
		mines: Array[Vector2i], start_pos: Vector2i) -> void:

	# Connect once
	if not solver_scene.solve_completed.is_connected(_on_solve_completed):
		solver_scene.solve_completed.connect(_on_solve_completed)

	var board_data := {
		"width":    width,
		"height":   height,
		"mines":    mines,
		"revealed": [start_pos],   # first click is always safe & revealed
	}

	result_label.text = "Analysing board…"
	solver_scene.solve(board_data)   # async — won't block the frame


func _on_solve_completed(result: MinesweeperSolver.SolveResult) -> void:
	if result.is_solvable:
		result_label.text = "✓ No guesses needed"
		result_label.modulate = Color.GREEN
	else:
		result_label.text = "⚠ Requires %d guess(es)" % result.guesses_needed
		result_label.modulate = Color.ORANGE

	# Optional: highlight guess positions on the board
	for pos in result.guess_positions:
		_highlight_cell(pos, Color(1, 0.6, 0, 0.4))


func _highlight_cell(pos: Vector2i, color: Color) -> void:
	# Replace with however you draw/mark cells in your game
	pass


# ── Synchronous alternative (e.g. in editor @tool scripts) ────────────────────
func check_board_sync(board_data: Dictionary) -> bool:
	var result := solver_scene.solve_sync(board_data)
	return result.is_solvable
