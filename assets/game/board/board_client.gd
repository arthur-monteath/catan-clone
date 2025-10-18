class_name BoardClient
extends Node2D

enum TileType {
	BRICK = Main.Res.BRICK,
	LUMBER = Main.Res.LUMBER,
	ORE = Main.Res.ORE,
	GRAIN = Main.Res.GRAIN,
	WOOL = Main.Res.WOOL,
	DESERT
}

func _tile_type_to_resource(type: TileType):
	match type:
		TileType.BRICK: return Main.Res.BRICK
		TileType.LUMBER: return Main.Res.LUMBER
		TileType.ORE: return Main.Res.ORE
		TileType.GRAIN: return Main.Res.GRAIN
		TileType.WOOL: return Main.Res.WOOL
		TileType.DESERT: return null

@onready var main: Node = $".."
@export var textures: Dictionary[TileType, Texture2D]

const TILE: PackedScene = preload("uid://dtvr5obijngj")
const SETTLEMENT: PackedScene = preload("uid://be4lgt7hs4inj")
const ROAD: PackedScene = preload("uid://be4lgt7hs4inj")

var tileAmounts: Dictionary[TileType, int] = {
	TileType.LUMBER: 4,
	TileType.GRAIN: 4,
	TileType.WOOL: 4,
	TileType.BRICK: 3,
	TileType.ORE: 3,
	TileType.DESERT: 1,
}

class Tile:
	var node: Node2D
	var type: TileType
	var pos: Vector2:
		get: return pos
		set(value):
			node.global_position = value
			pos = value
	var number: int:
		get: return number
		set(value):
			node.get_node("Number").text = String.num_int64(value)
			number = value
	var edges: Array[Vector2]

func give_resource(tile: Tile):
		for edge in tile.edges:
			if roads.has(edge):
				var resource_type: Main.Res = _tile_type_to_resource(tile.type)
				if resource_type != null:
					main.players[roads[edge]].resources[resource_type] += 1

var color: Color
@rpc("authority", "reliable", "call_local")
func set_color(c: Color):
	color = c
#var player: Main.Player
#@rpc("authority", "reliable", "call_local")
#func set_local_player():
	#for p in players:
		#if p.id == multiplayer.get_unique_id():
			#player = p

@onready var action_ui: Control = $"../CanvasLayer/ActionUI"
var is_my_turn: bool = false
@rpc("authority", "reliable", "call_local")
func set_is_my_turn(value: bool):
	is_my_turn = value
	action_ui.visible = value
	if !value: build_mode = false

var edges: Dictionary[Vector2, Array]
var edge_lines: Dictionary[Vector2, Array]
var points: Array[Vector2]

var tiles: Array[Tile]
var roads: Dictionary[Vector2, int]
var settlements: Dictionary[Vector2, Dictionary]

func generate_map() -> void:
	if !multiplayer.is_server(): return
	
	var tile_types: Array = []
	for type in tileAmounts:
		for _i in range(tileAmounts[type]):
			tile_types.append(int(type))
	tile_types.shuffle()
	
	var number_tokens: Array[int] = []
	number_tokens.append_array(range(2,13))
	number_tokens.append_array(range(3,12))
	number_tokens.shuffle()
	
	propagate_map.rpc(tile_types, number_tokens)

@rpc("authority", "reliable", "call_local")
func propagate_map(tile_types, number_tokens):
	for type in tile_types:
		var t = Tile.new()
		t.type = type
		tiles.append(t)
	
	for i in range(0, len(tiles)):
		var t = TILE.instantiate()
		tiles[i].node = t
		t.get_node("Hex").texture = textures[tiles[i].type]
	
		tiles[i].number = number_tokens.pop_front()
		
		var pos = get_hex_position(i)
		tiles[i].pos = pos
		
		for point in get_points(tiles[i]):
			points.append(point)
		
		var edge_dict = get_edge_lines(tiles[i])
		for edge in edge_dict:
			if not edges.has(edge):
				edge_lines[edge] = edge_dict[edge]
				edges[edge] = [tiles[i]]
				tiles[i].edges.append(edge)
			else:
				edges[edge].append(tiles[i])
		
		add_child(t)

#region Structure Building
func request_structure(pos: Vector2, structure: Structure):
	match structure:
		Structure.SETTLEMENT:
			request_settlement.rpc_id(1, pos)
		Structure.ROAD:
			request_road.rpc_id(1, pos)

#region Build Settlement
signal on_settlement_built
@rpc("any_peer", "reliable", "call_local")
func request_settlement(pos: Vector2):
	if multiplayer.is_server():
		var free_settlement: bool = main.game_state == Main.State.FIRST_SETTLEMENT or main.game_state == Main.State.SECOND_SETTLEMENT
		var can_pay: bool = false
		var can_place: bool = points.has(pos) and !settlements.has(pos)
		if (free_settlement or can_pay) and can_place:
			build_settlement.rpc(pos, main.get_player_client_info_by_id(multiplayer.get_remote_sender_id()))
			emit_signal("on_settlement_built", pos)

@rpc("authority", "reliable", "call_local")
func build_settlement(pos: Vector2, player: Dictionary):
	var settlement = SETTLEMENT.instantiate()
	settlement.position = pos
	var sprite: Sprite2D = settlement.get_node("Sprite2D")
	sprite.self_modulate = player.color
	settlements.set(pos, player)
	add_child(settlement)
#endregion

#region Build Road
signal on_road_built
@rpc("any_peer", "reliable", "call_local")
func request_road(pos: Vector2):
	if multiplayer.is_server():
		var free_road: bool = main.game_state == Main.State.FIRST_SETTLEMENT or main.game_state == Main.State.SECOND_SETTLEMENT
		var can_pay: bool = false
		var can_place: bool = points.has(pos) and !settlements.has(pos)
		if (free_road or can_pay) and can_place:
			build_road.rpc(pos, main.get_player_client_info_by_id(multiplayer.get_remote_sender_id()))
			emit_signal("on_road_built", pos)

@rpc("authority", "reliable", "call_local")
func build_road(pos: Vector2, player: Dictionary):
	var road = ROAD.instantiate()
	road.position = pos
	var sprite: Sprite2D = road.get_node("Sprite2D")
	sprite.self_modulate = player.color
	roads.set(pos, player)
	add_child(road)
#endregion

enum Structure {
	SETTLEMENT,
	ROAD,
}

var selected_structure: Structure = Structure.SETTLEMENT
#endregion

var preview_pos: Vector2 = Vector2.INF
var build_mode: bool = false
func _unhandled_input(_event: InputEvent) -> void:
	if !is_my_turn: return
	var mouse = get_global_mouse_position()
	match main.game_state:
		Main.State.FIRST_SETTLEMENT or Main.State.SECOND_SETTLEMENT:
			if selected_structure == Structure.SETTLEMENT:
				preview_pos = get_point(mouse)
			else: preview_pos = get_edge(mouse)
			if (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and preview_pos != Vector2.INF):
				request_structure(preview_pos, selected_structure)
		Main.State.BUILDING:
			if build_mode:
				if (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and preview_pos != Vector2.INF):
					settlements.set(get_point(mouse), main.turn)
					roads.set(get_edge(mouse), main.turn)
	queue_redraw()

func _draw() -> void:
	if edge_lines.has(preview_pos):
		var line = edge_lines[preview_pos]
		if line != null:
			draw_line(line[0], line[1], color, 4)
			
	if points.has(preview_pos):
		draw_circle(preview_pos, 8, color)
	
	for road in roads:
		draw_line(edge_lines[road][0], edge_lines[road][1], color, 4) #main.players[roads[road]].color
	
	for settlement in settlements:
		draw_circle(settlement, 8, settlements[settlement].color, true)

#region Hex Grid

var grid_size: int = 5
var hex_radius: float = 36
var hex_apothem: float = hex_radius * sqrt(3.0) / 2.0
var height_diff: float = hex_radius + hex_apothem

func get_hex_position(index: int):
	var pos = Vector2(0,0)
	if index < 3:
		pos.x = (3 + 2*index) * hex_apothem
		pos.y = 0
	elif index < 7:
		pos.x = (2 + 2*(index-3)) * hex_apothem
		pos.y = hex_radius*1.5
	elif index < 12:
		pos.x = (1 + 2*(index-7)) * hex_apothem
		pos.y = hex_radius*3
	elif index < 16:
		pos.x = (2 + 2*(index-12)) * hex_apothem
		pos.y = hex_radius*4.5
	elif index < 19:
		pos.x = (3 + 2*(index-16)) * hex_apothem
		pos.y = hex_radius*6
	pos -= Vector2(hex_apothem*5, hex_radius*3)
	return pos

enum Dir {
	TOP,
	RIGHT_UP,
	RIGHT_DOWN,
	BOTTOM,
	LEFT_DOWN,
	LEFT_UP
}

func get_direction_vector(point:Dir) -> Vector2:
	match point:
		Dir.TOP: return Vector2(0, -hex_radius)
		Dir.RIGHT_UP: return Vector2(hex_apothem, -hex_radius/2.0)
		Dir.RIGHT_DOWN: return Vector2(hex_apothem, hex_radius / 2.0)
		Dir.BOTTOM: return Vector2(0, hex_radius)
		Dir.LEFT_DOWN: return Vector2(-hex_apothem, hex_radius / 2.0)
		Dir.LEFT_UP: return Vector2(-hex_apothem, -hex_radius / 2.0)
		_: return Vector2.ZERO

func get_points(tile: Tile):
	var p = []
	for dir in Dir.values():
		p.append(tile.pos + get_direction_vector(dir))
	return p

func get_point(pos: Vector2, max_dist: float = 20.0) -> Vector2:
	var lowest_distance = INF
	var found_point: Vector2
	for point: Vector2 in points:
		var dist = pos.distance_to(point)
		if dist < lowest_distance:
			lowest_distance = dist
			found_point = point
	if lowest_distance > max_dist: return Vector2.INF
	if found_point: return found_point
	return Vector2.INF

func get_edge_lines(tile: Tile) -> Dictionary[Vector2, Array]:
	var e: Dictionary[Vector2, Array]
	var p = get_points(tile)
	
	for i in range(p.size()):
		var a: Vector2 = p[i]
		var b: Vector2 = p[(i + 1) % p.size()]
		var mid: Vector2 = (a + b) / 2.0
		e[mid] = [a,b]
	
	return e

func get_edge(pos: Vector2) -> Vector2:
	var lowest_distance = INF
	var found_edge: Vector2
	for edge: Vector2 in edges:
		var dist = pos.distance_to(edge)
		if dist < lowest_distance:
			lowest_distance = dist
			found_edge = edge
	if lowest_distance > 12: return Vector2.INF
	if found_edge: return found_edge
	return Vector2.INF
	
func get_tile(pos: Vector2) -> Tile:
	var lowest_distance = INF
	var found_tile
	for tile: Tile in tiles:
		var dist = pos.distance_to(tile.pos)
		if dist < lowest_distance:
			lowest_distance = dist
			found_tile = tile
	return found_tile

func get_key(pos: Vector2) -> Vector2:
	var point: Vector2 = get_point(pos)
	var edge: Vector2 = get_edge(pos)
	if point != Vector2.INF: return point
	if edge != Vector2.INF: return edge
	return Vector2.INF
	
func get_key_unnocupied(pos: Vector2) -> Vector2:
	var point: Vector2 = get_point(pos)
	var edge: Vector2 = get_edge(pos)
	if !settlements.has(point) and point != Vector2.INF: return point
	if edge != Vector2.INF: return edge
	return Vector2.INF

#endregion

func _on_build_button_pressed() -> void:
	build_mode = !build_mode
