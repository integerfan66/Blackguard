extends TileMapLayer

@onready var tilemapgroup : Node2D = get_parent()

var tile_id : int = 0
const ROWS : int = 14
const COLS : int = 15
const CELL_SIZE : int = 50

#mayın koordinatları için dizi
var mine_coords := []

func _input(event):
	if event is InputEventMouseButton:
		#fare pozisyonu ızgara üstünde mi bak
		if event.position.y < ROWS*CELL_SIZE:
			var map_pos := local_to_map(event.position)
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				pass
			#bayrak ekleme ve silme
			elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
				process_right_click(map_pos)
				
func process_right_click(pos):
	if tilemapgroup.grass_layer.is_grass(pos):
		if tilemapgroup.flag_layer.is_flag(pos):
			tilemapgroup.flag_layer.set_cell(pos,-1)
		else:
			tilemapgroup.flag_layer.set_cell(pos,tile_id,tilemapgroup.flag_atlas)


func generate_mines():
	for i in range(tilemapgroup.get_parent().TOTAL_MINES):
		var mine_pos = Vector2i(randi_range(0, COLS-1), randi_range(0,ROWS-1))
		while mine_coords.has(mine_pos):
			mine_pos = Vector2i(randi_range(0, COLS-1), randi_range(0,ROWS-1))
		mine_coords.append(mine_pos)
		#coords, source_id, atlas_coords, alternative_title
		set_cell(mine_pos,tile_id, tilemapgroup.mine_atlas) #add mine to tilemap

func is_mine(pos):
	return get_cell_atlas_coords(pos) == tilemapgroup.mine_atlas

func get_empty_cells():
	var empty_cells := [] 
	#ızgarada gezin
	for y in range(ROWS):
		for x in range(COLS):
			#eğer hücre boşsa diziye ekle
			if not is_mine(Vector2i(x,y)):
				empty_cells.append(Vector2i(x,y))
	return empty_cells

func get_all_surrounding_cells(middle_cell):
	var surrounding_cells := []
	var target_cell
	for y in range(3):
		for x in range(3):
			target_cell = middle_cell + Vector2i(x-1,y-1)
			#ortadaki hücreyse geç
			if target_cell!=middle_cell:
				#hücre ızgara üstünde mi bak
				if (target_cell.x>=0 and target_cell.x <= COLS-1 
					and target_cell.y >=y and target_cell.y <= ROWS-1):
					surrounding_cells.append(target_cell)
	return surrounding_cells


func _process(_delta: float) -> void:
	pass
