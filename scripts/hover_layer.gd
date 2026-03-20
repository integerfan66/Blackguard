extends TileMapLayer

@onready var tilemapgroup : Node2D = get_parent()
var tile_id : int = 2 #yerel karo kaynağı numarası
var last_hovered: Vector2i = Vector2i(-1, -1) #geçersiz nöbetçi değişken
func highlight_cell():
	var mouse_pos = local_to_map(get_local_mouse_position())  
	if mouse_pos == last_hovered:
		return
	# Clear previous hover
	if last_hovered != Vector2i(-1, -1):
		set_cell(last_hovered, -1)
	#çimen hücreleri üstünde süzül
	if tilemapgroup.grass_layer.is_grass(mouse_pos):
		set_cell(mouse_pos,tile_id,tilemapgroup.hover_atlas)
		last_hovered = mouse_pos
	else:
		last_hovered = Vector2i(-1,-1)



func _ready() -> void:
	pass 

func _process(_delta: float) -> void:
	highlight_cell()
