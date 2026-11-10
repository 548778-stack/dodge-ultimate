extends RigidBody3D

@export var wander_strength: float = 1.5    # How hard they push themselves to float around
@export var return_strength: float = 2.0    # How hard they pull back to their spawn point
@export var max_radius: float = 2.0         # How far away from the spawn point they can wander
@export var max_speed: float = 1.5          # Limits how fast they can float

var start_position: Vector3

func _ready() -> void:
	# Remember where the light was placed in the level
	start_position = global_position

func _physics_process(_delta: float) -> void:
	# 1. Wander gently in random directions
	var random_dir = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized()
	apply_central_force(random_dir * wander_strength)

	# 2. If they get knocked away or wander too far, pull them back to their start position
	var distance = global_position.distance_to(start_position)
	if distance > max_radius:
		var pull_dir = global_position.direction_to(start_position)
		# The further they are, the harder the pull
		apply_central_force(pull_dir * return_strength * (distance - max_radius))

	# 3. Cap their speed so they don't spin out of control
	if linear_velocity.length() > max_speed:
		linear_velocity = linear_velocity.normalized() * max_speed
