# NetworkHandler.gd
extends Node

signal on_lobby_created

var lobby_id: int = 0
var is_host: bool = false
var is_joining: bool = false
var peer
var use_steam := false

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
		multiplayer.connected_to_server.connect(_on_connected_to_server)


func _on_lobby_joined(lobby_id: int, _permissions: int, _locked: bool, _response: int):
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


func _on_connected_to_server() -> void:
	_add_player(multiplayer.get_unique_id())

func _add_player(id: int = 1):
	var player := NetworkPlayer.new()
	player.name = str(id)
	player.id = id
	_player_manager().add_child.call_deferred(player)


func _remove_player(id: int):
	var player := _player_manager().get_node_or_null(str(id))
	if player: player.queue_free()


func _player_manager() -> PlayerManager:
	return get_tree().current_scene.get_node("%PlayerManager")
