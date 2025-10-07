extends Node2D
class_name Board

enum TileType {
	BRICK,
	LUMBER,
	ORE,
	GRAIN,
	WOOL,
	DESERT
}

@onready var main: Node = $".."

@export var textures: Dictionary[TileType, Texture2D]
var tile_prefab: PackedScene = preload("res://assets/tiles/tile.tscn")

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

func give_resource(tile: Tile):
		for edge in edges:
			if roads.has(edge):
				var resource_type
				main.players[roads[edge]].resources.has()

var edges: Dictionary[Vector2, Array]
var edge_lines: Dictionary[Vector2, Array]
var points: Array[Vector2]

var tiles: Array[Tile]
var roads: Dictionary[Vector2, int]
var settlements: Dictionary[Vector2, int]

func _ready() -> void:
	for type in tileAmounts:
		for i in range(tileAmounts[type]):
			var t = Tile.new()
			t.type = type
			tiles.append(t)
	tiles.shuffle()
	
	var number_tokens: Array[int]
	number_tokens.append_array(range(2,13))
	number_tokens.append_array(range(3,12))
	number_tokens.shuffle()
	
	for i in range(0, len(tiles)):
		var t = tile_prefab.instantiate()
		tiles[i].node = t
		t.get_node("Hex").texture = textures[tiles[i].type]
	
		tiles[i].number = number_tokens.pop_front()
		
		var pos = get_hex_position(i)
		tiles[i].pos = pos
		
		for point in get_points(tiles[i]):
			points.append(point)
		
		var edge_dict = get_edges(tiles[i])
		for edge in edge_dict:
			if not edges.has(edge):
				edge_lines[edge] = edge_dict[edge]
				edges[edge] = [tiles[i]]
			else:
				edges[edge].append(tiles[i])
		
		add_child(t)

#var mouse = get_global_mouse_position()
#func _unhandled_input(event: InputEvent) -> void:
	#if !multiplayer.is_server() and multiplayer.is_server():
		#mouse = get_global_mouse_position()
		#if (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
			#settlements.set(get_point(mouse), main.turn)
			#roads.set(get_edge(mouse), main.turn)
		#queue_redraw()

func _draw() -> void:
	for road in roads:
		draw_line(edge_lines[road][0], edge_lines[road][1], main.players[roads[road]].color, 4)
	
	for settlement in settlements:
		draw_circle(settlement, 8, main.players[settlements[settlement]].color, true)

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

func get_point(pos: Vector2):
	var lowest_distance = INF
	var found_point: Vector2
	for point: Vector2 in points:
		var dist = pos.distance_to(point)
		if dist < lowest_distance:
			lowest_distance = dist
			found_point = point
	if found_point: return found_point
	return null

func get_edges(tile: Tile):
	var e: Dictionary[Vector2, Array]
	var p = get_points(tile)
	
	for i in range(p.size()):
		var a: Vector2 = p[i]
		var b: Vector2 = p[(i + 1) % p.size()]
		var mid: Vector2 = (a + b) / 2.0
		e[mid] = [a,b]
	
	return e

func get_edge(pos: Vector2):
	var lowest_distance = INF
	var found_edge: Vector2
	for edge: Vector2 in edges:
		var dist = pos.distance_to(edge)
		if dist < lowest_distance:
			lowest_distance = dist
			found_edge = edge
	if found_edge: return found_edge
	return null

func get_tile(pos: Vector2) -> Tile:
	var lowest_distance = INF
	var found_tile
	for tile: Tile in tiles:
		var dist = pos.distance_to(tile.pos)
		if dist < lowest_distance:
			lowest_distance = dist
			found_tile = tile
	return found_tile
