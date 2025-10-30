class_name Resources extends Node

enum Type {
	ORE,
	GRAIN,
	LUMBER,
	BRICK,
	WOOL,
}

const ORE: Texture2D = preload("uid://dpo1tsm4hi7rh")
const GRAIN: Texture2D = preload("uid://ci51nt8puxdik")
const LUMBER: Texture2D = preload("uid://34ej43vr0l7h")
const BRICK: Texture2D = preload("uid://o18pbrdgyip2")
const WOOL: Texture2D = preload("uid://cpyu3swdqn4k3")

static var resource_texture: Dictionary[Type, Texture2D] = {
	Type.ORE: ORE,
	Type.GRAIN: GRAIN,
	Type.LUMBER: LUMBER,
	Type.BRICK: BRICK,
	Type.WOOL: WOOL,
}
