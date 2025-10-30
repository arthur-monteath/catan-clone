class_name TradeManager extends Control

@onready var main: Main = get_tree().get_current_scene()
@onready var turn_manager: TurnManager = %TurnManager

@onready var trade_container: PanelContainer = $TradeContainer
@onready var trade_ui: VBoxContainer = %TradeUI
@onready var player_list: VBoxContainer = %PlayerList
const TRADE_PLAYER_BUTTON = preload("uid://dgmrocg0hjbdr")
const TRADE_RESOURCE = preload("uid://c32k37svumggt")

var trade_owner_id: int
var trade_offer: Dictionary[Resources.Type, int]
var trade_request: Dictionary[Resources.Type, int]
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

@onready var offer_popup: PanelContainer = %TradeOffer
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
	offer_popup.hide()
	set_player_choice.rpc_id(1, false)

func _on_offer_modify_pressed() -> void:
	offer_popup.hide()
	#send_trade_suggestion.rpc_id(trade_owner_id, new_offer, new_request)

func _on_offer_accept_pressed() -> void:
	offer_popup.hide()
	set_player_choice.rpc_id(1, true)
	
@onready var trade_offer_list: HBoxContainer = %TradeOfferList
@onready var trade_request_list: HBoxContainer = %TradeRequestList

func open_trade_ui(offer: Dictionary[Resources.Type, int] = {}, request: Dictionary[Resources.Type, int] = {}):
	trade_offer = offer
	trade_request = request
	for resource in Resources.Type.values():
		var offer_resource: TradeResourceUI = TRADE_RESOURCE.instantiate()
		var request_resource: TradeResourceUI = TRADE_RESOURCE.instantiate()
		
		offer_resource.set_icon(Resources.resource_texture[resource])
		if offer.has(resource):
			offer_resource.set_value(offer[resource])
		else:
			offer[resource] = 0
		trade_offer[resource] = offer[resource]
		
		request_resource.set_icon(Resources.resource_texture[resource])
		if request.has(resource):
			request_resource.set_value(request[resource])
		else:
			request[resource] = 0
		trade_request[resource] = request[resource]
		
		offer_resource.on_resource_amount_changed.connect(on_offer_changed.bind(resource))
		request_resource.on_resource_amount_changed.connect(on_request_changed.bind(resource))
		
		trade_offer_list.add_child(offer_resource)
		trade_request_list.add_child(request_resource)
	trade_container.show()

func on_offer_changed(change: int, resource: Resources.Type):
	trade_offer[resource] += change

	# Make checks to update UI such as Bank
	pass

func on_request_changed(change: int, resource: Resources.Type):
	trade_request[resource] += change
	
	# Make checks to update UI such as Bank
	pass

func is_offer_bank_acceptable(offer: Dictionary) -> bool:
	return true


func _on_cancel_trade_button_pressed() -> void:
	trade_offer = {}
	trade_request = {}
	trade_container.hide()
	
	# Maybe in the future make it so this does not delete-redraw every time TradeUI is opened...
	for child in trade_offer_list: child.queue_free()
	for child in trade_request_list: child.queue_free()

func _on_propose_trade_button_pressed() -> void:
	send_trade_request.rpc_id(1, trade_offer, trade_request)
