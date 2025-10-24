class_name NetworkPlayer
extends Control

@onready var outline: PanelContainer = %Outline
@onready var player_image: TextureRect = %PlayerImage
var player_color: Color = Color.WHITE
var player_name: String = "player_0"

func _enter_tree() -> void:
	var info = get_tree().current_scene.get_node("%MultiplayerUI").player_info
	player_name = info.name
	player_color = info.color
	NetworkHandler.update_player_information_server_rpc.rpc_id(1, info)

#func _ready():
	#print("(READY)Player ID: ", multiplayer.get_unique_id(), " | name: ", player_name, " color: ", player_color)

@rpc("any_peer", "reliable", "call_local")
func setup_player_info(new_name: String, color: Color) -> void:
	player_name = new_name
	get_node("%PlayerLabel").text = new_name
	player_color = color
	get_node("%Outline").self_modulate = color
	
@rpc("authority", "reliable", "call_local")
func set_outline(value: bool):
	outline.visible = value
	
#func set_message(text: String):
	
#func _input(event: InputEvent) -> void:
	#if !is_multiplayer_authority(): return
