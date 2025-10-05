extends Node

enum Res {
	ORE,
	GRAIN,
	LUMBER,
	BRICK,
}

class Player:
	var name: String
	var color: Color
	var resources: Dictionary[Res, int]

var players: Array[Player]
var turn = 0

@onready var turn_label: Label = $CanvasLayer/PanelContainer/MarginContainer/TurnLabel
@onready var turn_timer: Timer = $TurnTimer
@onready var board: Board = $Board

func _ready():
	_initiate_debug_players()
	_update_turn_label()

func _input(event: InputEvent) -> void:
	pass

func _process_dice(dice: Array[int]):
	for tile in board.tiles:
		if tile.number == dice[0]:
			tile.give_resource()
		if tile.number == dice[1]:
			tile.give_resource()

func _on_turn_timer_timeout() -> void:
	turn += 1
	if turn >= len(players): turn = 0
	_update_turn_label()
	
func _update_turn_label():
	turn_label.text = players[turn].name + "'s Turn"
	turn_label.label_settings.font_color = players[turn].color

@onready var dice_button: Button = $CanvasLayer/DiceButton
@onready var d1 = dice_button.get_node("Dice")
@onready var d2 = dice_button.get_node("Dice2")

var dice := [0,0]
var dice_delay := 0.1
var dice_spinning := false

func _on_dice_button_pressed() -> void:
	if dice_spinning: return
	dice_spinning = true
	for i in range(1,6):
		dice = [randi()%6, randi()%6]
		d1.rotation = -(i/5.0) * PI
		d2.rotation = (i/5.0) * PI
		d1.frame = dice[0]
		d2.frame = dice[1]
		await get_tree().create_timer(dice_delay).timeout
	_process_dice(dice)
	dice_spinning = false

var colors = [
	Color.ORANGE_RED,
	Color.LAWN_GREEN,
	Color.DEEP_SKY_BLUE,
]

func _initiate_debug_players():
	for i in range(0,3):
		var player = Player.new()
		player.name = "Player " + String.num_int64(i+1)
		player.color = colors[i]
		players.append(player)
