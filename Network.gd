extends Node

const PORT := 7000
const MAX_CLIENTS := 8

func host_game() -> void:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(PORT, MAX_CLIENTS)
	if error != OK:
		print("Could not host: ", error)
		return

	multiplayer.multiplayer_peer = peer
	print("Hosting on port ", PORT)

func join_game(ip_address: String) -> void:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(ip_address, PORT)
	if error != OK:
		print("Could not join: ", error)
		return

	multiplayer.multiplayer_peer = peer
	print("Connecting to ", ip_address)
