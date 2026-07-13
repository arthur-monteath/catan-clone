class_name ServerBus extends Node


var clients: Array

func sync_clients():
	#TODO Check if is server, if not, give error
	for client in clients:
		sync_client(client)


func sync_client(client):
	update_resources_for(client)


func update_resources_for(client):
	var client_resources
	Client.rpc_id(client, "update_resources", client_resources)
