extends Node

const MAX_CLIENTS := 8
const PORT := 25565

var peer: ENetMultiplayerPeer

signal server_started

var _server_player_info: Dictionary[int, Dictionary]

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
			child.setup_player_info.rpc(info.name, info.color, info.tutorial)

func start_server() -> void:
	peer = ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT, MAX_CLIENTS)
	if err != OK: push_error("Server failed: %s" % err); return
	multiplayer.multiplayer_peer = peer
	#player_info[1] = info
	emit_signal("server_started")

func start_client(ip: String) -> void:
	peer = ENetMultiplayerPeer.new()
	var err := peer.create_client(ip, PORT)
	if err != OK: push_error("Client failed: %s" % err); return
	multiplayer.multiplayer_peer = peer
