class_name RootUI extends CanvasLayer

func _ready() -> void:
	base_position = dice_result.position

@rpc("authority", "reliable", "call_local")
func set_dice_spin(i: int, dice: Array[int]):
	dice1.rotation = -(i/5.0) * PI
	dice2.rotation = (i/5.0) * PI
	dice1.frame = dice[0]
	dice2.frame = dice[1]
	if i == 5: set_dice_result(dice)

var base_position: Vector2
var result_tween: Tween
func set_dice_result(dice: Array[int]):
	if is_instance_valid(result_tween): # Cancel existing animation
		result_tween.kill()
		result_tween = null
	var label = dice_result
	label.modulate.a = 1
	label.text = str(dice[0] + dice[1] + 2)
	label.show()
	var tw := get_tree().create_tween()
	result_tween = tw
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tw.tween_interval(0.2)
	tw.set_parallel(true)
	tw.tween_property(label.label_settings, "font_size", 64, 1.5).from(16)
	tw.tween_property(label, "position:y", -128, 1.8).as_relative().from(base_position.y + 96)
	tw.set_parallel(false)
	tw.tween_interval(1.8)
	tw.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tw.set_parallel(true)
	tw.tween_property(label, "modulate:a", 0, 0.5).from(1)
	tw.tween_property(label, "position:y", 96, 0.5).as_relative().from(base_position.y - 32)
	tw.tween_property(label.label_settings, "font_size", 16, 0.5).from(64)
	tw.set_parallel(false)
	tw.tween_callback(Callable(label, "hide"))
		#label.position.y += 64)

@onready var dice_result: Label = %DiceResult
@onready var dice_button: Button = %DiceButton
@onready var dice_area: Control = %DiceArea
@onready var dice1 = %Dice2
@onready var dice2 = %Dice1
@rpc("authority", "reliable", "call_local")
func set_player_specific_ui(args: Dictionary):
	if args.has("message") and (!args.has("tutorial") or args["tutorial"]): # Only players with tutorial On will receive tutorial messages
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
