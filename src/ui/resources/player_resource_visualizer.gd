extends ResourceVisualizer


func _ready():
	#Client.on_resources_changed.connect(func(r): resources = r)
	#resources = Client.resources
	resources = {
		Resources.Type.BRICK: 2,
		Resources.Type.ROCK: 4,
		Resources.Type.GRAIN: 4,
		Resources.Type.LUMBER: 4,
		Resources.Type.SHEEP: 4,
	}
