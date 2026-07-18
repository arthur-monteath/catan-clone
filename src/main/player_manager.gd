class_name PlayerManager
extends Node

# NetworkHandler owns the connection and spawns/frees these player nodes as our
# children. This manager never touches peer lifecycle; it is the one place their
# data is read (get_player / players) and synced. Views can watch the built-in
# child_entered_tree / child_exiting_tree signals to track the roster.

func get_player(id: int) -> NetworkPlayer:
	return get_node_or_null(str(id)) as NetworkPlayer

func players() -> Array[NetworkPlayer]:
	var result: Array[NetworkPlayer] = []
	for child in get_children():
		result.append(child)
	return result

#region Identity (local client -> server -> all)
func submit_local_identity() -> void:
	var info = get_tree().current_scene.get_node("%MultiplayerUI").player_info
	var nickname: String = info.name
	var steam_id := 0
	if NetworkHandler.use_steam:
		if nickname.is_empty(): nickname = Steam.getPersonaName()
		steam_id = Steam.getSteamID()
	if nickname.is_empty(): nickname = "player_%d" % multiplayer.get_unique_id()

	if multiplayer.is_server():
		_broadcast_identity(multiplayer.get_unique_id(), nickname, info.color, info.tutorial, steam_id)
	else:
		_submit_identity.rpc_id(1, nickname, info.color, info.tutorial, steam_id)

@rpc("any_peer", "reliable")
func _submit_identity(nickname: String, color: Color, tutorial: bool, steam_id: int) -> void:
	if not multiplayer.is_server(): return
	_broadcast_identity(multiplayer.get_remote_sender_id(), nickname, color, tutorial, steam_id)

func _broadcast_identity(id: int, nickname: String, color: Color, tutorial: bool, steam_id: int) -> void:
	_sync_identity.rpc(id, nickname, color, tutorial, steam_id)

@rpc("authority", "reliable", "call_local")
func _sync_identity(id: int, nickname: String, color: Color, tutorial: bool, steam_id: int) -> void:
	var player := get_player(id)
	if player: player.set_identity(nickname, color, tutorial, steam_id)
#endregion

#region Game state (server owns all; owner gets its hand, everyone gets totals)
func set_resources(id: int, resources: Dictionary) -> void:
	if not multiplayer.is_server(): return
	var player := get_player(id)
	if player == null: return
	player.set_resources(resources)
	if id != multiplayer.get_unique_id():
		_sync_owned_resources.rpc_id(id, id, resources)
	_sync_resource_total.rpc(id, NetworkPlayer.total_of(resources))

@rpc("authority", "reliable")
func _sync_owned_resources(id: int, resources: Dictionary) -> void:
	var player := get_player(id)
	if player: player.set_resources(resources)

@rpc("authority", "reliable")
func _sync_resource_total(id: int, total: int) -> void:
	var player := get_player(id)
	if player: player.set_resource_total(total)

func set_action_cards(id: int, cards: Array) -> void:
	if not multiplayer.is_server(): return
	var player := get_player(id)
	if player == null: return
	player.set_action_cards(cards)
	if id != multiplayer.get_unique_id():
		_sync_owned_action_cards.rpc_id(id, id, cards)
	_sync_action_card_total.rpc(id, cards.size())

@rpc("authority", "reliable")
func _sync_owned_action_cards(id: int, cards: Array) -> void:
	var player := get_player(id)
	if player: player.set_action_cards(cards)

@rpc("authority", "reliable")
func _sync_action_card_total(id: int, total: int) -> void:
	var player := get_player(id)
	if player: player.set_action_card_total(total)

func set_victory_points(id: int, value: int) -> void:
	if not multiplayer.is_server(): return
	_sync_victory_points.rpc(id, value)

@rpc("authority", "reliable", "call_local")
func _sync_victory_points(id: int, value: int) -> void:
	var player := get_player(id)
	if player: player.set_victory_points(value)
#endregion
