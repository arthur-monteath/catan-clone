class_name BoardClient
extends Node2D

@onready var main: Main = get_tree().current_scene
@onready var board: Board = get_parent()
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

var points: Array[Vector2]
var edges: Array[Vector2]
var edge_lines: Dictionary[Vector2, Array]

var roads: Dictionary[Vector2, Dictionary]
var settlements: Dictionary[Vector2, Dictionary]

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
		t.get_node("Number").text = String.num_int64(number_tokens.pop_front())
		
		var pos = board.get_hex_position(i)
		t.global_position = pos
		
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
			board.request_settlement.rpc_id(1, pos)
		Board.Structure.ROAD:
			board.request_road.rpc_id(1, pos)

@rpc("authority", "reliable", "call_local")
func place_settlement(pos: Vector2, info: Dictionary):
	var settlement = SETTLEMENT.instantiate()
	settlement.position = pos
	var sprite: Sprite2D = settlement.get_node("Sprite2D")
	sprite.self_modulate = info.color
	settlements[pos] = info
	add_child(settlement)

@rpc("authority", "reliable", "call_local")
func place_road(pos: Vector2, info: Dictionary):
	var road = ROAD.instantiate()
	road.position = pos
	var line: Line2D = road.get_node("Line2D")
	line.add_point(edge_lines[pos][0] - road.global_position,0)
	line.add_point(edge_lines[pos][1] - road.global_position,1)
	line.self_modulate = info.color
	roads[pos] = info
	add_child(road)
#endregion

@rpc("authority", "reliable", "call_local")
func set_client_selected_structure(structure: Board.Structure):
	selected_structure = structure

var selected_structure: Board.Structure = Board.Structure.SETTLEMENT
#endregion

var preview_pos: Vector2 = Vector2.INF
var build_mode: bool = false
func _unhandled_input(_event: InputEvent) -> void:
	if !is_my_turn: return
	var mouse = get_global_mouse_position()
	match main.game_state:
		Main.State.FIRST_SETTLEMENT:
			if selected_structure == Board.Structure.SETTLEMENT:
				preview_pos = board.get_point(mouse)
			elif selected_structure == Board.Structure.ROAD: preview_pos = board.get_edge(mouse)
			if (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and preview_pos != Vector2.INF):
				request_structure(preview_pos, selected_structure)
		Main.State.SECOND_SETTLEMENT:
			if selected_structure == Board.Structure.SETTLEMENT:
				preview_pos = board.get_point(mouse)
			elif selected_structure == Board.Structure.ROAD: preview_pos = board.get_edge(mouse)
			if (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and preview_pos != Vector2.INF):
				request_structure(preview_pos, selected_structure)
		Main.State.BUILDING:
			if build_mode:
				if (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and preview_pos != Vector2.INF):
					settlements.set(board.get_point(mouse), main.turn)
					roads.set(board.get_edge(mouse), main.turn)
	queue_redraw()

func _draw() -> void:
	if edges.has(preview_pos):
		var color = NetworkHandler.get_player_color()
		var line = edge_lines[preview_pos]
		if line != null:
			draw_line(line[0], line[1], color, 2)
			
	if points.has(preview_pos):
		#var color = NetworkHandler.get_player_color()
		draw_circle(preview_pos, 4, Color.WHITE)
	
#region Debug
	#for road in roads:
		#var color = NetworkHandler.get_player_color()
		#draw_line(edge_lines[road][0], edge_lines[road][1], color, 4) #main.players[roads[road]].color
	
	#for settlement in settlements:
		#draw_circle(settlement, 8, settlements[settlement].color, true)
#endregion

func _on_build_button_pressed() -> void:
	build_mode = !build_mode
