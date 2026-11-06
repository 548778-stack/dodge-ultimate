extends Node3D

@export var ball_scene: PackedScene = preload("res://ball.tscn")
@onready var ball_starting_positions = $BallStartingPositions

func _ready() -> void:
	spawn_center_balls()

func spawn_center_balls() -> void:
	for marker in ball_starting_positions.get_children():
		# Check if it's any kind of 3D node (works for Marker3D)
		if marker is Node3D:
			var new_ball = ball_scene.instantiate()
			# 1. Add to the scene FIRST
			add_child(new_ball)
			# 2. THEN set the global position
			new_ball.global_position = marker.global_position
