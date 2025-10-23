extends GPUParticles2D

@export var on_spawn: bool = false

func _ready():
	if on_spawn:
		emitting = true

func start():
	emitting = true
