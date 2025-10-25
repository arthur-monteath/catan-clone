extends Control
class_name ResourcesUI

@onready var grid: GridContainer = $PanelContainer/MarginContainer/Grid
const RESOURCE_TEMPLATE = preload("uid://dbuvbml0vr4ip")

@export var res: Dictionary[Main.Res, Texture]
var resource_labels: Dictionary[Main.Res, Label]

func _ready():
	for resource in Main.Res.values():
		var res_ui = RESOURCE_TEMPLATE.instantiate()
		resource_labels[resource] = res_ui.get_node("Label")
		resource_labels[resource].text = "0"
		
		res_ui.get_node("Image").texture = res[resource]
		
		grid.add_child(res_ui)

@rpc("authority","reliable","call_local")
func set_resources(resource_inventory: Dictionary[Main.Res, int]):
	for resource in resource_inventory.keys():
		resource_labels[resource].text = str(resource_inventory[resource])

func get_resource_position(type: Main.Res) -> Vector2:
	var icon: Control = resource_labels[type].get_parent().get_child(0)
	return icon.get_global_transform().get_origin() + Vector2(16,16)
