extends MultiplayerSpawner

@export var network_player: PackedScene

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	NetworkHandler.server_started.connect(_spawn_player.bind(multiplayer.get_unique_id()))

func _on_peer_connected(id: int) -> void:
	if multiplayer.is_server():
		_spawn_player(id)

func _spawn_player(id: int) -> void:
	var player: NetworkPlayer = network_player.instantiate()
	player.name = str(id)
	player.set_multiplayer_authority(id)
	get_node(spawn_path).add_child.call_deferred(player)
	setup_player_info.rpc(player, NetworkHandler.player_info[id])

@rpc("authority", "reliable", "call_local")
func setup_player_info(player: NetworkPlayer, info):
	player.setup_player_info(info.name, info.color)
