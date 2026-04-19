extends Node2D

@export var hud_canvas_layer: CanvasLayer
@onready var board_layer : TileMapLayer = $BoardLayer
@onready var number_layer : TileMapLayer = $NumberLayer
@onready var grass_layer : TileMapLayer = $GrassLayer
@onready var flag_layer : TileMapLayer = $FlagLayer
@onready var hover_layer : TileMapLayer = $HoverLayer
@onready var solver_scene: SolverScene = $SolverScene   # add as child node
@onready var result_label: Label = hud_canvas_layer.get_node("DebugMenu/Panel/GuessPointResult")

signal minesReady

#var mine_layer : int = 0
#var number_layer : int = 1
#var grass_layer : int = 2
#var flag_layer : int = 3
#var hover_layer : int = 4


var mine_atlas := Vector2i(4, 0)
var number_atlas : Array = generate_number_atlas()
var grass_atlas := Vector2i(3, 0)
var flag_atlas := Vector2i(5, 0)
var hover_atlas := Vector2i(6, 0)


func generate_number_atlas():
	var a := []
	for i in range(8):
		a.append(Vector2i(i,1))
	print(a)
	return a

func _ready() -> void:
	new_game()

func new_game():
	clear()
	board_layer.mine_coords.clear()
	#board_layer.generate_mines()
	#number_layer.generate_numbers()
	grass_layer.generate_grass()

func clear():
	board_layer.clear()
	number_layer.clear()
	grass_layer.clear()
	flag_layer.clear()
	hover_layer.clear()


func _on_board_layer_first_clicked(safe_cells) -> void:
	pass
	#board_layer.generate_mines(safe_cells)
	#number_layer.generate_numbers()
	#
	## Connect once
	#if not solver_scene.solve_completed.is_connected(_on_solve_completed):
		#solver_scene.solve_completed.connect(_on_solve_completed)
#
	#var board_data := {
		#"width":    board_layer.COLS,
		#"height":   board_layer.ROWS,
		#"mines":    board_layer.mine_coords,
		#"revealed": safe_cells,   # first click is always safe & revealed
	#}
#
	#result_label.text = "Analysing board…"
	#solver_scene.solve(board_data)   # async — won't block the frame
	#result_label.text = "DEBUG"
#
## ── Called when the player first opens a cell ─────────────────────────────────
##func on_board_generated(width: int, height: int,
		##mines: Array[Vector2i], start_pos: Vector2i) -> void:
#
#func _on_solve_completed(result: MinesweeperSolver.SolveResult) -> void:
	#if result.is_solvable:
		#result_label.text = "✓ No guesses needed"
		#result_label.modulate = Color.GREEN
	#else:
		#result_label.text = "⚠ Requires %d guess(es)" % result.guesses_needed
		#result_label.modulate = Color.ORANGE
#
	## Optional: highlight guess positions on the board
	#for pos in result.guess_positions:
		#_highlight_cell(pos, Color(1, 0.6, 0, 0.4))
#
#
#func _highlight_cell(pos: Vector2i, color: Color) -> void:
	## Replace with however you draw/mark cells in your game
	#pass


func _on_board_layer_mines_ready() -> void:
	minesReady.emit()
