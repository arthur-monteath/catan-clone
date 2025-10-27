extends Control

signal build_mode_changed(build_mode: bool)
signal on_structure_selected(structure: Board.Structure)

@onready var structure_list: VBoxContainer = %StructureList
@onready var build_button: FoldableContainer = %BuildButton
@onready var trade_button: FoldableContainer = %TradeButton

const STRUCTURE_BUTTON = preload("uid://davx3ceu4av3u")

func _ready() -> void:
	for structure_name in Board.Structure.keys():
		var button: Button = STRUCTURE_BUTTON.instantiate()
		button.text = structure_name.to_pascal_case()
		structure_list.add_child(button)
		button.pressed.connect(_on_structure_selected.bind(Board.Structure[structure_name]))
	visibility_changed.connect(func(): # Ensures the UI resets to folded state
		build_button.fold()
		trade_button.fold())

func _on_build_button_folding_changed(is_folded: bool) -> void:
	emit_signal("build_mode_changed", !is_folded)

func _on_structure_selected(structure: Board.Structure):
	emit_signal("on_structure_selected", structure)
