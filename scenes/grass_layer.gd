extends TileMapLayer

@onready var tilemapgroup : Node2D = get_parent()
var tile_id : int = 3

func generate_grass():
	for y in range(tilemapgroup.board_layer.ROWS):
		for x in range(tilemapgroup.board_layer.COLS):
			var toggle = ((x+y)%2)		#3,0 ve 4,0 atlas koordinatları arasında git-gel
			set_cell(Vector2i(x,y),tile_id,(tilemapgroup.grass_atlas-Vector2i(toggle,0)))

func is_grass(pos):
	return get_cell_atlas_coords(pos) == tilemapgroup.grass_atlas or get_cell_atlas_coords(pos) == (tilemapgroup.grass_atlas-Vector2i(1,0))

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
