extends Node

const IP_ADDRESS: String = "localhost"
const MAX_CLIENTS = 8
const PORT: int = 25565

var peer: ENetMultiplayerPeer

func start_server() -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT, MAX_CLIENTS)
	multiplayer.multiplayer_peer = peer

func start_client():
	peer = ENetMultiplayerPeer.new()
	peer.create_client(IP_ADDRESS, PORT)
	multiplayer.multiplayer_peer = peer
