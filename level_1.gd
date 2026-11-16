extends Node3D

const PLAYER_SCENE: PackedScene = preload("res://player.tscn")

@export var ball_scene: PackedScene = preload("res://ball.tscn")

@onready var ball_starting_positions: Node = $BallStartingPositions
@onready var players: Node3D = $Players
@onready var player_spawn_points: Node = $PlayerSpawnPoints
@onready var spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var main_menu: Control = $CanvasLayer/MainMenu

func _ready() -> void:
	spawner.spawn_function = _spawn_player

	# Connect before accepting guests. Only the server creates player nodes.
	if multiplayer.is_server():
		multiplayer.peer_connected.connect(_on_peer_connected)
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	_spawn_center_balls()

	# A standalone run has no network peer; spawn a local player for testing.
	if multiplayer.multiplayer_peer == null:
		_spawn_for_peer(1)
	elif multiplayer.is_server():
		_spawn_for_peer(1)

func _spawn_center_balls() -> void:
	for marker in ball_starting_positions.get_children():
		if marker is Node3D:
			var new_ball = ball_scene.instantiate()
			add_child(new_ball)
			new_ball.global_position = marker.global_position

func _on_peer_connected(peer_id: int) -> void:
	_spawn_for_peer(peer_id)

func _spawn_for_peer(peer_id: int) -> void:
	if player_spawn_points.get_child_count() == 0:
		push_error("PlayerSpawnPoints needs at least one Marker3D.")
		return

	var index := (peer_id - 1) % player_spawn_points.get_child_count()
	spawner.spawn({
		"peer_id": peer_id,
		"spawn_index": index
	})

func _spawn_player(data: Variant) -> Node:
	var player := PLAYER_SCENE.instantiate()
	player.name = str(data["peer_id"])
	player.set_multiplayer_authority(int(data["peer_id"]))

	var marker := player_spawn_points.get_child(int(data["spawn_index"])) as Node3D
	player.global_position = marker.global_position
	return player

func _on_peer_disconnected(peer_id: int) -> void:
	var player := players.get_node_or_null(str(peer_id))
	if player:
		player.queue_free()
