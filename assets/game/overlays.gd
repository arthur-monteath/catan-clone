extends Node2D

@onready var client: BoardClient = %BoardClient

func _process(_dt):
	queue_redraw()

func _draw() -> void:
	if !client.is_my_turn: return
	#region Structure Preview
	var preview = client.preview_pos
	if client.edges.has(preview):
		var color = NetworkHandler.get_player_color()
		var line = client.edge_lines[preview]
		var point1: Vector2 = line[0]
		var point2: Vector2 = line[1]
		var point3: Vector2 = point1 + (point2 - point1).normalized() * 12
		var point4: Vector2 = point2 + (point1 - point2).normalized() * 12
		if line != null:
			draw_line(point3, point4, color, 2)
	
	if client.build_mode and client.selected_structure == Board.Structure.ROAD: #TODO - Make this better, based on edges
		var preview_edges = []
		for settlement in client.settlements.keys():
			if !client.settlements[settlement].id == multiplayer.get_unique_id(): continue
			for e in client.edge_lines.keys():
				var edge: Array = client.edge_lines[e]
				if settlement.distance_to(edge[0]) < 0.1:
					preview_edges.append(edge)
				if settlement.distance_to(edge[1]) < 0.1:
					preview_edges.append(edge)
		
		for edge in preview_edges:
			var color = Color.from_rgba8(255,255,255,155)
			var point1: Vector2 = edge[0]
			var point2: Vector2 = edge[1]
			var point3: Vector2 = point1 + (point2 - point1).normalized() * 12
			var point4: Vector2 = point2 + (point1 - point2).normalized() * 12
			draw_line(point3, point4, color, 2)
		
	if client.points.has(preview) and !client.settlements.has(preview):
		#var color = NetworkHandler.get_player_color()
		draw_circle(preview, 4, Color.WHITE)
	#endregion
