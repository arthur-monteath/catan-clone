class_name ClientBus extends Node


signal on_resources_changed(new_resources)

@rpc("authority", "call_remote", "reliable")
func update_resources(resources):
	on_resources_changed.emit(resources)


func a(): pass
