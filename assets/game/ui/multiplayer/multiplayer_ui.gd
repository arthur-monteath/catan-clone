class_name MultiplayerUI
extends Control

@onready var _player_name: LineEdit = %PlayerName
@onready var _player_color_picker: ColorPickerButton = %PlayerColorPicker
@onready var _tutorial_button: CheckButton = %TutorialMode
@onready var host_button = $VBoxContainer/HostButton
@onready var join_button = $VBoxContainer/JoinButton

var player_info:
	get: return {
		"name": _player_name.text.strip_edges(),
		"color": _player_color_picker.color,
		"tutorial": _tutorial_button.button_pressed
	}

func _ready():
	host_button.pressed.connect(_on_host_button_pressed)
	_player_name.placeholder_text = Steam.getPersonaName()
	#NetworkHandler.join_lobby()

func _on_host_button_pressed() -> void:
	NetworkHandler.host_lobby()
	hide()

func _on_join_button_pressed() -> void:
	#var ip = "localhost" # "127.0.0.1"
	#NetworkHandler.join_lobby()
	hide()
