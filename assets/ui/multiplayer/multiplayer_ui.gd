extends Control

@onready var ip_line: LineEdit = $VBoxContainer/IpLine

func _on_host_button_pressed() -> void:
	NetworkHandler.start_server()
	hide()

func _on_join_button_pressed() -> void:
	var ip := ip_line.text.strip_edges()
	if ip.is_empty(): ip = "localhost" #"127.0.0.1"
	NetworkHandler.start_client(ip)
	hide()
