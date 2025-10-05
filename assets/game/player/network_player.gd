extends Control

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())
	
func _input(event: InputEvent) -> void:
	if !is_multiplayer_authority(): return
