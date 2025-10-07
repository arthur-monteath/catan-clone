extends MultiplayerSpawner

@export var network_player: PackedScene

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)

func _on_peer_connected(id: int) -> void:
	if !multiplayer.is_server(): return
	print("peer connected id: " + str(id))
	var p: Node = network_player.instantiate()
	p.name = str(id)
	p.set_multiplayer_authority(id)
	get_node(spawn_path).add_child.call_deferred(p)
