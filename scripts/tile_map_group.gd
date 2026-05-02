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
signal flag_placed
signal flag_removed
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

func _on_board_layer_mines_ready() -> void:
	minesReady.emit()


func _on_board_layer_flag_removed() -> void:
	flag_removed.emit()


func _on_board_layer_flag_placed() -> void:
	flag_placed.emit()
