class_name Board
extends Node2D

@onready var main: Main = $".."
@onready var client: BoardClient = $BoardClient

var _edges: Dictionary[Vector2i, Array]
var _edge_lines: Dictionary[Vector2i, Array]
var _points: Array[Vector2i]

var _tiles: Array[Tile]

var _roads: Dictionary[Vector2i, Dictionary]:
	get: return _roads
	set(value):
		_roads = value
		#client.update_roads.rpc(value)
var _settlements: Dictionary[Vector2i, Dictionary]:
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
	number_tokens.erase(7)
	number_tokens.append_array(range(3,12))
	number_tokens.erase(7)
	number_tokens.shuffle()
	
	for i in range(0, len(tile_types)):
		var t: Tile = Tile.new()
		t.type = tile_types[i]
		_tiles.append(t)
		
		var pos = get_hex_position(i)
		t.pos = pos
	
		for point in get_points(pos):
			t.points.append(point)
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

# TODO - MAKE KEYS RELIABLE THROUGH Vector2i

class Tile:
	var node: Node2D
	var type: TileType
	var pos: Vector2i
	var number: int
	var points: Array[Vector2i]
	var edges: Array[Vector2i]
#endregion

#region Building

enum Structure {
	SETTLEMENT,
	ROAD,
}

signal on_road_built
signal on_settlement_built

@rpc("any_peer", "reliable", "call_local")
func request_road(_pos: Vector2):
	if multiplayer.is_server():
		var pos: Vector2i = _pos.round()
		var requester = multiplayer.get_remote_sender_id()
		var valid_space: bool = _edges.has(pos) and !_roads.has(pos)
		var has_connection: bool = _road_has_connection(pos)
		if valid_space and has_connection and main.buy(requester, Structure.ROAD):
			var player_info = main.get_player_client_info_by_id(requester)
			_set_road(pos, player_info)
			emit_signal("on_road_built", pos, requester)

@rpc("any_peer", "reliable", "call_local")
func request_settlement(_pos: Vector2):
	if multiplayer.is_server():
		var pos: Vector2i = _pos.round()
		var requester = multiplayer.get_remote_sender_id()
		#var free_settlement: bool = main.game_state == Main.State.FIRST_SETTLEMENT or main.game_state == Main.State.SECOND_SETTLEMENT
		var valid_space: bool = _points.has(pos) and !_settlements.has(pos)
		if valid_space and main.buy(requester, Structure.SETTLEMENT):
			var player_info = main.get_player_client_info_by_id(requester)
			_set_settlement(pos, player_info)
			emit_signal("on_settlement_built", pos, requester)

func _set_road(pos: Vector2i, player: Dictionary):
	var info = { "id": player.id, "color": player.color }
	_roads.set(pos, info)
	client.place_road.rpc(pos, info)

func _set_settlement(pos: Vector2i, player: Dictionary):
	var info = { "id": player.id, "color": player.color }
	_settlements.set(pos, info)
	client.place_settlement.rpc(pos, info)

#endregion

func _get_tile_resources(tile: Tile) -> Dictionary:
	var resource_type: Main.Res = _tile_type_to_resource(tile.type)
	if resource_type == null: return {}
	var info = {}
	for point in get_points(tile.pos):
		if _settlements.has(point):
			info[_settlements[point].id] = { resource_type: 1 }
	return info

func _road_has_connection(pos: Vector2) -> bool:
	var key: Vector2i = pos.round()
	var _line_points: Array = _edge_lines[key]
	var line_points = [Vector2i(_line_points[0].round()), Vector2i(_line_points[1].round())]
	# Check for roads
	for road in _roads.keys():
		var _road_points = _edge_lines[road]
		var road_points = [Vector2i(_road_points[0].round()), Vector2i(_road_points[1].round())]
		if road_points[0] == line_points[0] or\
		road_points[0] == line_points[1] or\
		road_points[1] == line_points[0] or\
		road_points[1] == line_points[1]:
			return true
	# Check for settlements
	for point in line_points:
		if _settlements.has(point): return true
	return false

func get_point_adjacent_tile_resources(settlement_pos: Vector2i) -> Dictionary[Main.Res, int]:
	var resources: Dictionary[Main.Res, int] = {}
	for tile in _tiles:
		if settlement_pos in tile.points:
			var type = tile.type
			if resources.has(type): resources[type] += 1
			else: resources[type] = 1
			continue
	return resources

#region Hex Grid

const GRID_SIZE: int = 5
const HEX_RADIUS: float = 36
var HEX_APOTHEM: float = HEX_RADIUS * sqrt(3.0) / 2.0
var HEIGHT_DIFF: float = HEX_RADIUS + HEX_APOTHEM

func get_hex_position(index: int):
	var pos = Vector2(0,0)
	if index < 3:
		pos.x = (3 + 2*index) * HEX_APOTHEM
		pos.y = 0
	elif index < 7:
		pos.x = (2 + 2*(index-3)) * HEX_APOTHEM
		pos.y = HEX_RADIUS*1.5
	elif index < 12:
		pos.x = (1 + 2*(index-7)) * HEX_APOTHEM
		pos.y = HEX_RADIUS*3
	elif index < 16:
		pos.x = (2 + 2*(index-12)) * HEX_APOTHEM
		pos.y = HEX_RADIUS*4.5
	elif index < 19:
		pos.x = (3 + 2*(index-16)) * HEX_APOTHEM
		pos.y = HEX_RADIUS*6
	pos -= Vector2(HEX_APOTHEM*5, HEX_RADIUS*3)
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
		Dir.TOP: return Vector2(0, -HEX_RADIUS)
		Dir.RIGHT_UP: return Vector2(HEX_APOTHEM, -HEX_RADIUS/2.0)
		Dir.RIGHT_DOWN: return Vector2(HEX_APOTHEM, HEX_RADIUS / 2.0)
		Dir.BOTTOM: return Vector2(0, HEX_RADIUS)
		Dir.LEFT_DOWN: return Vector2(-HEX_APOTHEM, HEX_RADIUS / 2.0)
		Dir.LEFT_UP: return Vector2(-HEX_APOTHEM, -HEX_RADIUS / 2.0)
		_: return Vector2.ZERO

func get_points(pos: Vector2) -> Array[Vector2i]:
	var p: Array[Vector2i] = []
	for dir in Dir.values():
		p.append(Vector2i(Vector2(pos + get_direction_vector(dir)).round()))
	return p

# Returns the UNROUNDED, vector2 positions in the array
func get_edge_lines(pos: Vector2) -> Dictionary[Vector2i, Array]:
	var e: Dictionary[Vector2i, Array]
	var p = get_points(pos)
	
	for i in range(p.size()):
		var a: Vector2 = p[i]
		var b: Vector2 = p[(i + 1) % p.size()]
		var mid: Vector2i = ((a + b) / 2.0).round()
		e[mid] = [a,b]
	
	return e
	
func _get_tile(pos: Vector2) -> Tile:
	var lowest_distance = INF
	var found_tile
	for tile: Tile in _tiles:
		var dist = pos.distance_to(tile.pos)
		if dist < lowest_distance:
			lowest_distance = dist
			found_tile = tile
	return found_tile

#func get_key(pos: Vector2) -> Vector2:
	#var point: Vector2 = get_point(pos)
	#var edge: Vector2 = get_edge(pos)
	#if point != Vector2.INF: return point
	#if edge != Vector2.INF: return edge
	#return Vector2.INF
	#
#func get_key_unnocupied(pos: Vector2) -> Vector2:
	#var point: Vector2 = get_point(pos)
	#var edge: Vector2 = get_edge(pos)
	#if !_settlements.has(point) and point != Vector2.INF: return point
	#if edge != Vector2.INF: return edge
	#return Vector2.INF

#endregion
