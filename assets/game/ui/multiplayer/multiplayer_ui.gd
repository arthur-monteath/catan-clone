class_name MultiplayerUI
extends Control

@onready var _player_name: LineEdit = %PlayerName
@onready var _player_color_picker: ColorPickerButton = %PlayerColorPicker
@onready var _tutorial_button: CheckButton = %TutorialMode
@onready var host_button = $VBoxContainer/HostButton
@onready var join_button = $VBoxContainer/JoinButton
@onready var lobby_menu = %LobbyMenu
@onready var lobby_list = %LobbyList
@onready var lobby_spinner = %Spinner
@onready var refresh_lobbies_button = %RefreshLobbiesButton
@onready var close_lobby_menu_button = %CloseLobbyMenuButton
const LOBBY_ENTRY = preload("uid://bik6un8xolxrt")

var player_info:
	get: return {
		"name": _player_name.text.strip_edges(),
		"color": _player_color_picker.color,
		"tutorial": _tutorial_button.button_pressed
	}

func _ready():
	host_button.pressed.connect(_on_host_button_pressed)
	_player_name.placeholder_text = Steam.getPersonaName()
	
	join_button.pressed.connect(_on_join_button_pressed)
	Steam.lobby_match_list.connect(_on_lobby_list_fetched)
	
	refresh_lobbies_button.pressed.connect(_on_join_button_pressed)
	close_lobby_menu_button.pressed.connect(lobby_menu.hide)

func _on_host_button_pressed() -> void:
	NetworkHandler.host_lobby()
	hide()

func _on_join_button_pressed() -> void:
	_clear_lobby_list()
	lobby_menu.show()
	_request_lobbies()
	#var ip = "localhost" # "127.0.0.1"
	#NetworkHandler.join_lobby()

func _request_lobbies():
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	Steam.addRequestLobbyListResultCountFilter(4)
	Steam.requestLobbyList()

func _on_lobby_list_fetched(lobbies: Array):
	lobby_spinner.hide()
	for lobby in lobbies:
		var lobby_name = Steam.getLobbyData(lobby, "name")
		if lobby_name.is_empty(): continue
		
		var players = str(Steam.getNumLobbyMembers(lobby))
		var lobby_entry: Button = LOBBY_ENTRY.instantiate()
		lobby_entry.text = players + "/4 " + lobby_name
		
		lobby_list.add_child(lobby_entry)
	if lobby_list.get_children().is_empty():
		refresh_lobbies_button.show()

func _clear_lobby_list():
	for child in lobby_list.get_children():
		child.queue_free()
	lobby_spinner.show()
	refresh_lobbies_button.hide()
