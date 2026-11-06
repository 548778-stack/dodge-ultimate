extends CharacterBody3D

@export var speed: float = 8.0
@export var mouse_sensitivity: float = 0.003

@onready var camera = $Camera3D
@onready var interaction_ray = $Camera3D/RayCast3D
@onready var hold_position = $Camera3D/HoldPosition

var held_ball: RigidBody3D = null

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))

	if event.is_action_pressed("ui_accept"):
		if held_ball == null:
			try_pickup_ball()
		else:
			throw_ball()

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(_delta: float) -> void:
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()

func try_pickup_ball() -> void:
	# Force the ray to update exactly at the moment we press the button
	interaction_ray.force_raycast_update()
	
	print("Ray colliding: ", interaction_ray.is_colliding(), " | Collider: ", interaction_ray.get_collider())
	
	if interaction_ray.is_colliding():
		var object_seen = interaction_ray.get_collider()
		
		if object_seen is RigidBody3D:
			held_ball = object_seen
			
			# Freeze physics before moving it
			held_ball.freeze = true
			held_ball.linear_velocity = Vector3.ZERO
			held_ball.angular_velocity = Vector3.ZERO
			
			# Reparent to the hand
			if held_ball.get_parent():
				held_ball.get_parent().remove_child(held_ball)
			hold_position.add_child(held_ball)
			
			# Snap to hand center
			held_ball.position = Vector3.ZERO
			held_ball.rotation = Vector3.ZERO
			print("Successfully picked up the ball!")

func throw_ball() -> void:
	if held_ball == null:
		return
		
	var ball_to_throw = held_ball
	held_ball = null
	
	# Reparent back to the level
	hold_position.remove_child(ball_to_throw)
	get_parent().add_child(ball_to_throw)
	
	# Match current hand position
	ball_to_throw.global_position = hold_position.global_position
	
	# Unfreeze so physics works again
	ball_to_throw.freeze = false
	
	# Throw it forward
	var throw_direction = -camera.global_transform.basis.z.normalized()
	ball_to_throw.linear_velocity = throw_direction * 25.0
