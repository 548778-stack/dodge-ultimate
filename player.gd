extends CharacterBody3D

@export var speed: float = 8.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.003

# Get the gravity from the project settings to be synced with RigidBody nodes
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var camera = $Camera3D
@onready var interaction_ray = $Camera3D/RayCast3D
@onready var hold_position = $Camera3D/HoldPosition

var held_ball: RigidBody3D = null

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))

	# INTERACT (E)
	if event.is_action_pressed("interact"):
		if held_ball == null:
			try_pickup_ball()

	# THROW (Left Click)
	if event.is_action_pressed("throw_ball"):
		if held_ball != null:
			throw_ball()

	# Uncapture mouse (Escape)
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
	# Add gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Get movement input based on new Input Map
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()

func try_pickup_ball() -> void:
	interaction_ray.force_raycast_update()
	
	if interaction_ray.is_colliding():
		var object_seen = interaction_ray.get_collider()
		
		if object_seen is RigidBody3D:
			held_ball = object_seen
			
			held_ball.freeze = true
			held_ball.linear_velocity = Vector3.ZERO
			held_ball.angular_velocity = Vector3.ZERO
			
			# Turn off collision so it doesn't push the player
			var ball_shape = held_ball.get_node("CollisionShape3D")
			if ball_shape:
				ball_shape.disabled = true
			
			if held_ball.get_parent():
				held_ball.get_parent().remove_child(held_ball)
			hold_position.add_child(held_ball)
			
			held_ball.position = Vector3.ZERO
			held_ball.rotation = Vector3.ZERO
			print("Successfully picked up the ball!")

func throw_ball() -> void:
	if held_ball == null:
		return
		
	var ball_to_throw = held_ball
	held_ball = null
	
	hold_position.remove_child(ball_to_throw)
	get_parent().add_child(ball_to_throw)
	
	ball_to_throw.global_position = hold_position.global_position
	
	# Turn collision back on
	var ball_shape = ball_to_throw.get_node("CollisionShape3D")
	if ball_shape:
		ball_shape.disabled = false
		
	ball_to_throw.freeze = false
	var throw_direction = -camera.global_transform.basis.z.normalized()
	ball_to_throw.linear_velocity = throw_direction * 25.0
