extends Node3D

# Preload your Ball scene configuration from your file directory
@export var ball_scene: PackedScene = preload("res://ball.tscn")

# Link directly to the container holding your spatial markers
@onready var ball_starting_positions = $BallStartingPositions

func _ready() -> void:
	spawn_center_balls()

func spawn_center_balls() -> void:
	for marker in ball_starting_positions.get_children():
		if marker is Node3D:
			var new_ball = ball_scene.instantiate()
			add_child(new_ball)
			
			# Add +0.5 (or whatever the radius of your ball is) to the Y axis
			new_ball.global_position = marker.global_position + Vector3(0, 1.0, 0)
