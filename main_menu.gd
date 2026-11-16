extends Control

const GAME_SCENE := "res://level_1.tscn"

@onready var ip_input: LineEdit = $CenterContainer/VBoxContainer/IPInput
@onready var status_label: Label = $CenterContainer/VBoxContainer/StatusLabel
@onready var ip_label: Label = $CenterContainer/VBoxContainer/IPLabel

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	ip_label.text = "Your Local IP: " + _get_local_ip()
	$CenterContainer/VBoxContainer/HostButton.pressed.connect(_host)
	$CenterContainer/VBoxContainer/JoinButton.pressed.connect(_join)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func _host() -> void:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(7000, 8)
	if err != OK:
		status_label.text = "Host failed: " + str(err)
		return

	multiplayer.multiplayer_peer = peer
	status_label.text = "Waiting for guest..."

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
		if address.begins_with("10.220.1."):
			return address
	return "10.220.1.x address not found"

func _on_connected() -> void:
	print("Guest: connected_to_server fired")
	_go_to_game()

func _go_to_game() -> void:
	print("Loading scene: ", GAME_SCENE)
	var error := get_tree().change_scene_to_file(GAME_SCENE)
	if error != OK:
		status_label.text = "Scene load error: %s" % error
		push_error("Could not load %s (error %d)" % [GAME_SCENE, error])

func _on_connection_failed() -> void:
	status_label.text = "Connection failed. Check the IP and try again."

func _on_server_disconnected() -> void:
	status_label.text = "Host disconnected."

func hide_menu() -> void:
	hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
