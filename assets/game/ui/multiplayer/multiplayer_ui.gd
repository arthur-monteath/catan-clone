class_name MultiplayerUI
extends Control

@onready var _player_name: LineEdit = %PlayerName
@onready var _player_color_picker: ColorPickerButton = %PlayerColorPicker
@onready var _tutorial_button: CheckButton = %TutorialMode

var player_info:
	get: return {
		"name": _player_name.text.strip_edges(),
		"color": _player_color_picker.color,
		"tutorial": _tutorial_button.button_pressed
	}

func _on_host_button_pressed() -> void:
	NetworkHandler.start_server()
	hide()

func _on_join_button_pressed() -> void:
	var ip = "localhost" #"127.0.0.1"
	NetworkHandler.start_client(ip)
	hide()
