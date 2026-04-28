extends Node2D

@onready var HUD : CanvasLayer = $HUD
var DebugMenu : CanvasLayer 
@onready var TileMapGroup : Node2D = $TileMapGroup
var winScreen : Panel 

#oyun değişkenleri
var TOTAL_MINES : int 
var remaining_mines : int
var time_elapsed : float


func _ready() -> void:
	TOTAL_MINES = TileMapGroup.get_node("BoardLayer").MINE_COUNT
	DebugMenu = HUD.get_node("DebugMenu")
	winScreen = HUD.get_node("WinLoseScreen").get_node("WinScreen")

func new_game():
	DebugMenu.isPaused = false
	time_elapsed = 0
	remaining_mines = TOTAL_MINES
#ya böyle oyun olmasın bu dil çok kötü ben C++/C#
#"tamam metehan" - kaan saksoy
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not DebugMenu.isPaused:
		time_elapsed += delta
		HUD.get_node("MenuBar").get_node("Stopwatch").text = str(int(time_elapsed))
		HUD.get_node("MenuBar").get_node("MineCount").text = str(int(remaining_mines))


func _on_tile_map_group_flag_placed() -> void:
	remaining_mines -= 1
	if TileMapGroup.board_layer.unflagged_mine_count == 0 and remaining_mines == 0:
		winScreen.visible = true
		print("finished game") #eğer her bayrak doğru konulduysa geri kalan boş hücreleri aç

func _on_tile_map_group_flag_removed() -> void:
	remaining_mines += 1
