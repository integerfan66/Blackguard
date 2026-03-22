extends Node2D

#oyun değişkenleri
const TOTAL_MINES : int = 50
var remaining_mines : int
var time_elapsed : float

func _ready() -> void:
	new_game()

func new_game():
	time_elapsed = 0
	remaining_mines = TOTAL_MINES


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time_elapsed += delta
	$HUD.get_node("Stopwatch").text = str(int(time_elapsed))
	$HUD.get_node("MineCount").text = str(int(remaining_mines))


func _on_tile_map_group_flag_placed() -> void:
	remaining_mines -= 1
	if remaining_mines == 0:
		pass #eğer her bayrak doğru konulduysa geri kalan boş hücreleri aç

func _on_tile_map_group_flag_removed() -> void:
	remaining_mines += 1
