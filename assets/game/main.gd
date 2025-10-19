extends Node
class_name Main

enum State {
	LOBBY,
	FIRST_SETTLEMENT,
	SECOND_SETTLEMENT,
	ROLLING,
	BUILDING,
}

var game_state: State = State.LOBBY:
	get: return game_state
	set(new_state): if multiplayer.is_server(): game_state = new_state

enum Res {
	ORE,
	GRAIN,
	LUMBER,
	BRICK,
	WOOL,
}

class Player:
	var id: int
	var node: Node
	var name: String
	var color: Color
	var resources: Dictionary[Res, int]

var players: Array[Player]

@onready var resources_panel: Control = %ResourcesPanel
@onready var player_list: VBoxContainer = %PlayerList

@onready var turn_manager: TurnManager = %TurnManager
@onready var board: Board = %Board
@onready var root_ui: RootUI = %RootUI
@onready var start_button: Button = %StartButton

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

func _process_dice(dice: Array[int]):
	var value: int = dice[0] + dice[1]
	for tile in board.tiles:
		if tile.number == value:
			board.give_resource(tile)
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

var colors = [
	Color.ORANGE_RED,
	Color.LAWN_GREEN,
	Color.DEEP_SKY_BLUE,
]

func start_game():
	if !multiplayer.is_server(): return
	start_button.hide()
	var counter = 1
	for p in player_list.get_children():
		var player = Player.new()
		player.node = p
		player.id = p.name
		player.name = "Player " + str(counter)
		counter += 1
		player.color = colors[randi_range(0,colors.size()-1)]
		players.append(player)
	# connect board server-side signals
	board.on_settlement_built.connect(_on_settlement_built)
	turn_manager.on_turn_start.connect(_on_turn_start)
	turn_manager.on_turn_end.connect(_on_turn_end)
	board.generate_map()
	game_state = State.FIRST_SETTLEMENT
	
	turn_manager.start_turn()

func _on_turn_start(turn: int):
	var player: Player = players[turn]
	var id = player.id
	#for peer in multiplayer.get_peers(): # Does not include the server
		#board.set_is_my_turn.rpc_id(peer, id == peer)
	#board.set_is_my_turn.rpc_id(1, id == multiplayer.get_unique_id())
	
	player.node.set_outline.rpc(true)
	match game_state:
		State.FIRST_SETTLEMENT:
			root_ui.set_player_specific_ui.rpc_id(id, {
				"message": "Place your first settlement!"
			})
		State.SECOND_SETTLEMENT:
			root_ui.set_player_specific_ui.rpc_id(id, {
				"message": "Place your second settlement!\nRemember, this one will immediately give you resources."
			})
		State.ROLLING:
			root_ui.set_player_specific_ui.rpc_id(id, {
				"show_dice": true
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

func update_resources_ui():
	for player in players:
		resources_panel.set_resources.rpc_id(player.id, player.resources)

#func _initiate_debug_players():
	#for i in range(0,3):
		#var player = Player.new()
		#player.name = "Player " + String.num_int64(i+1)
		#player.color = colors[i]
		#players.append(player)

func _on_settlement_built(_pos: Vector2) -> void:
	match game_state:
		State.FIRST_SETTLEMENT:
			pass
		State.SECOND_SETTLEMENT:
			game_state = State.ROLLING
