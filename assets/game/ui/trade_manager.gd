class_name TradeManager extends Control

@onready var main: Main = $".."
@onready var turn_manager: TurnManager = %TurnManager

@onready var trade_ui: VBoxContainer = %TradeUI
@onready var player_list: VBoxContainer = %PlayerList
const TRADE_PLAYER_BUTTON = preload("uid://dgmrocg0hjbdr")

var trade_owner_id: int
var player_choices: Dictionary[int, bool]

func propose_trade(offer: Dictionary, request: Dictionary):
	send_trade_request.rpc_id(1, offer, request)

@rpc("any_peer", "reliable", "call_local")
func send_trade_request(offer: Dictionary, request: Dictionary):
	if !multiplayer.is_server(): return
	trade_owner_id = multiplayer.get_remote_sender_id()
	var is_requester_turn: bool = trade_owner_id == main.players[turn_manager.turn].id
	if !is_requester_turn: return # Safety check to only allow players on their turn to request a trade
	for peer in multiplayer.get_peers():
		offer_trade.rpc(offer, request, trade_owner_id)

@rpc("any_peer", "reliable", "call_remote")
func send_trade_suggestion(): pass

@onready var trade_offer: PanelContainer = %TradeOffer
@rpc("authority", "reliable", "call_local")
func offer_trade(offer: Dictionary, request: Dictionary, owner: int):
	trade_owner_id = owner
	# Setup offer
	# Setup X
	# Setup Y
	# Setup Z
	pass
	# Setup

@export var player_choice_texture: Array[Texture2D]
@rpc("any_peer", "reliable", "call_local")
func set_player_choice(choice: bool):
	var is_trade_owner = multiplayer.get_unique_id() != trade_owner_id
	if !multiplayer.is_server() and is_trade_owner: return
	var choicemaker_id = multiplayer.get_remote_sender_id()
	for player in player_list:
		if player.name == str(choicemaker_id):
			player_choices[choicemaker_id] = choice
			if is_trade_owner:
				var image: TextureRect = player.get_node("$HBoxContainer/Choice")
				image.texture = player_choice_texture[int(choice)]
			break

func _on_offer_reject_pressed() -> void:
	trade_offer.hide()
	set_player_choice.rpc_id(1, false)

func _on_offer_modify_pressed() -> void:
	trade_offer.hide()
	#send_trade_suggestion.rpc_id(trade_owner_id, new_offer, new_request)

func _on_offer_accept_pressed() -> void:
	trade_offer.hide()
	set_player_choice.rpc_id(1, true)

func open_trade_ui(offer: Dictionary, request: Dictionary):
	show()
	for resource in Main.Res.keys():
		# check for existence of each resource in both offer or request to prefill the info in case its a modification not a new trade.
		pass # TODO - Create one Resource button for each resources (In offer and in request button

func on_offer_changed():
	# Acquire offer data based on Client's UI
	
	# Make checks to update UI such as Bank
	pass

func is_offer_bank_acceptable(offer: Dictionary) -> bool:
	return true
