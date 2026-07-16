class_name NetworkPlayer extends Node

signal changed

var id: int
var steam_id: int
var nickname: String = "player_0"
var color: Color = Color.WHITE
var tutorial_mode: bool = true
# Itemized hands live only on the owning client and the server; every other
# client sees the totals only.
var resources: Dictionary[Resources.Type, int]
var resource_total: int = 0
var action_cards: Array
var action_card_total: int = 0
var victory_points: int = 0
var avatar: Texture2D


static func total_of(hand: Dictionary) -> int:
	var sum := 0
	for amount in hand.values(): sum += amount
	return sum

#func _enter_tree() -> void:
	#var info = get_tree().current_scene.get_node("%MultiplayerUI").player_info
	#info.name = info.name if len(info.name) > 0 else Steam.getPersonaName()
	#nickname = info.name
	#color = info.color
	#tutorial_mode = info.tutorial
	#info.steam_id = Steam.getSteamID()
	#NetworkHandler.update_player_information_server_rpc.rpc_id(1, info)

func _load_avatar() -> void:
	if not NetworkHandler.use_steam or steam_id == 0: return
	if not Steam.avatar_loaded.is_connected(_on_avatar_loaded):
		Steam.avatar_loaded.connect(_on_avatar_loaded)
	Steam.getPlayerAvatar(2, steam_id)
 
func _on_avatar_loaded(user_id: int, size: int, buffer: PackedByteArray) -> void:
	if user_id != steam_id: return
	var image := Image.create_from_data(size, size, false, Image.FORMAT_RGBA8, buffer)
	avatar = ImageTexture.create_from_image(image)
	changed.emit()

func set_identity(_nickname: String, _color: Color, _tutorial: bool, _steam_id: int) -> void:
	nickname = _nickname
	color = _color
	tutorial_mode = _tutorial
	if _steam_id != steam_id:
		steam_id = _steam_id
		_load_avatar()
	changed.emit()

func set_resources(_resources: Dictionary) -> void:
	resources = _resources
	resource_total = total_of(_resources)
	changed.emit()
 
func set_resource_total(value: int) -> void:
	resource_total = value
	changed.emit()
 
func set_action_cards(_cards: Array) -> void:
	action_cards = _cards
	action_card_total = _cards.size()
	changed.emit()
 
func set_action_card_total(value: int) -> void:
	action_card_total = value
	changed.emit()
 
func set_victory_points(value: int) -> void:
	victory_points = value
	changed.emit()
