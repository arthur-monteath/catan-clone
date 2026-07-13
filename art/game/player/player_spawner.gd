extends MultiplayerSpawner

#func _on_peer_connected(id: int) -> void:
	#if multiplayer.is_server():
		#_spawn_player(id)
#
#func _spawn_player(id: int) -> void:
	#var player: NetworkPlayer = network_player.instantiate()
	#player.name = str(id)
	#get_node(spawn_path).add_child.call_deferred(player)
