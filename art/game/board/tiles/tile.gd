extends Node2D


@onready var hex: Sprite2D = %HexSprite
@onready var outline_sprite = %OutlineSprite

var outline_color: Color:
	set(v):
		outline_color = v
		outline_sprite.self_modulate = v

@export var sand_color: Color = Color("e5b96c")


func set_highlighted(v: bool = true):
	outline_color = Color.WHITE if v else sand_color
	outline_sprite.z_index = -1 if v else -2
