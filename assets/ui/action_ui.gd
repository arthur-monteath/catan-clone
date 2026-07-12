extends Control

signal trade_button_pressed
signal build_mode_changed(build_mode: bool)
signal on_structure_selected(structure: Board.Structure)

@onready var structure_list: VBoxContainer = %StructureList
@onready var build_button: FoldableContainer = %BuildButton
@onready var trade_button: Button = %TradeButton
@onready var card_container: HBoxContainer = %CardContainer
@onready var action_card_prompt: PanelContainer = %ActionCardPrompt
@onready var main: Main = get_tree().get_current_scene()

const STRUCTURE_BUTTON = preload("uid://davx3ceu4av3u")
const ACTION_CARD = preload("uid://dmncywki2xmjq")

var cards: Array


func _ready() -> void:
	for structure_name in Board.Structure.keys():
		var button: Button = STRUCTURE_BUTTON.instantiate()
		button.text = structure_name.to_pascal_case()
		structure_list.add_child(button)
		button.pressed.connect(_on_structure_selected
			.bind(Board.Structure[structure_name]))
	# Ensures the UI resets to folded state
	visibility_changed.connect(func(): build_button.fold())
	var no = action_card_prompt.get_node("%No") as TextureButton
	no.pressed.connect(action_card_prompt.hide)


func _on_build_button_folding_changed(is_folded: bool) -> void:
	emit_signal("build_mode_changed", !is_folded)


func _on_structure_selected(structure: Board.Structure):
	emit_signal("on_structure_selected", structure)


func _on_trade_button_pressed() -> void:
	emit_signal("trade_button_pressed")
	# Maybe in the future hide ActionUI on trade ui open?


@rpc("authority", "call_local", "reliable")
func _update_actions_cards_ui(cards: Array):
	self.cards = cards
	for info: Dictionary in cards:
		var card = ACTION_CARD.instantiate()
		if info.has("icon"):
			card.get_node("%Icon").texture = info.icon
		if info.has("title"):
			card.get_node("%Title").text = info.title
		card_container.add_child(card)
	for i in card_container.get_child_count():
		var card: MarginContainer = card_container.get_child(i)
		var others = {}
		for j in range(i+1, card_container.get_child_count()):
			others[card_container.get_child(j)] = 62 * j
		# (62 * card_container.get_child_count() - 1) * ease(float(j)/(card_container.get_child_count() - 1), 0.9) Unused easing math
		card.mouse_entered.connect(_on_card_hovered.bind(card, others))
		card.mouse_exited.connect(_on_card_released.bind(card, others))
		card.gui_input.connect(_on_card_receives_input.bind(i))


func _on_card_receives_input(event: InputEvent, index: int):
	if event.is_action_pressed("select_action_card"):
		_prompt_action_card_activation(index)


func _prompt_action_card_activation(index: int):
	#main.activate_action_card_request.
	var title = cards[index].title if cards[index].has("title") else "selected"
	var label = action_card_prompt.get_node("%Label") as Label
	label.text = "Are you sure you want to use the " + title + " card?"
	var yes = action_card_prompt.get_node("%Yes") as TextureButton
	# Clear all connections from yes button
	for conn in (yes.pressed as Signal).get_connections():
		yes.disconnect(yes.pressed, conn)
	
	action_card_prompt.show()


func _on_card_hovered(card: MarginContainer, others: Dictionary):
	card.z_index = 1
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT).set_parallel()
	tw.tween_property(card.get_child(0), "position:y", 0, 0.4)
	tw.tween_property(card, "scale", Vector2(1.1,1.1), 0.4)
	for other_card in others.keys():
		tw.tween_property(other_card, "position:x", others[other_card] + 40, 0.4)


func _on_card_released(card: MarginContainer, others: Dictionary):
	card.z_index = 0
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT).set_parallel()
	tw.tween_property(card.get_child(0), "position:y", 32, 0.4)
	tw.tween_property(card, "scale", Vector2(1,1), 0.4)
	for other_card in others.keys():
		tw.tween_property(other_card, "position:x", others[other_card], 0.35).set_delay(0.05)
