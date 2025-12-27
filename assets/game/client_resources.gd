class_name ClientResources

static var local_resources: Dictionary[Resources.Type, int] = {}

static func update_local_resources(dict: Dictionary[Resources.Type, int]):
	local_resources = dict.duplicate(true)

static func get_local_resources() -> Dictionary:
	return local_resources

static func get_amount(type: Resources.Type) -> int:
	return local_resources.get(type, 0)
