extends Node

signal on_lobby_created

var lobby_id: int = 0
var is_host: bool = false
var is_joining: bool = false
var peer
var use_steam := false
const NETWORK_PLAYER: PackedScene = preload("uid://by1q5dsk0j4se")
var _server_player_info: Dictionary[int, Dictionary]

#region player information
func get_player_color() -> Color:
	if _server_player_info.has(multiplayer.get_unique_id()):
		return _server_player_info[multiplayer.get_unique_id()].color
	return Color.WHITE

@rpc("any_peer", "reliable", "call_local")
func update_player_information_server_rpc(info: Dictionary):
	if !multiplayer.is_server(): return
	_server_player_info[multiplayer.get_remote_sender_id()] = info
	_send_clients_player_information.rpc(_server_player_info)

@rpc("authority", "reliable", "call_local")
func _send_clients_player_information(server_info):
	for child: NetworkPlayer in get_tree().current_scene.get_node("%PlayerList").get_children():
		if server_info.has(int(child.name)):
			var info = server_info[int(child.name)]
			child.setup_player_info.rpc(info.name, info.color, info.tutorial, info.steam_id)
#endregion

func _ready():
	if use_steam:
		print("Steam Initialized: ", Steam.steamInit(480, true))
		Steam.initRelayNetworkAccess()
		Steam.lobby_created.connect(_on_lobby_created)
		Steam.lobby_joined.connect(_on_lobby_joined)
	else: print("Non-steam P2P mode")

func host_lobby() -> void:
	MainSpinner.instance.show()
	is_host = true
	
	if use_steam:
		Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, 4)
	else:
		peer = ENetMultiplayerPeer.new()
		peer.create_server(25565, 4) # <--- local port
		_init_peer()
		on_lobby_created.emit()


func _on_lobby_created(result: int, lobby_id: int):
	if result != Steam.RESULT_OK: return
	self.lobby_id = lobby_id
	peer = SteamMultiplayerPeer.new()
	peer.server_relay = true
	peer.create_host()
	_init_peer()
	on_lobby_created.emit()


func _init_peer():
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_add_player)
	multiplayer.peer_disconnected.connect(_remove_player)
	if is_host:
		_add_player()
	MainSpinner.instance.hide()


func join_lobby(lobby_id: int):
	if use_steam:
		is_joining = true
		Steam.joinLobby(lobby_id)
	else:
		peer = ENetMultiplayerPeer.new()
		var err = peer.create_client("127.0.0.1", lobby_id)
		if err: push_error("Failed to connect to host at %s:%d" % ["127.0.0.1", lobby_id])
		multiplayer.multiplayer_peer = peer
		multiplayer.peer_connected.connect(_add_player)
		multiplayer.peer_disconnected.connect(_remove_player)


func _on_lobby_joined(lobby_id: int, permissions: int, locked: bool, response: int):
	# Code that runs for everyone on lobby
	if !is_joining: return
	# Code that runs only on joining player
	self.lobby_id = lobby_id
	peer = SteamMultiplayerPeer.new()
	peer.server_relay = true
	peer.create_client(Steam.getLobbyOwner(lobby_id))
	multiplayer.multiplayer_peer = peer
	MainSpinner.instance.hide()
	is_joining = false


func _add_player(id: int = 1):
	var player = NETWORK_PLAYER.instantiate()
	player.name = str(id)
	get_node("/root/Main/RootUI/PlayerList").add_child.call_deferred(player)


func _remove_player(id: int):
	if !has_node(str(id)): return
	get_node(str(id)).queue_free()
