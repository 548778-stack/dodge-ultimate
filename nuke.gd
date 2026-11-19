extends Node3D

@export var nuke_scene: PackedScene

@onready var player = $Player

func _ready() -> void:
	player.lost.connect(_on_player_lost)

func _on_player_lost() -> void:
	var nuke := nuke_scene.instantiate()
	add_child(nuke)
	nuke.global_position = player.global_position
	
