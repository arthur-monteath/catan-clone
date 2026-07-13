class_name NetworkPlayer
extends Control

@onready var outline: PanelContainer = %Outline
@onready var player_image: TextureRect = %PlayerImage
var steam_id: int
var player_color: Color = Color.WHITE
var player_name: String = "player_0"
var tutorial_mode: bool = true

func _enter_tree() -> void:
	var info = get_tree().current_scene.get_node("%MultiplayerUI").player_info
	info.name = info.name if len(info.name) > 0 else Steam.getPersonaName()
	player_name = info.name
	player_color = info.color
	tutorial_mode = info.tutorial
	info.steam_id = Steam.getSteamID()
	NetworkHandler.update_player_information_server_rpc.rpc_id(1, info)

func _on_loaded_avatar(user_id: int, avatar_size: int, avatar_buffer: PackedByteArray) -> void:
	print("Avatar for user: %s" % user_id)
	print("Size: %s" % avatar_size)
	var avatar_image: Image = Image.create_from_data(avatar_size, avatar_size, false, Image.FORMAT_RGBA8, avatar_buffer)
	# Apply the image to a texture
	var avatar_texture: ImageTexture = ImageTexture.create_from_image(avatar_image)
	player_image.texture = avatar_texture

#func _ready():
	#print("(READY)Player ID: ", multiplayer.get_unique_id(), " | name: ", player_name, " color: ", player_color)

@rpc("any_peer", "reliable", "call_local")
func setup_player_info(new_name: String, color: Color, tutorial: bool, steam_id: int) -> void:
	player_name = new_name
	get_node("%PlayerLabel").text = new_name
	player_color = color
	get_node("%Outline").self_modulate = color
	tutorial_mode = tutorial
	self.steam_id = steam_id
	Steam.getPlayerAvatar(2, steam_id)
	Steam.avatar_loaded.connect(_on_loaded_avatar)
	
@rpc("authority", "reliable", "call_local")
func set_outline(value: bool):
	outline.visible = value
	
#func set_message(text: String):
	
#func _input(event: InputEvent) -> void:
	#if !is_multiplayer_authority(): return
