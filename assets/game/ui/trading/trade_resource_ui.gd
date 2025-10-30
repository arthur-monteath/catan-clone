class_name TradeResourceUI extends PanelContainer

signal on_resource_amount_changed(change: int)

@onready var amount: Label = %Amount

@onready var add_button: Button = %AddButton
@onready var subtract_button: Button = %SubtractButton

func set_icon(image: Texture2D):
	get_node("%Icon").texture = image

func set_value(value: int):
	get_node("%Amount").text = str(value)

func _on_subtract_button_pressed() -> void:
	if (int(amount.text) <= 0):
		amount.text = "0"
		return
	emit_signal("on_resource_amount_changed", -1)
	amount.text = str(int(amount.text) - 1)

func _on_add_button_pressed() -> void:
	emit_signal("on_resource_amount_changed", 1)
	amount.text = str(int(amount.text) + 1)
