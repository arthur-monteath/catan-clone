class_name TurnManager
extends Timer

signal on_turn_start
signal on_turn_end

@onready var main: Main = $".."

var turn = 0
@onready var turn_bar: ProgressBar = %TurnBar

func _ready() -> void:
	timeout.connect(end_turn)

func _process(_delta: float) -> void:
	if !multiplayer.is_server(): return
	var timer = !is_stopped()
	if turn_bar.visible != timer:
		turn_bar.visible = timer
		
	if timer:
		turn_bar.value = time_left / wait_time

func is_my_turn(id: int) -> bool:
	if !multiplayer.is_server(): return false
	return id == main.players[turn].id

func start_turn():
	if !multiplayer.is_server(): return
	emit_signal("on_turn_start", turn)
	if not (main.game_state == Main.State.FIRST_SETTLEMENT or main.game_state == Main.State.SECOND_SETTLEMENT):
		start()

var turn_increment: int = 1
func end_turn():
	if !multiplayer.is_server(): return
	emit_signal("on_turn_end", turn)
	turn += turn_increment
	if turn >= len(main.players) or turn < 0:
		match main.game_state:
			Main.State.FIRST_SETTLEMENT:
				main.game_state = Main.State.SECOND_SETTLEMENT
				turn_increment = -1
				turn = len(main.players)-1
			Main.State.SECOND_SETTLEMENT:
				main.game_state = Main.State.ROLLING
				turn_increment = 1
				turn = 0
	start_turn()


func _on_end_turn_pressed() -> void:
	end_turn()
