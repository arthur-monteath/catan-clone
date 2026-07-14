class_name ResourceVisualizer extends Control


var resources: Dictionary:
	set(v):
		resources = v
		update_visuals()


func update_visuals():
	for child in get_children():
		child.queue_free()
	for resource in resources.keys():
		for i in range(resources[resource]):
			var tex = TextureRect.new()
			tex.texture = Resources.resource_texture[resource]
			add_child(tex)
