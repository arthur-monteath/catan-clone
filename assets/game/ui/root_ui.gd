class_name RootUI
extends CanvasLayer

@rpc("authority", "reliable", "call_local")
func set_dice_spin(i: int, dice: Array[int]):
	dice1.rotation = -(i/5.0) * PI
	dice2.rotation = (i/5.0) * PI
	dice1.frame = dice[0]
	dice2.frame = dice[1]

@onready var dice_button: Button = %DiceButton
@onready var dice_area: Control = %DiceArea
@onready var dice1 = %Dice2
@onready var dice2 = %Dice1
@rpc("authority", "reliable", "call_local")
func set_player_specific_ui(args: Dictionary):
	if args.has("message"):
		_send_client_message(args.message)
	if args.has("dice_enabled"):
		dice_button.visible = args.dice_enabled
	if args.has("dice_visible"):
		dice_area.visible = args.dice_visible

@onready var message_box: Panel = %MessageBox
@onready var message_label: Label = %MessageLabel
func _send_client_message(message: String):
	message_label.text = message
	message_box.show()

func _on_message_box_gui_input(event: InputEvent) -> void:
	if event.is_pressed():
		message_box.hide()
