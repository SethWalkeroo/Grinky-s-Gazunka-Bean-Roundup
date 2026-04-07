extends GridMap

# --- NODE REFERENCES ---
@onready var gazunka_beans: Node3D = $"../../Gazunka_Beans"
@onready var player: CharacterBody3D = $"../../player"
@onready var enemy: CharacterBody3D = $"../Enemy"
@onready var nav_region: NavigationRegion3D = $".." 

# --- TILE IDs ---
@export_group("Tile IDs")
@export var tile_floor: int = 0
@export var tile_wall: int = 1
@export var tile_corner_in: int = 2
@export var tile_corner_out: int = 3

# --- 90-DEGREE FLIPPED ROTATIONS ---
# If textures are on the wrong side, swap the 0s and 16s, or the 10s and 22s!

@export_group("Straight Walls (Floor is to the...)")
@export var wall_floor_N: int = 10  
@export var wall_floor_S: int = 22  
@export var wall_floor_E: int = 0   
@export var wall_floor_W: int = 16  

@export_group("Outside Corners")
@export var out_corner_floor_NE: int = 10
@export var out_corner_floor_SE: int = 22
@export var out_corner_floor_SW: int = 16
@export var out_corner_floor_NW: int = 0

@export_group("Inside Corners")
@export var in_corner_floor_NE: int = 22
@export var in_corner_floor_SE: int = 16
@export var in_corner_floor_SW: int = 0
@export var in_corner_floor_NW: int = 10

# --- GENERATION SETTINGS ---
@export_group("Map Settings")
@export var map_width: int = 50
@export var map_depth: int = 50
@export var max_rooms: int = 12

var rooms: Array[Rect2i] = []
var floor_cells: Dictionary = {}

func _ready() -> void:
	randomize()
	generate_full_game()

func generate_full_game() -> void:
	clear()
	rooms.clear()
	floor_cells.clear()
	
	_carve_solid_floors()
	_build_perimeter_walls()
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	_spawn_everything()
	
	if nav_region:
		await get_tree().create_timer(0.3).timeout
		nav_region.bake_navigation_mesh()

# --- 1. CARVE SOLID FLOORS ---
func _carve_solid_floors() -> void:
	for i in range(max_rooms):
		var w = randi_range(6, 10)
		var h = randi_range(6, 10)
		var x = randi_range(5, map_width - 15)
		var z = randi_range(5, map_depth - 15)
		var new_room = Rect2i(x, z, w, h)
		
		var intersects = false
		for r in rooms:
			if new_room.intersects(r.grow(2)):
				intersects = true
				break
		
		if not intersects:
			rooms.append(new_room)
			for rx in range(new_room.position.x, new_room.end.x):
				for rz in range(new_room.position.y, new_room.end.y):
					floor_cells[Vector2i(rx, rz)] = true
			
			if rooms.size() > 1:
				_carve_l_shape_path(rooms[rooms.size()-2].get_center(), rooms[-1].get_center())

func _carve_l_shape_path(start: Vector2i, end: Vector2i):
	var step_x = sign(end.x - start.x)
	if step_x != 0:
		for x in range(start.x, end.x + step_x, step_x):
			_add_2x2_floor(Vector2i(x, start.y))
			
	var step_y = sign(end.y - start.y)
	if step_y != 0:
		for y in range(start.y, end.y + step_y, step_y):
			_add_2x2_floor(Vector2i(end.x, y))

func _add_2x2_floor(p: Vector2i):
	floor_cells[Vector2i(p.x, p.y)] = true
	floor_cells[Vector2i(p.x + 1, p.y)] = true
	floor_cells[Vector2i(p.x, p.y + 1)] = true
	floor_cells[Vector2i(p.x + 1, p.y + 1)] = true

# --- 2. BITMASK PERIMETER ---
func _build_perimeter_walls() -> void:
	for cell in floor_cells.keys():
		set_cell_item(Vector3i(cell.x, 0, cell.y), tile_floor, 0)
	
	var perimeter = {}
	for cell in floor_cells.keys():
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				var n = cell + Vector2i(dx, dy)
				if not floor_cells.has(n):
					perimeter[n] = true

	for p in perimeter.keys():
		var fN = floor_cells.has(p + Vector2i(0, -1))
		var fS = floor_cells.has(p + Vector2i(0, 1))
		var fE = floor_cells.has(p + Vector2i(1, 0))
		var fW = floor_cells.has(p + Vector2i(-1, 0))
		
		var mask = 0
		if fN: mask += 1
		if fE: mask += 2
		if fS: mask += 4
		if fW: mask += 8
		
		var id = -1
		var rot = 0
		
		if mask == 1: id = tile_wall; rot = wall_floor_N
		elif mask == 2: id = tile_wall; rot = wall_floor_E
		elif mask == 4: id = tile_wall; rot = wall_floor_S
		elif mask == 8: id = tile_wall; rot = wall_floor_W
		
		elif mask == 3: id = tile_corner_out; rot = out_corner_floor_NE
		elif mask == 6: id = tile_corner_out; rot = out_corner_floor_SE
		elif mask == 12: id = tile_corner_out; rot = out_corner_floor_SW
		elif mask == 9: id = tile_corner_out; rot = out_corner_floor_NW
		
		elif mask == 0:
			var fNE = floor_cells.has(p + Vector2i(1, -1))
			var fNW = floor_cells.has(p + Vector2i(-1, -1))
			var fSE = floor_cells.has(p + Vector2i(1, 1))
			var fSW = floor_cells.has(p + Vector2i(-1, 1))
			
			if fNE: id = tile_corner_in; rot = in_corner_floor_NE
			elif fSE: id = tile_corner_in; rot = in_corner_floor_SE
			elif fSW: id = tile_corner_in; rot = in_corner_floor_SW
			elif fNW: id = tile_corner_in; rot = in_corner_floor_NW
		
		if id != -1:
			set_cell_item(Vector3i(p.x, 0, p.y), id, rot)

# --- 3. ENTITIES & SPAWNING ---
func _spawn_everything():
	if rooms.is_empty(): return
	var start_room = rooms[0].get_center()
	var end_room = rooms[-1].get_center()
	
	player.global_position = to_global(map_to_local(Vector3i(start_room.x, 0, start_room.y))) + Vector3(0, 1.0, 0)
	if player is CharacterBody3D: player.velocity = Vector3.ZERO
	
	enemy.global_position = to_global(map_to_local(Vector3i(end_room.x, 0, end_room.y))) + Vector3(0, 1.0, 0)
	
	var beans = gazunka_beans.get_children()
	for i in range(beans.size()):
		var r = rooms[i % rooms.size()].get_center()
		beans[i].global_position = to_global(map_to_local(Vector3i(r.x, 0, r.y))) + Vector3(0, 0.5, 0)

	create_escape_zone()

func create_escape_zone() -> void:
	var area = Area3D.new()
	var col = CollisionShape3D.new()
	col.shape = BoxShape3D.new()
	col.shape.size = Vector3(2, 2, 2)
	area.add_child(col)
	add_child(area)
	
	var r0 = rooms[0].get_center()
	area.global_position = to_global(map_to_local(Vector3i(r0.x, 0, r0.y)))
	area.body_entered.connect(_on_escape_entered)

func _on_escape_entered(body):
	if body == player and player.get("bean_count") >= 7:
		get_tree().change_scene_to_file("res://scenes/heaven.tscn")

func _process(_delta):
	if player.global_position.y < -10:
		var start_room = rooms[0].get_center()
		player.global_position = to_global(map_to_local(Vector3i(start_room.x, 0, start_room.y))) + Vector3(0, 2.0, 0)
