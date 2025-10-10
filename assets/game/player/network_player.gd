extends Control
@onready var resources_ui: Control = $"../../Resources"

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())
	
@rpc("any_peer", "reliable", "call_local")
func set_outline(value: bool):
	$Panel/Outline.visible = value
	
#func set_message(text: String):
	
#func _input(event: InputEvent) -> void:
	#if !is_multiplayer_authority(): return
