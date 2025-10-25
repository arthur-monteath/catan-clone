extends Node
class_name Main

# This is basically the GameHandler / Server

enum State {
	LOBBY,
	FIRST_SETTLEMENT,
	SECOND_SETTLEMENT,
	ROLLING,
	BUILDING,
}

@export var game_state: State = State.LOBBY

enum Res {
	ORE,
	GRAIN,
	LUMBER,
	BRICK,
	WOOL,
}

const STRUCTURE_COSTS: Dictionary[Board.Structure, Dictionary] = {
	Board.Structure.SETTLEMENT: { Res.ORE: 2, Res.BRICK: 1 },
	Board.Structure.ROAD: { Res.LUMBER: 1, Res.BRICK: 1 },
}

class Player:
	var id: int
	var node: Node
	var name: String
	var color: Color
	var resources: Dictionary[Res, int]

var players: Array[Player]

const RESOURCE_VISUAL = preload("uid://ct8mbgdghj2nn")

@onready var resources_panel: Control = %ResourcesPanel
@onready var player_list: VBoxContainer = %PlayerList

@onready var turn_manager: TurnManager = %TurnManager
@onready var board: Board = %Board
@onready var client: BoardClient = %BoardClient
@onready var root_ui: RootUI = %RootUI
@onready var start_button: Button = %StartButton

@onready var SCREEN_CENTER = board.get_viewport_rect().get_center()

func _ready():
	multiplayer.peer_connected.connect(_on_player_join)
	NetworkHandler.server_started.connect(_on_server_started)
	
func _on_server_started():
	if multiplayer.is_server():
		start_button.show()
	
func _on_player_join(_id: int):
	pass

#@rpc("any_peer", "call_local", "reliable")
#func is_my_turn() -> bool:
	#if multiplayer.is_server() and game_state != State.LOBBY:
		#return multiplayer.get_remote_sender_id() == players[turn].id
	#return false

#func _process(_delta: float) -> void:
	#if !multiplayer.is_server(): return

#func _input(event: InputEvent) -> void:

func give_resources(id: int, resources_to_add: Dictionary, pos: Vector2 = Vector2.INF):
	for type in resources_to_add.keys():
		var resources = get_player_by_id(id).resources
		var give = func():
			if !resources.has(type): resources[type] = 1
			else: resources[type] += 1
			update_resources_ui()
		if pos != Vector2.INF:
			animate_resources({type:resources_to_add[type]}, pos, give)
		else: for i in range(0, resources_to_add[type]): give.call()

func animate_resources(resources_to_add: Dictionary, pos: Vector2, cb: Callable):
	for type in resources_to_add.keys():
		for i in range(0, resources_to_add[type]):
			_client_animate_resources.rpc_id(players[turn_manager.turn].id, type, pos)
			
			get_tree().create_timer(1).timeout.connect(cb)
			await get_tree().create_timer(0.05).timeout

@rpc("authority", "reliable", "call_local")
func _client_animate_resources(type: Res, pos: Vector2):
	var resource: Sprite2D = RESOURCE_VISUAL.instantiate()
	resource.texture = resources_panel.res[type]
	resource.position = pos
	var tween_pos = get_tree().create_tween()
	tween_pos.set_ease(Tween.EASE_IN_OUT)
	tween_pos.set_trans(Tween.TRANS_CUBIC)
	tween_pos.tween_property(resource, "position", Vector2(randfn(0, 64), randfn(0, 64)), 0.6).as_relative()
	tween_pos.tween_property(resource, "position", resources_panel.get_resource_position(type), 0.4)
	
	var tween_scale = get_tree().create_tween()
	tween_scale.set_ease(Tween.EASE_IN_OUT)
	tween_scale.set_trans(Tween.TRANS_CUBIC)
	tween_scale.tween_property(resource, "scale", Vector2(1,1), 0.6).from(Vector2(0,0))
	tween_scale.tween_property(resource, "scale", Vector2(-0.5,-0.5), 0.4).as_relative()
	root_ui.add_child(resource)
	tween_scale.tween_callback(resource.queue_free)

func take_resources(id: int, resources_to_take: Dictionary):
	for type in resources_to_take.keys():
		var resources = get_player_by_id(id).resources
		if !resources.has(type): resources[type] = resources_to_take[type]
		else: resources[type] -= resources_to_take[type]
	update_resources_ui()

func has_resources(resources: Dictionary, cost: Dictionary) -> bool:
	for type in cost.keys():
		if !resources.has(type) or resources[type] < cost[type]:
			return false
	return true

func buy(requester: int, structure: Board.Structure) -> bool:
	var resources = get_player_by_id(requester).resources
	var cost = STRUCTURE_COSTS[structure]
	
	if !has_resources(resources, cost): return false
	take_resources(requester, cost)
	update_resources_ui() # TODO - Why tf does this break?
	return true

func _process_dice(dice: Array[int]):
	var value: int = dice[0] + dice[1]
	for tile in board._tiles:
		if tile.number == value:
			var resource_info: Dictionary = board.get_tile_resources(tile)
			for id in resource_info.keys():
				give_resources(id, resource_info[id])
	update_resources_ui()

var dice_delay := 0.1

func _on_dice_button_pressed() -> void:
	_press_dice_request.rpc_id(1) #multiplayer.get_remote_sender_id() == players[turn].id

@rpc("any_peer", "reliable", "call_local")
func _press_dice_request() -> void:
	if !multiplayer.is_server(): return
	root_ui.set_player_specific_ui.rpc_id(players[turn_manager.turn].id, {
		"dice_enabled": false
	})
	var dice: Array[int]
	for i in range(1,6):
		dice = [randi()%6, randi()%6]
		root_ui.set_dice_spin.rpc(i, dice)
		await get_tree().create_timer(dice_delay).timeout
	_process_dice(dice)

func start_game():
	if !multiplayer.is_server(): return
	start_button.hide()
	for p: NetworkPlayer in player_list.get_children():
		var player = Player.new()
		player.node = p
		player.id = p.name
		player.name = p.player_name
		player.color = p.player_color
		players.append(player)
	# connect board server-side signals
	board.on_settlement_built.connect(_on_settlement_built)
	board.on_road_built.connect(_on_road_built)
	turn_manager.on_turn_start.connect(_on_turn_start)
	turn_manager.on_turn_end.connect(_on_turn_end)
	board.generate_map()
	game_state = State.FIRST_SETTLEMENT
	
	turn_manager.start_turn()

func _on_turn_start(turn: int):
	var player: Player = players[turn]
	var id = player.id
	
	player.node.set_outline.rpc(true)
	match game_state:
		State.FIRST_SETTLEMENT:
			for i in range(0,999):give_resources(player.id, STRUCTURE_COSTS[Board.Structure.SETTLEMENT], SCREEN_CENTER)
			client.set_client_selected_structure.rpc_id(id, Board.Structure.SETTLEMENT)
			await get_tree().create_timer(1).timeout
			root_ui.set_player_specific_ui.rpc_id(id, {
				"message": "Place your first settlement!"
			})
		State.SECOND_SETTLEMENT:
			give_resources(player.id, STRUCTURE_COSTS[Board.Structure.SETTLEMENT], SCREEN_CENTER)
			client.set_client_selected_structure.rpc_id(id, Board.Structure.SETTLEMENT)
			await get_tree().create_timer(1).timeout
			root_ui.set_player_specific_ui.rpc_id(id, {
				"message": "Place your second settlement!\nRemember, this one will immediately give you resources."
			})
		State.ROLLING:
			root_ui.set_player_specific_ui.rpc_id(id, {
				"dice_enabled": true
			})
			root_ui.set_player_specific_ui.rpc({
				"dice_visible": true
			})

func _on_turn_end(turn: int):
	var player: Player = players[turn]
	#var id = player.id
	player.node.set_outline.rpc(false)

func get_player_by_id(id: int):
	for player in players:
		if player.id == id: return player

func get_player_client_info_by_id(id: int):
	for player in players:
		if player.id == id:
			var dict = {
				"id": player.id,
				"color": player.color,
				"name": player.name,
			}
			return dict
	printerr("No player found with id ", id)

func update_resources_ui():
	for player in players:
		resources_panel.set_resources.rpc_id(player.id, player.resources)

#func _initiate_debug_players():
	#for i in range(0,3):
		#var player = Player.new()
		#player.name = "Player " + String.num_int64(i+1)
		#player.color = colors[i]
		#players.append(player)

func _on_road_built(_pos: Vector2, id: int) -> void:
	match game_state:
		State.FIRST_SETTLEMENT:
			
			turn_manager.end_turn()
		State.SECOND_SETTLEMENT:
			await get_tree().create_timer(1).timeout
			
			turn_manager.end_turn()

func _on_settlement_built(pos: Vector2, id: int) -> void: pass
	#match game_state:
		#State.FIRST_SETTLEMENT:
			#give_resources(id, STRUCTURE_COSTS[Board.Structure.ROAD], SCREEN_CENTER)
			#await get_tree().create_timer(1).timeout
			#root_ui.set_player_specific_ui.rpc_id(id, {
				#"message": "Place your first road!"
			#})
			#client.set_client_selected_structure.rpc_id(id, Board.Structure.ROAD)
			#
		#State.SECOND_SETTLEMENT:
			#await get_tree().create_timer(0.2).timeout
			#var screen_pos = get_viewport().get_canvas_transform().basis_xform(pos) + SCREEN_CENTER
			#give_resources(id, _get_resources_from_settlement(Vector2(0,0)), screen_pos)
			#await get_tree().create_timer(0.8).timeout
			#
			#root_ui.set_player_specific_ui.rpc_id(id, {
				#"message": "Place your second road!"
			#})
			#
			#give_resources(id, STRUCTURE_COSTS[Board.Structure.ROAD])
			#client.set_client_selected_structure.rpc_id(id, Board.Structure.ROAD)

func _get_resources_from_settlement(pos: Vector2) -> Dictionary[Res, int]:
	return { Res.ORE: 10 }
