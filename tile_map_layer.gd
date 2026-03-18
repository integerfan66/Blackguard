extends TileMapLayer

#!TODO: USE SET_CELLS AND TILE_MAP_LAYERS PROPERLY
#CURRENTLY NOT USING LAYERS BUT ATLAS_COORDS, DRAWS OVER OTHER CELLS
#grid variables
const ROWS : int = 14
const COLS : int = 15
const CELL_SIZE : int = 50

#tile map variables
var tile_id : int = 0

#layer variables (may be deemed unnecessary !!!)
var mine_layer : int = 0
var number_layer : int = 1
var grass_layer : int = 2
var flag_layer : int = 3
var hover_layer : int = 4

#atlas coordinates (switch atlases with tile layers? may be unnecessary.)
var mine_atlas := Vector2i(4, 0)
var number_atlas : Array = generate_number_atlas()
var grass_atlas := Vector2i(3, 0)
var hover_atlas := Vector2i(6, 0)

func generate_number_atlas():
	var a := []
	for i in range(8):
		a.append(Vector2i(i,1))
	return a

#array for mine coordinates
var mine_coords := []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	new_game()
	
func new_game():
	clear()
	mine_coords.clear()
	generate_mines()
	generate_numbers()
	generate_grass()

func generate_mines():
	for i in range(get_parent().TOTAL_MINES):
		var mine_pos = Vector2i(randi_range(0, COLS-1), randi_range(0,ROWS-1))
		while mine_coords.has(mine_pos):
			mine_pos = Vector2i(randi_range(0, COLS-1), randi_range(0,ROWS-1))
		mine_coords.append(mine_pos)
		#coords, source_id, atlas_coords, alternative_title
		set_cell(mine_pos,tile_id, mine_atlas) #add mine to tilemap

func generate_numbers():
	for i in get_empty_cells():
		var mine_count : int = 0
		for j in get_all_surrounding_cells(i):
			#check if there is mine in the cell
			if is_mine(j):
				mine_count+=1
		#once counted, add number cell to the tilemap
		if mine_count>0:
			set_cell(i, tile_id, number_atlas[mine_count-1])

func generate_grass():
	for y in range(ROWS):
		for x in range(COLS):
			var toggle = ((x+y)%2)		#Switch between 3,0 and 4,0 atlases
			set_cell(Vector2i(x,y),tile_id,(grass_atlas-Vector2i(toggle,0)))


func is_mine(pos):
	return get_cell_atlas_coords(pos) == mine_atlas
	
func is_grass(pos):
	return get_cell_atlas_coords(pos) == grass_atlas
	
func get_empty_cells():
	var empty_cells := [] 
	#iterate through the grid
	for y in range(ROWS):
		for x in range(COLS):
			#check if cell empty, if it is then add to array
			if not is_mine(Vector2i(x,y)):
				empty_cells.append(Vector2i(x,y))
	return empty_cells

func get_all_surrounding_cells(middle_cell):
	var surrounding_cells := []
	var target_cell
	for y in range(3):
		for x in range(3):
			target_cell = middle_cell + Vector2i(x-1,y-1)
			#skip cell if it is the middle one
			if target_cell!=middle_cell:
				#check if cell is on grid
				if (target_cell.x>=0 and target_cell.x <= COLS-1 
					and target_cell.y >=y and target_cell.y <= ROWS-1):
					surrounding_cells.append(target_cell)
	return surrounding_cells

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	highlight_cell()
	
func highlight_cell():
	var mouse_pos := local_to_map(get_local_mouse_position())
	#hover over grass cells
	if is_grass(mouse_pos):
		set_cell(mouse_pos,tile_id,hover_atlas) 
		
		
