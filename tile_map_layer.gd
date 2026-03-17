extends TileMapLayer

#grid variables
const ROWS : int = 14
const COLS : int = 15
const CELL_SIZE : int = 50

#tile map variables
var tile_id : int = 0

#layer variables
var mine_layer : int = 0
var number_layer : int = 1
var grass_layer : int = 2
var flag_layer : int = 3
var hover_layer : int = 4

#atlas coordinates
var mine_atlas := Vector2i(4, 0)

#array for mine coordinates
var mine_coords := []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	new_game()
	
func new_game():
	clear()
	mine_coords.clear()
	generate_mines()

func generate_mines():
	for i in range(get_parent().TOTAL_MINES):
		var mine_pos = Vector2i(randi_range(0, COLS-1), randi_range(0,ROWS-1))
		mine_coords.append(mine_pos)
		#coords, source_id, atlas_coords, alternative_title
		set_cell(mine_pos,tile_id, mine_atlas) #add mine to tilemap

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
