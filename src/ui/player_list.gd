extends VBoxContainer

const PLAYER_CONTAINER = preload("uid://cv1l06m4do1li")

var _players: Array[NetworkPlayer]:
	set(v):
		for p in _players:
			p.changed.disconnect(_on_player_changed)
		_players = v
		for p in _players:
			p.changed.connect(_on_player_changed)


func _on_player_changed():
	for player in _players:
		var container = get_node_or_null(str(player.id))
		if container == null:
			container = PLAYER_CONTAINER.instantiate()
			container.name = str(player.id)
		
		container.get_node("%PlayerAvatar").texture = player.avatar
		container.get_node("%Label").text = "%s\n[img]res://art/ui/resources/resources.png[/img] %s  [img]res://art/ui/action_cards/action_card_icon.png[/img] %s  [img]res://art/ui/trophy_icon.png[/img] %s" % [
			player.nickname,
			player.resource_total,
			player.action_card_total,
			player.victory_points
		]
