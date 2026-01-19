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

@onready var offer_popup_offer_list: HBoxContainer = %OfferPopupOfferList
@onready var offer_popup_request_list: HBoxContainer = %OfferPopupRequestList
@onready var offer_popup: PanelContainer = %TradeOffer
@rpc("authority", "reliable", "call_local")
func offer_trade(offer: Dictionary, request: Dictionary, trade_owner: int):
	if multiplayer.get_unique_id() == trade_owner: return
	for child in offer_popup_offer_list.get_children(): child.queue_free()
	for child in offer_popup_request_list.get_children(): child.queue_free()
	
	trade_owner_id = trade_owner
	trade_offer = offer
	trade_request = request
	
	var offer_resource_uis := generate_resource_ui(offer)
	for resource_ui in offer_resource_uis:
		offer_popup_offer_list.add_child(resource_ui)
		
	var request_resource_uis := generate_resource_ui(request)
	for resource_ui in request_resource_uis:
		offer_popup_request_list.add_child(resource_ui)
	
	get_node("%OfferLabel").text = "Trade Offer from " + main.get_player_by_id(trade_owner).name
	offer_popup.show()

@export var player_choice_texture: Array[Texture2D]
@rpc("any_peer", "reliable", "call_local")
func set_player_choice(choice: bool):
	var is_trade_owner = multiplayer.get_unique_id() != trade_owner_id
	if !multiplayer.is_server() and is_trade_owner: return
	var choicemaker_id = multiplayer.get_remote_sender_id()
	for player in player_list.get_children():
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
		if !offer.has(resource): offer[resource] = 0
		if !request.has(resource): request[resource] = 0
	
	var offer_resource_uis := generate_resource_ui(offer)
	for resource_ui in offer_resource_uis:
		var type := resource_ui.resource_type
		resource_ui.on_resource_amount_changed.connect(func(amt):
			on_offer_changed(amt, type)
			resource_ui.update_resource_affordances(ClientResources.get_local_resources())
		)
		trade_offer_list.add_child(resource_ui)
		
	var request_resource_uis := generate_resource_ui(request)
	for resource_ui in request_resource_uis:
		var type := resource_ui.resource_type
		resource_ui.on_resource_amount_changed.connect(on_request_changed.bind(type))
		trade_request_list.add_child(resource_ui)
	trade_container.show()

func generate_resource_ui(resources: Dictionary[Resources.Type, int]) -> Array[TradeResourceUI]:
	var trade_resources: Array[TradeResourceUI]
	for resource: Resources.Type in resources.keys():
		var trade_resource: TradeResourceUI = TRADE_RESOURCE.instantiate()
		trade_resource.set_icon(Resources.resource_texture[resource])
		trade_resource.set_value(resources[resource])
		trade_resource.set_type(resource)
		trade_resources.append(trade_resource)
	return trade_resources

func on_offer_changed(change: int, resource: Resources.Type):
	
	if trade_offer.has(resource): trade_offer[resource] += change
	else: trade_offer[resource] = change
	update_trade_container_ui()
	pass

func on_request_changed(change: int, resource: Resources.Type):
	if trade_request.has(resource): trade_request[resource] += change
	else: trade_request[resource] = change
	update_trade_container_ui()
	pass

func update_trade_container_ui():
	update_bank_button()

func is_offer_bank_acceptable(offer: Dictionary[Resources.Type, int], request: Dictionary[Resources.Type, int]) -> bool:
	var offer_sum := 0.0
	for v in offer.values():
		offer_sum += v

	var request_sum := 0.0
	for v in request.values():
		request_sum += v
	
	if request_sum == 0: # You can give away your resources
		return true
	
	return (offer_sum / request_sum) >= 4
	
@onready var bank_button: Button = %BankButton
func update_bank_button():
	var image: TextureRect = bank_button.get_node("HBoxContainer/Choice")
	image.texture = player_choice_texture[int(is_offer_bank_acceptable(trade_offer, trade_request))]

func _on_cancel_trade_button_pressed() -> void:
	trade_offer = {}
	trade_request = {}
	trade_container.hide()
	
	# TODO - Maybe in the future make it so this does not delete-redraw every time TradeUI is opened...
	for child in trade_offer_list.get_children(): child.queue_free()
	for child in trade_request_list.get_children(): child.queue_free()

func _on_propose_trade_button_pressed() -> void:
	propose_trade(trade_offer, trade_request)
