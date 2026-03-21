extends TileMapLayer
@onready var tilemapgroup : Node2D = get_parent()
var tile_id : int = 3
func is_flag(pos):
	return get_cell_atlas_coords(pos) == tilemapgroup.flag_atlas
