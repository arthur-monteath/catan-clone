extends Node
class_name Main

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

class Player:
	var id: int
	var node: Node
	var name: String
	var color: Color
	var resources: Dictionary[Res, int]

var players: Array[Player]
var turn = 0

@onready var resources_panel: Control = $CanvasLayer/Resources
@onready var player_list: VBoxContainer = $CanvasLayer/PlayerList
@onready var turn_bar: ProgressBar = $CanvasLayer/TurnBar
@onready var turn_timer: Timer = $TurnTimer
@onready var board: Board = $Board
@onready var start_button: Button = $CanvasLayer/StartButton

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

func _process(_delta: float) -> void:
	if !multiplayer.is_server(): return
	var timer = !turn_timer.is_stopped()
	if turn_bar.visible != timer:
		turn_bar.visible = timer
		
	if timer:
		turn_bar.value = turn_timer.time_left / turn_timer.wait_time

#func _input(event: InputEvent) -> void:

func _process_dice(dice: Array[int]):
	var value: int = dice[0] + dice[1]
	for tile in board.tiles:
		if tile.number == value:
			board.give_resource(tile)
	update_resources_ui()

@onready var dice_area: Control = $CanvasLayer/Dice
@onready var d1 = dice_area.get_node("Sprite1")
@onready var d2 = dice_area.get_node("Sprite2")

var dice_delay := 0.1
var dice_spinning := false

func _on_dice_button_pressed() -> void:
	_press_dice_request.rpc() #multiplayer.get_remote_sender_id() == players[turn].id

@rpc("any_peer", "reliable", "call_local")
func _press_dice_request() -> void:
	if not multiplayer.is_server(): return
	_set_dice_area.rpc(false)
	if dice_spinning: return
	dice_spinning = true
	var dice: Array[int]
	for i in range(1,6):
		dice = [randi()%6, randi()%6]
		_spin_dice.rpc_id(0, i, dice)
		await get_tree().create_timer(dice_delay).timeout
	_process_dice(dice)
	dice_spinning = false

@rpc("authority", "reliable", "call_local")
func _spin_dice(i: int, dice):
	d1.rotation = -(i/5.0) * PI
	d2.rotation = (i/5.0) * PI
	d1.frame = dice[0]
	d2.frame = dice[1]

var colors = [
	Color.ORANGE_RED,
	Color.LAWN_GREEN,
	Color.DEEP_SKY_BLUE,
]

func start_game():
	if multiplayer.is_server():
		start_button.hide()
		var counter = 1
		for p in player_list.get_children():
			var player = Player.new()
			player.node = p
			player.id = p.name
			player.name = "Player " + str(counter)
			print("New Player: " + player.name + " node: " + str(player.node))
			counter += 1
			player.color = colors[randi_range(0,colors.size()-1)]
			board.set_color.rpc_id(player.id, player.color)
			players.append(player)
		# connect board server-side signals
		board.on_settlement_built.connect(_on_settlement_built)
		board.generate_map()
		game_state = State.FIRST_SETTLEMENT
		on_turn_start()

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

func on_turn_start():
	for peer in multiplayer.get_peers(): # Does not include the server
		board.set_is_my_turn.rpc_id(peer, players[turn].id == peer)
	board.set_is_my_turn.rpc_id(1, players[turn].id == multiplayer.get_unique_id())
	_set_player_outline(players[turn], true)
	_update_player_specific_ui.rpc(players[turn].id)
	turn_timer.start()

@rpc("authority", "reliable", "call_local")
func _update_player_specific_ui(id: int):
	var _is_my_turn: bool = multiplayer.get_unique_id() == id
	match game_state:
		State.FIRST_SETTLEMENT:
			_send_client_message.rpc_id(id, "Place your first settlement!")
		State.SECOND_SETTLEMENT:
			_send_client_message.rpc_id(id, "Place your second settlement!\nRemember, this one will immediately give you resources.")
		State.ROLLING:
			_set_dice_area(_is_my_turn)
	
@onready var message_box: Panel = $CanvasLayer/MessageBox
@onready var message_label: Label = $CanvasLayer/MessageBox/PanelContainer/MarginContainer/Label

@rpc("authority", "reliable", "call_local")
func _send_client_message(message: String):
	message_label.text = message
	message_box.show()
	
@rpc("authority", "reliable", "call_local")
func _set_dice_area(value: bool):
	dice_area.get_child(0).visible = value

var turn_increment: int = 1
func end_turn():
	_set_player_outline(players[turn], false)
	turn += turn_increment
	if turn >= len(players) or turn < 0:
		match game_state:
			State.FIRST_SETTLEMENT:
				game_state = State.SECOND_SETTLEMENT
				turn_increment = -1
				turn -= 1
			State.SECOND_SETTLEMENT:
				game_state = State.ROLLING
				turn_increment = 1
				turn = 0
	on_turn_start()
	
func _set_player_outline(player: Player, value: bool):
	player.node.set_outline.rpc(value)
	
func _on_turn_timer_timeout() -> void: end_turn()

#func _initiate_debug_players():
	#for i in range(0,3):
		#var player = Player.new()
		#player.name = "Player " + String.num_int64(i+1)
		#player.color = colors[i]
		#players.append(player)

func _on_settlement_built(_pos: Vector2) -> void:
	match game_state:
		State.FIRST_SETTLEMENT:
			end_turn()
		State.SECOND_SETTLEMENT:
			game_state = State.ROLLING
			end_turn()

func _on_message_box_gui_input(event: InputEvent) -> void:
	if event.is_pressed():
		message_box.hide()
