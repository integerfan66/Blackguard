extends TileMapLayer

@onready var mine_generator: MineGenerator = $"../MineGenerator"
@onready var tilemapgroup : Node2D = get_parent()
@onready var debugMenu : CanvasLayer = tilemapgroup.hud_canvas_layer.get_node("DebugMenu")
var loseScreen : Panel


var isFirstClick : bool = true
signal flag_placed
signal flag_removed
#signal firstClicked(safe_cells)
signal minesReady

var tile_id : int = 0
var flag_tile_id : int = 3
var map_pos

const ROWS : int = 14
const COLS : int = 15
const MINE_COUNT : int = 35 
const CELL_SIZE : int = 50

#mayın koordinatları için dizi
var mine_coords := []
var unflagged_mine_count : int = MINE_COUNT

func _ready() -> void:
	mine_generator.generation_completed.connect(_on_mines_ready)
	mine_generator.generation_failed.connect(_on_generation_failed)
	loseScreen = tilemapgroup.hud_canvas_layer.get_node("WinLoseScreen").get_node("LoseScreen")
	

func _on_mines_ready(mines: Array[Vector2i], result: MinesweeperSolver.SolveResult) -> void:
	# Commit mines to your board_layer, then reveal start cell
	for m in mines:
		set_mine(m)
	tilemapgroup.number_layer.generate_numbers()
	process_left_click(map_pos)
	minesReady.emit()
	
	
	# result.guesses_needed is available here if you want to display it

func set_mine(mine):
	set_cell(mine,tile_id,tilemapgroup.mine_atlas)

func _on_generation_failed() -> void:
	push_warning("generation failed.")


func _input(event):
	
	if event is InputEventMouseButton:
		#fare pozisyonu ızgara üstünde mi bak
		if event.position.y < ROWS*CELL_SIZE:
			map_pos = local_to_map(event.position)
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not isFirstClick and not debugMenu.visible:
				if not tilemapgroup.flag_layer.is_flag(map_pos):
					if is_mine(map_pos):
						loseScreen.visible = true
					else:
						process_left_click(map_pos)
			elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed and isFirstClick and not debugMenu.visible:
				var safe_cells = erase_radius(map_pos)
				isFirstClick = false
				#emit_signal("firstClicked", safe_cells)
				mine_generator.generate(COLS, ROWS, MINE_COUNT, safe_cells)
			#bayrak ekleme ve silme
			elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and not isFirstClick:
				process_right_click(map_pos)

func erase_radius(center: Vector2i) -> Array[Vector2i]:
	var safe_cells : Array[Vector2i]= []
	for x in range(-1, 2):  # -1, 0, 1
		for y in range(-1, 2):
			var cell = center + Vector2i(x, y)
			# Bounds check so you don't go off the grid
			if cell.x >= 0 and cell.x < COLS and cell.y >= 0 and cell.y < ROWS:
				tilemapgroup.grass_layer.erase_cell(cell)
				safe_cells.append(cell)
	return safe_cells

func process_left_click(pos):
	var revealed_cells := []
	var cells_to_reveal := [pos]
	
	while not cells_to_reveal.is_empty():
		#hücreyi temizle ve temiz olduğunu belirt
		tilemapgroup.grass_layer.erase_cell(cells_to_reveal[0])
		revealed_cells.append(cells_to_reveal[0])
		if not tilemapgroup.number_layer.is_number(cells_to_reveal[0]):
				cells_to_reveal= reveal_surrounding_cells(cells_to_reveal,revealed_cells)
		#temizlenmiş hücreyi diziden kaldır
		cells_to_reveal.erase(cells_to_reveal[0])

#bayrak dikme/kaldırma
func process_right_click(pos):
	if tilemapgroup.grass_layer.is_grass(pos):
		if is_mine(pos) and tilemapgroup.flag_layer.is_flag(pos):
			tilemapgroup.flag_layer.set_cell(pos,flag_tile_id,Vector2i(-1,-1))
			unflagged_mine_count+=1
			flag_removed.emit()
		elif is_mine(pos) and not tilemapgroup.flag_layer.is_flag(pos):
			tilemapgroup.flag_layer.set_cell(pos,flag_tile_id,tilemapgroup.flag_atlas)
			unflagged_mine_count-=1
			flag_placed.emit()
		elif not is_mine(pos) and not tilemapgroup.flag_layer.is_flag(pos):
			tilemapgroup.flag_layer.set_cell(pos,flag_tile_id,tilemapgroup.flag_atlas)
			flag_placed.emit()
		else:
			tilemapgroup.flag_layer.set_cell(pos,flag_tile_id,Vector2i(-1,-1))
			flag_removed.emit()

func generate_mines(safe_cells: Array):
	for i in range(tilemapgroup.get_parent().TOTAL_MINES):
		var mine_pos = Vector2i(randi_range(0, COLS-1), randi_range(0,ROWS-1))
		while mine_coords.has(mine_pos) or safe_cells.has(mine_pos):
			mine_pos = Vector2i(randi_range(0, COLS-1), randi_range(0,ROWS-1))
		mine_coords.append(mine_pos)
		#coords, source_id, atlas_coords, alternative_title
		set_cell(mine_pos,tile_id, tilemapgroup.mine_atlas) #add mine to tilemap

func get_empty_cells():
	var empty_cells := []
	#ızgarada gezin
	for y in range(ROWS):
		for x in range(COLS):
			#eğer hücre boşsa diziye ekle
			if not is_mine(Vector2i(x,y)):
				empty_cells.append(Vector2i(x,y))
	return empty_cells

func reveal_surrounding_cells(cells_to_reveal, revealed_cells):
	for i in get_all_surrounding_cells(cells_to_reveal[0]):
		#hücrenin zaten görünmüş olup olmadığına bak
		if not revealed_cells.has(i):
			if not cells_to_reveal.has(i) and not tilemapgroup.flag_layer.is_flag(i):
				cells_to_reveal.append(i)
	return cells_to_reveal

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
					and target_cell.y >=0 and target_cell.y <= ROWS-1):
					surrounding_cells.append(target_cell)
	return surrounding_cells

func is_mine(pos):
	return get_cell_atlas_coords(pos) == tilemapgroup.mine_atlas
