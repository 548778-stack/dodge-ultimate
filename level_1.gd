extends Node3D

@export var ball_scene: PackedScene = preload("res://ball.tscn")

@onready var ball_starting_positions: Node = $BallStartingPositions


func _ready() -> void:
	_spawn_center_balls()


func _spawn_center_balls() -> void:
	for marker in ball_starting_positions.get_children():
		if marker is Node3D:
			var new_ball: Node3D = ball_scene.instantiate()
			add_child(new_ball)
			new_ball.global_position = marker.global_position
