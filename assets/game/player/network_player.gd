class_name NetworkPlayer
extends Control

@onready var outline: PanelContainer = %Outline
@onready var player_image: TextureRect = %PlayerImage
@onready var player_color: Color = Color.WHITE
@onready var multiplayer_ui: MultiplayerUI = $"../../MultiplayerUI"

func setup_player_info(player_name: String, color: Color) -> void:
	get_node("%PlayerLabel").text = player_name
	player_color = color
	
@rpc("any_peer", "reliable", "call_local")
func set_outline(value: bool):
	outline.visible = value
	
#func set_message(text: String):
	
#func _input(event: InputEvent) -> void:
	#if !is_multiplayer_authority(): return
