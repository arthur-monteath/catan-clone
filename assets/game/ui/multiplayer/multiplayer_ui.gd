class_name MultiplayerUI
extends Control

@onready var player_name: LineEdit = %PlayerName
@onready var player_color_picker: ColorPickerButton = %PlayerColorPicker

var player_info:
	get: return {
		"name": player_name.text.strip_edges(),
		"color": player_color_picker.color
	}

func _on_host_button_pressed() -> void:
	NetworkHandler.start_server(player_info)
	hide()

func _on_join_button_pressed() -> void:
	var ip = "localhost" #"127.0.0.1"
	NetworkHandler.start_client(ip, player_info)
	hide()
