class_name Resources extends Node

enum Type {
	ROCK,
	GRAIN,
	LUMBER,
	BRICK,
	SHEEP,
}

const BRICK_RES = preload("uid://cdu4eeivvpwur")
const GRAIN_RES = preload("uid://libiqm35tqh8")
const LUMBER_RES = preload("uid://bcyyypljqiaae")
const ROCK_RES = preload("uid://pqt0babio2su")
const SHEEP_RES = preload("uid://d0gx5knbx7me4")

static var resource_texture: Dictionary[Type, Texture2D] = {
	Type.ROCK: ROCK_RES,
	Type.GRAIN: GRAIN_RES,
	Type.LUMBER: LUMBER_RES,
	Type.BRICK: BRICK_RES,
	Type.SHEEP: SHEEP_RES,
}
