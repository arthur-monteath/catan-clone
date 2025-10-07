extends Node

const MAX_CLIENTS := 8
const PORT := 25565

var peer: ENetMultiplayerPeer

signal server_started

func start_server() -> void:
	peer = ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT, MAX_CLIENTS)
	if err != OK: push_error("Server failed: %s" % err); return
	multiplayer.multiplayer_peer = peer
	emit_signal("server_started")

func start_client(ip: String) -> void:
	peer = ENetMultiplayerPeer.new()
	var err := peer.create_client(ip, PORT)
	if err != OK: push_error("Client failed: %s" % err); return
	multiplayer.multiplayer_peer = peer
