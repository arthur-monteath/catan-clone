class_name RootUI
extends CanvasLayer

@rpc("authority", "reliable", "call_local")
func set_dice_spin(i: int, dice: Array[int]):
	dice1.rotation = -(i/5.0) * PI
	dice2.rotation = (i/5.0) * PI
	dice1.frame = dice[0]
	dice2.frame = dice[1]
	if i == 5: set_dice_result(dice)

func set_dice_result(dice: Array[int]):
	for t in get_tree().get_processed_tweens(): t.kill()
	var label = dice_result
	label.text = str(dice[0] + dice[1] + 2)
	label.label_settings.font_color = Color.WHITE
	label.show()
	var tween_font = get_tree().create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC).set_parallel()
	tween_font.tween_property(label.label_settings, "font_size", 64, 2).from(16)
	tween_font.tween_property(label, "position:y", -128, 2).as_relative().from(label.position.y)
	var tween_opacity = get_tree().create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween_opacity.tween_property(label.label_settings, "font_color:a", 0, 1).set_delay(2).from(1)
	tween_opacity.tween_property(label.label_settings, "outline_color:a", 0, 1).from(1)
	tween_opacity.tween_property(label.label_settings, "shadow_color:a", 0, 1).from(1)
	tween_opacity.tween_property(label, "position:y", 64, 1).set_delay(2).as_relative()
	tween_opacity.tween_callback(func():
		label.hide())
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
