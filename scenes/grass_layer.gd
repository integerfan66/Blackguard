extends TileMapLayer

@onready var tilemapgroup : Node2D = get_parent()
var tile_id : int = 2

func generate_grass():
	for y in range(tilemapgroup.board_layer.ROWS):
		for x in range(tilemapgroup.board_layer.COLS):
			var toggle = ((x+y)%2)		#3,0 ve 4,0 atlas koordinatları arasında git-gel
			set_cell(Vector2i(x,y),tile_id,(tilemapgroup.grass_atlas-Vector2i(toggle,0)))

func is_grass(pos):
	return get_cell_atlas_coords(pos) == tilemapgroup.grass_atlas or get_cell_atlas_coords(pos) == (tilemapgroup.grass_atlas-Vector2i(1,0))
