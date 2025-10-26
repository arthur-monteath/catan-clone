class_name BoardClient
extends Node2D

@onready var main: Main = get_tree().current_scene
@onready var board: Board = get_parent()
@onready var robber: Node2D = %Robber
@export var textures: Dictionary[Board.TileType, Texture2D]

const TILE: PackedScene = preload("uid://dtvr5obijngj")
const SETTLEMENT: PackedScene = preload("uid://be4lgt7hs4inj")
const ROAD: PackedScene = preload("uid://ltem0vjldnni")

#var player: Main.Player
#@rpc("authority", "reliable", "call_local")
#func set_local_player():
	#for p in players:
		#if p.id == multiplayer.get_unique_id():
			#player = p

var points: Array[Vector2i]
var edges: Array[Vector2i]
var edge_lines: Dictionary[Vector2i, Array]

var roads: Dictionary[Vector2i, Dictionary]
var settlements: Dictionary[Vector2i, Dictionary]

@onready var action_ui: Control = $"../../RootUI/ActionUI" # TODO: Figure out where to go with this
var is_my_turn: bool = false
@rpc("authority", "reliable", "call_local")
func set_is_my_turn(value: bool):
	is_my_turn = value
	action_ui.visible = value
	if !value: build_mode = false

@rpc("authority", "reliable", "call_local")
func propagate_map(tile_types, number_tokens):	
	for i in range(0, len(tile_types)):
		var t = TILE.instantiate()
		t.get_node("Hex").texture = textures[tile_types[i]]
		t.get_node("Outline").texture = textures[tile_types[i]]
		
		var pos = board.get_hex_position(i)
		t.global_position = pos
		
		if tile_types[i] == Board.TileType.DESERT:
			robber.position = t.global_position
			robber.visible = true
		else:
			t.get_node("Number").text = String.num_int64(number_tokens.pop_front())
		
		for point in board.get_points(pos):
			points.append(point)
		
		var edge_dict = board.get_edge_lines(pos)
		for edge in edge_dict.keys():
			if not edges.has(edge):
				edge_lines[edge] = edge_dict[edge]
				edges.append(edge)
			#else:
				#edges[edge].append(t)
		
		add_child(t)

#region Structure Building
func request_structure(pos: Vector2, structure: Board.Structure):
	match structure:
		Board.Structure.SETTLEMENT:
			#print("Settlement requested by ", multiplayer.get_unique_id())
			board.request_settlement.rpc_id(1, pos)
		Board.Structure.ROAD:
			#print("Road requested by ", multiplayer.get_unique_id())
			board.request_road.rpc_id(1, pos)

@rpc("authority", "reliable", "call_local")
func place_settlement(pos: Vector2i, info: Dictionary):
	var settlement = SETTLEMENT.instantiate()
	settlement.position = pos
	var sprite: Sprite2D = settlement.get_node("Sprite2D")
	sprite.self_modulate = info.color
	settlements[pos] = info
	add_child(settlement)

@rpc("authority", "reliable", "call_local")
func place_road(pos: Vector2i, info: Dictionary):
	var road = ROAD.instantiate()
	road.position = pos
	var line: Line2D = road.get_node("Line2D")
	var point1: Vector2 = edge_lines[pos][0] - road.global_position
	var point2: Vector2 = edge_lines[pos][1] - road.global_position
	var point3: Vector2 = point1 + (point2 - point1).normalized() * 12
	var point4: Vector2 = point2 + (point1 - point2).normalized() * 12
	line.add_point(point3, 0)
	line.add_point(point4, 1)
	line.self_modulate = info.color
	roads[pos] = info
	add_child(road)
#endregion

@rpc("authority", "reliable", "call_local")
func set_client_selected_structure(structure: Board.Structure):
	selected_structure = structure

var selected_structure: Board.Structure = Board.Structure.SETTLEMENT
#endregion

var preview_pos: Vector2i = Vector2i.MAX
var build_mode: bool = false
func _unhandled_input(_event: InputEvent) -> void:
	if !is_my_turn: return
	var mouse = get_global_mouse_position()
	#print("This is me, id ", multiplayer.get_unique_id(), " with the state ", main.game_state)
	match main.game_state:
		Main.State.FIRST_SETTLEMENT:
			if selected_structure == Board.Structure.SETTLEMENT:
				preview_pos = get_point(mouse)
			elif selected_structure == Board.Structure.ROAD: preview_pos = get_edge(mouse)
			if (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and preview_pos != Vector2i.MAX):
				request_structure(preview_pos, selected_structure)
		Main.State.SECOND_SETTLEMENT:
			if selected_structure == Board.Structure.SETTLEMENT:
				preview_pos = get_point(mouse)
			elif selected_structure == Board.Structure.ROAD: preview_pos = get_edge(mouse)
			if (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and preview_pos != Vector2i.MAX):
				request_structure(preview_pos, selected_structure)
		Main.State.BUILDING:
			if build_mode:
				if (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and preview_pos != Vector2i.MAX):
					settlements.set(get_point(mouse), main.turn)
					roads.set(get_edge(mouse), main.turn)

func _process(_dt):
	queue_redraw()

func _draw() -> void:
	if !is_my_turn: return
	#region Structure Preview
	if edges.has(preview_pos):
		var color = NetworkHandler.get_player_color()
		var line = edge_lines[preview_pos]
		var point1: Vector2 = line[0]
		var point2: Vector2 = line[1]
		var point3: Vector2 = point1 + (point2 - point1).normalized() * 12
		var point4: Vector2 = point2 + (point1 - point2).normalized() * 12
		if line != null:
			draw_line(point3, point4, color, 2)
	
	if build_mode and selected_structure == Board.Structure.ROAD: #TODO - Make this better, based on edges
		var preview_edges = []
		for settlement in settlements.keys():
			if !settlements[settlement].id == multiplayer.get_unique_id(): continue
			for e in edge_lines.keys():
				var edge: Array = edge_lines[e]
				if settlement.distance_to(edge[0]) < 0.1:
					preview_edges.append(edge)
				if settlement.distance_to(edge[1]) < 0.1:
					preview_edges.append(edge)
		
		for edge in preview_edges:
			var color = Color.from_rgba8(255,255,255,155)
			var point1: Vector2 = edge[0]
			var point2: Vector2 = edge[1]
			var point3: Vector2 = point1 + (point2 - point1).normalized() * 12
			var point4: Vector2 = point2 + (point1 - point2).normalized() * 12
			draw_line(point3, point4, color, 2)
		
	if points.has(preview_pos):
		#var color = NetworkHandler.get_player_color()
		draw_circle(preview_pos, 4, Color.WHITE)
	#endregion
	
	#region Debug
	#for road in roads:
		#var color = NetworkHandler.get_player_color()
		#draw_line(edge_lines[road][0], edge_lines[road][1], color, 4) #main.players[roads[road]].color
	
	#for settlement in settlements:
		#draw_circle(settlement, 8, settlements[settlement].color, true)
	
	#var point1: Vector2 = Vector2(-64,64)
	#var point2: Vector2 = Vector2(64,-64)
	#var point3 = point1 + (point2 - point1).normalized() * 12
	#var point4 = point2 + (point1 - point2).normalized() * 12
	#draw_line(point3, point4, Color.RED, 4)
	#draw_circle(point1, 2, Color.RED)
	#draw_circle(point2, 2, Color.RED)
#endregion

func get_point(pos: Vector2, max_dist: float = 20.0) -> Vector2i:
	var lowest_distance = INF
	var found_point: Vector2i
	for point: Vector2i in points:
		var dist = pos.distance_to(point)
		if dist < lowest_distance:
			lowest_distance = dist
			found_point = point
	if lowest_distance > max_dist: return Vector2i.MAX
	if found_point: return found_point
	return Vector2i.MAX

func get_edge(pos: Vector2) -> Vector2i:
	var lowest_distance = INF
	var found_edge: Vector2i
	for edge: Vector2i in edges:
		var dist = pos.distance_to(edge)
		if dist < lowest_distance:
			lowest_distance = dist
			found_edge = edge
	if lowest_distance > 12: return Vector2i.MAX
	if found_edge: return found_edge
	return Vector2i.MAX

func _on_build_button_pressed() -> void:
	build_mode = !build_mode
	print("build mode = ", build_mode)
