extends TileMapLayer
@onready var tilemapgroup : Node2D = get_parent()

func is_flag(pos):
	return tilemapgroup.hover_layer.get_cell_atlas_coords(pos) == tilemapgroup.flag_atlas



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
