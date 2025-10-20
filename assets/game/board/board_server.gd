class_name Board
extends Node2D

@onready var main: Main = $".."
@onready var client: BoardClient = $BoardClient

var _edges: Dictionary[Vector2, Array]
var _edge_lines: Dictionary[Vector2, Array]
var _points: Array[Vector2]

var _tiles: Array[Tile]

var _roads: Dictionary[Vector2, Dictionary]:
	get: return _roads
	set(value):
		_roads = value
		#client.update_roads.rpc(value)
var _settlements: Dictionary[Vector2, Dictionary]:
	get: return _settlements
	set(value):
		_settlements = value
		#client.update_settlements.rpc(value)
# Vector2 -> Dictionary:
#	id: int
#	color: Color

@onready var turn_manager: TurnManager = %TurnManager

var is_my_turn: bool = false
func _ready() -> void:
	if multiplayer.is_server():
		turn_manager.on_turn_start.connect(_set_turn)

func _set_turn(_turn):
	for peer in multiplayer.get_peers():
		client.set_is_my_turn.rpc_id(peer, turn_manager.is_my_turn(peer))
	client.set_is_my_turn.rpc_id(1, turn_manager.is_my_turn(multiplayer.get_unique_id()))

func generate_map() -> void:
	if !multiplayer.is_server(): return
	
	var tile_types: Array[TileType] = []
	for type in tileAmounts:
		for _i in range(tileAmounts[type]):
			tile_types.append(int(type))
	tile_types.shuffle()
	
	var number_tokens: Array[int] = []
	number_tokens.append_array(range(2,13))
	number_tokens.append_array(range(3,12))
	number_tokens.shuffle()
	
	for i in range(0, len(tile_types)):
		var t: Tile = Tile.new()
		t.type = tile_types[i]
		_tiles.append(t)
		
		var pos = get_hex_position(i)
		t.pos = pos
	
		for point in get_points(pos):
			_points.append(point)
		
		var edge_dict = get_edge_lines(pos)
		for edge in edge_dict.keys():
			if not _edges.has(edge):
				_edge_lines[edge] = edge_dict[edge]
				_edges[edge] = [_tiles[i]]
				_tiles[i].edges.append(edge)
			else:
				_edges[edge].append(_tiles[i])
	
	client.propagate_map.rpc(tile_types, number_tokens)

#region Tiles
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
	var pos: Vector2
	var number: int
	var edges: Array[Vector2]
#endregion

#region Building

enum Structure {
	SETTLEMENT,
	ROAD,
}

signal on_road_built
signal on_settlement_built

@rpc("any_peer", "reliable", "call_local")
func request_road(pos: Vector2):
	if multiplayer.is_server():
		var requester = multiplayer.get_remote_sender_id()
		var can_place: bool = _edges.has(pos) and !_roads.has(pos)
		if can_place and main.buy(requester, Structure.ROAD):
			var player_info = main.get_player_client_info_by_id(multiplayer.get_remote_sender_id())
			_set_road(pos, player_info)
			emit_signal("on_road_built", pos)

@rpc("any_peer", "reliable", "call_local")
func request_settlement(pos: Vector2):
	if multiplayer.is_server():
		var requester = multiplayer.get_remote_sender_id()
		#var free_settlement: bool = main.game_state == Main.State.FIRST_SETTLEMENT or main.game_state == Main.State.SECOND_SETTLEMENT
		var can_place: bool = _points.has(pos) and !_settlements.has(pos)
		if can_place and main.buy(requester, Structure.SETTLEMENT):
			var player_info = main.get_player_client_info_by_id(multiplayer.get_remote_sender_id())
			_set_settlement(pos, player_info)
			emit_signal("on_settlement_built", pos)

func _set_road(pos: Vector2, player: Dictionary):
	var info = { "id": player.id, "color": player.color }
	_roads.set(pos, info)
	client.place_road.rpc(pos, info)

func _set_settlement(pos: Vector2, player: Dictionary):
	var info = { "id": player.id, "color": player.color }
	_settlements.set(pos, info)
	client.place_settlement.rpc(pos, info)

#endregion

func get_resource_information(tile: Tile) -> Dictionary:
	var resource_type: Main.Res = _tile_type_to_resource(tile.type)
	if resource_type == null: return {}
	var info = {}
	for point in get_points(tile.pos):
		if _settlements.has(point):
			info[_settlements[point].id] = resource_type
	return info

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

func get_points(pos: Vector2):
	var p = []
	for dir in Dir.values():
		p.append(pos + get_direction_vector(dir))
	return p

func get_point(pos: Vector2, max_dist: float = 20.0) -> Vector2:
	var lowest_distance = INF
	var found_point: Vector2
	for point: Vector2 in _points:
		var dist = pos.distance_to(point)
		if dist < lowest_distance:
			lowest_distance = dist
			found_point = point
	if lowest_distance > max_dist: return Vector2.INF
	if found_point: return found_point
	return Vector2.INF

func get_edge_lines(pos: Vector2) -> Dictionary[Vector2, Array]:
	var e: Dictionary[Vector2, Array]
	var p = get_points(pos)
	
	for i in range(p.size()):
		var a: Vector2 = p[i]
		var b: Vector2 = p[(i + 1) % p.size()]
		var mid: Vector2 = (a + b) / 2.0
		e[mid] = [a,b]
	
	return e

func get_edge(pos: Vector2) -> Vector2:
	var lowest_distance = INF
	var found_edge: Vector2
	for edge: Vector2 in _edges:
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
	for tile: Tile in _tiles:
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
	if !_settlements.has(point) and point != Vector2.INF: return point
	if edge != Vector2.INF: return edge
	return Vector2.INF

#endregion
