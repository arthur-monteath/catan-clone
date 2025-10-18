extends Node

const MAX_CLIENTS := 8
const PORT := 25565

var peer: ENetMultiplayerPeer

signal server_started

var player_info: Dictionary

@rpc("any_peer", "reliable", "call_local")
func add_player_info(info, id: int = multiplayer.get_remote_sender_id()):
	if !player_info.has(id): player_info.set(id, info)

func start_server(info) -> void:
	peer = ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT, MAX_CLIENTS)
	if err != OK: push_error("Server failed: %s" % err); return
	multiplayer.multiplayer_peer = peer
	player_info[1] = info
	emit_signal("server_started")

func start_client(ip: String, info) -> void:
	peer = ENetMultiplayerPeer.new()
	var err := peer.create_client(ip, PORT)
	if err != OK: push_error("Client failed: %s" % err); return
	multiplayer.multiplayer_peer = peer
	print(multiplayer.is_server())
