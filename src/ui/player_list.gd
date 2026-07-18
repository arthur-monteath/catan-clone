class_name PlayerList extends VBoxContainer

const PLAYER_CONTAINER = preload("uid://cv1l06m4do1li")

@onready var _manager: PlayerManager = %PlayerManager

func _ready() -> void:
	_manager.child_entered_tree.connect(_add_entry)
	_manager.child_exiting_tree.connect(_remove_entry)
	for player in _manager.players():
		_add_entry(player)

func _add_entry(player: NetworkPlayer) -> void:
	var container := PLAYER_CONTAINER.instantiate()
	container.name = str(player.id)
	add_child(container)
	player.changed.connect(_refresh.bind(player, container))
	_refresh(player, container)

func _remove_entry(player: NetworkPlayer) -> void:
	var container := get_node_or_null(str(player.id))
	if container: container.queue_free()

func _refresh(player: NetworkPlayer, container: Node) -> void:
	if player.avatar != null: container.get_node("%PlayerAvatar").texture = player.avatar
	container.get_node("%Label").text = "%s\n[img]res://art/ui/resources/resources.png[/img] %s  [img]res://art/ui/action_cards/action_card_icon.png[/img] %s  [img]res://art/ui/trophy_icon.png[/img] %s" % [
		player.nickname,
		player.resource_total,
		player.action_card_total,
		player.victory_points,
	]
