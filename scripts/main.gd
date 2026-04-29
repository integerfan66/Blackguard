extends Node2D

@onready var HUD : CanvasLayer = $HUD
var DebugMenu : CanvasLayer 
@onready var TileMapGroup : Node2D = $TileMapGroup
var winScreen : Panel 

#oyun değişkenleri
var TOTAL_MINES : int 
var remaining_mines : int
var time_elapsed : float
var empty_cell_count : int
var isStarted : bool = false

func _ready() -> void:
	TOTAL_MINES = TileMapGroup.get_node("BoardLayer").MINE_COUNT
	DebugMenu = HUD.get_node("DebugMenu")
	winScreen = HUD.get_node("WinLoseScreen").get_node("WinScreen")

func new_game():
	isStarted = true
	time_elapsed = 0
	remaining_mines = TOTAL_MINES
	empty_cell_count = (TileMapGroup.board_layer.ROWS * TileMapGroup.board_layer.COLS) - TileMapGroup.board_layer.MINE_COUNT
	print(str(empty_cell_count) + "is the number of empty cells")
#ya böyle oyun olmasın bu dil çok kötü ben C++/C#
#"tamam metehan" - kaan saksoy
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if isStarted:
		time_elapsed += delta
		HUD.get_node("MenuBar").get_node("Stopwatch").text = str(int(time_elapsed))
		HUD.get_node("MenuBar").get_node("MineCount").text = str(int(remaining_mines))
		if empty_cell_count == TileMapGroup.board_layer.empty_cell_count: 
			win()
	


func _on_tile_map_group_flag_placed() -> void:
	remaining_mines -= 1
	

func _on_tile_map_group_flag_removed() -> void:
	remaining_mines += 1
	
func win() -> void:
	winScreen.visible = true
	print("finished game") #eğer her bayrak doğru konulduysa geri kalan boş hücreleri aç
	set_process(false) #oyunu durdur
