class_name BoardClient
extends Node2D

#@onready var main: Main = get_tree().current_scene
@onready var board: Board = get_parent()
@export var textures: Dictionary[Board.TileType, Texture2D]

const TILE: PackedScene = preload("uid://dtvr5obijngj")
const SETTLEMENT: PackedScene = preload("uid://be4lgt7hs4inj")
const ROAD: PackedScene = preload("uid://be4lgt7hs4inj")

#var player: Main.Player
#@rpc("authority", "reliable", "call_local")
#func set_local_player():
	#for p in players:
		#if p.id == multiplayer.get_unique_id():
			#player = p

@onready var action_ui: Control = $"../CanvasLayer/ActionUI" # TODO: Figure out where to go with this
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
	add_child(settlement)

@rpc("authority", "reliable", "call_local")
func place_road(pos: Vector2, info: Dictionary):
	var road = ROAD.instantiate()
	road.position = pos
	var sprite: Sprite2D = road.get_node("Sprite2D")
	sprite.self_modulate = info.color
	add_child(road)
#endregion

var selected_structure: Board.Structure = Board.Structure.SETTLEMENT
#endregion

var preview_pos: Vector2 = Vector2.INF
var build_mode: bool = false
func _unhandled_input(_event: InputEvent) -> void:
	if !is_my_turn: return
	var mouse = get_global_mouse_position()
	#match main.game_state:
		#Main.State.FIRST_SETTLEMENT or Main.State.SECOND_SETTLEMENT:
			#if selected_structure == Structure.SETTLEMENT:
				#preview_pos = get_point(mouse)
			#else: preview_pos = get_edge(mouse)
			#if (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and preview_pos != Vector2.INF):
				#request_structure(preview_pos, selected_structure)
		#Main.State.BUILDING:
			#if build_mode:
				#if (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and preview_pos != Vector2.INF):
					#settlements.set(get_point(mouse), main.turn)
					#roads.set(get_edge(mouse), main.turn)
	queue_redraw()

#func _draw() -> void:
	#if edge_lines.has(preview_pos):
		#var line = edge_lines[preview_pos]
		#if line != null:
			#draw_line(line[0], line[1], color, 4)
			#
	#if points.has(preview_pos):
		#draw_circle(preview_pos, 8, color)
	#
	#for road in roads:
		#draw_line(edge_lines[road][0], edge_lines[road][1], color, 4) #main.players[roads[road]].color
	#
	#for settlement in settlements:
		#draw_circle(settlement, 8, settlements[settlement].color, true)

func _on_build_button_pressed() -> void:
	build_mode = !build_mode
