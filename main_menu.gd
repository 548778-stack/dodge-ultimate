extends Control

@onready var ip_input: LineEdit = $CenterContainer/VBoxContainer/IPInput
@onready var status_label: Label = $CenterContainer/VBoxContainer/StatusLabel
@onready var ip_label: Label = $CenterContainer/VBoxContainer/IPLabel

func _ready() -> void:
	ip_label.text = "Your Local IP: " + _get_local_ip()
	$CenterContainer/VBoxContainer/HostButton.pressed.connect(_host)
	$CenterContainer/VBoxContainer/JoinButton.pressed.connect(_join)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func _host() -> void:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(7000, 8)
	if error != OK:
		status_label.text = "Couldn't host: %s" % error
		return

	multiplayer.multiplayer_peer = peer
	status_label.text = "Hosting—waiting for a player..."
	get_tree().change_scene_to_file("res://Game3D.tscn")

func _join() -> void:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(ip_input.text.strip_edges(), 7000)
	if error != OK:
		status_label.text = "Couldn't connect: %s" % error
		return

	multiplayer.multiplayer_peer = peer
	status_label.text = "Connecting..."

func _get_local_ip() -> String:
	for address in IP.get_local_addresses():
		if address.contains(".") and not address.begins_with("127."):
			return address
	return "Not found"

func _on_connected() -> void:
	get_tree().change_scene_to_file("res://Game3D.tscn")

func _on_connection_failed() -> void:
	status_label.text = "Connection failed. Check the IP and try again."

func _on_server_disconnected() -> void:
	status_label.text = "Host disconnected."
