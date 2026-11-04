extends Node3D

# Preload your Ball scene configuration from your file directory
@export var ball_scene: PackedScene = preload("res://Ball.tscn")

# Link directly to the container holding your spatial markers
@onready var ball_starting_positions = $BallStartingPositions

func _ready() -> void:
	# Run the custom spawning loop immediately when the map loads
	spawn_center_balls()

func spawn_center_balls() -> void:
	# Iterate through every individual child node inside BallStartingPositions
	for marker in ball_starting_positions.get_children():
		# Confirm the found node is a Marker3D before spawning
		if marker is Marker3D:
			var new_ball = ball_scene.instantiate()
			add_child(new_ball)
			
			# Align the newly spawned ball's spatial position with the marker
			new_ball.global_position = marker.global_position
