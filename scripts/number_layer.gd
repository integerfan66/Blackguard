extends TileMapLayer

@onready var tilemapgroup : Node2D = get_parent()
var tile_id : int = 1 #yerel karo kaynağı numarası

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func is_number(pos):
	for i in tilemapgroup.number_atlas:
		if get_cell_atlas_coords(pos) == i:
			return true
	return false

func generate_numbers():
	for i in tilemapgroup.board_layer.get_empty_cells():
		var mine_count : int = 0
		for j in tilemapgroup.board_layer.get_all_surrounding_cells(i):
			#hücrede mayın var mı bak
			if tilemapgroup.board_layer.is_mine(j):
				mine_count+=1
		#saydıktan sonra sayı hücresine tilemap ekle
		if mine_count>0:
			set_cell(i, tile_id, tilemapgroup.number_atlas[mine_count-1])
