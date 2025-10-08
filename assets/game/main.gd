extends Node
class_name Main

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
	
func _on_player_join(id: int):
	pass

func _process(delta: float) -> void:
	if !multiplayer.is_server(): return
	var timer = !turn_timer.is_stopped()
	if turn_bar.visible != timer:
		turn_bar.visible = timer
		
	if timer:
		turn_bar.value = turn_timer.time_left / turn_timer.wait_time

func _input(event: InputEvent) -> void:
	pass

func _process_dice(dice: Array[int]):
	var value: int = dice[0] + dice[1]
	for tile in board.tiles:
		if tile.number == value:
			board.give_resource(tile)

@onready var dice_button: Button = $CanvasLayer/DiceButton
@onready var d1 = dice_button.get_node("Dice")
@onready var d2 = dice_button.get_node("Dice2")

var dice: Array[int] = [0,0]
var dice_delay := 0.1
var dice_spinning := false

func _on_dice_button_pressed() -> void:
	_press_dice_request.rpc() #multiplayer.get_remote_sender_id() == players[turn].id

@rpc("any_peer", "reliable", "call_local")
func _press_dice_request() -> void:
	if not multiplayer.is_server(): return
	if dice_spinning: return
	dice_spinning = true
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
		dice_button.show()
		var counter = 1
		for p in player_list.get_children():
			var player = Player.new()
			player.node = p
			player.id = p.name
			player.name = "Player " + str(counter)
			counter += 1
			player.color = colors[randi_range(0,colors.size()-1)]
			players.append(player)
		on_turn_start()

func update_resources_ui():
	for player in players:
		resources_panel.set_resources.rpc_id(player.id, player.resources)

func on_turn_start():
	_set_player_outline(players[turn], true)
	turn_timer.start()
	
func end_turn():
	_set_player_outline(players[turn], false)
	turn += 1
	if turn >= len(players): turn = 0
	on_turn_start()
	
func _set_player_outline(player: Player, value: bool):
	player.node.get_node("Panel/Outline").visible = value
	
func _on_turn_timer_timeout() -> void: end_turn()

#func _initiate_debug_players():
	#for i in range(0,3):
		#var player = Player.new()
		#player.name = "Player " + String.num_int64(i+1)
		#player.color = colors[i]
		#players.append(player)
