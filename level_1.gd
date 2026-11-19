extends Node3D

@export var ball_scene: PackedScene = preload("res://Ball.tscn")

@onready var ball_starting_positions: Node = $BallStartingPositions
@onready var volume_slider: HSlider = get_node_or_null("MusicVolumeSlider")
@onready var music: AudioStreamPlayer = get_node_or_null("MusicPlayer")


func _ready() -> void:
	if music == null:
		push_error("MusicPlayer node not found.")
	elif music.stream == null:
		push_error("Assign the MP3 to MusicPlayer's Stream property.")
	else:
		music.volume_db = 0.0
		music.play()
		print("Playing: ", music.stream.resource_path)

	if volume_slider:
		volume_slider.min_value = -30.0
		volume_slider.max_value = 24.0
		volume_slider.step = 1.0
		volume_slider.value = 0.0
		volume_slider.value_changed.connect(_on_volume_changed)

	_spawn_center_balls()


func _on_volume_changed(value: float) -> void:
	if music:
		music.volume_db = value


func _spawn_center_balls() -> void:
	for marker in ball_starting_positions.get_children():
		if marker is Node3D:
			var new_ball: Node3D = ball_scene.instantiate()
			add_child(new_ball)
			new_ball.global_position = marker.global_position
