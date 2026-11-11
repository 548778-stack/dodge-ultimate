extends CharacterBody3D

@export var speed: float = 8.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.003
@export var push_force: float = 10.0

@export var min_throw_force: float = 10.0
@export var max_throw_force: float = 35.0
@export var max_charge_time: float = 1.0

var current_charge: float = 0.0
var is_charging: bool = false

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var camera = $Camera3D
@onready var interaction_ray = $Camera3D/RayCast3D
@onready var hold_position = $Camera3D/HoldPosition
@onready var anim_player: AnimationPlayer = $PlayerVisual/AnimationPlayer

@onready var charge_bar: ProgressBar = $CanvasLayer/ChargeBar 
@onready var crosshair: ColorRect = $CanvasLayer/CenterContainer/Crosshair

var color_default = Color(1, 1, 1, 0.5)
var color_hover = Color(0, 1, 1, 1)

var held_ball: RigidBody3D = null
var was_on_floor := is_on_floor()

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	charge_bar.hide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))

	if event.is_action_pressed("pick_or_throw"):
		if held_ball == null:
			try_pickup_ball()
		else:
			is_charging = true
			current_charge = 0.0
			charge_bar.show()
			
	if event.is_action_released("pick_or_throw"):
		if is_charging and held_ball != null:
			charge_throw()

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and was_on_floor:
		velocity.y = jump_velocity
		play_animation(&"Jump")
	
	if is_charging:
		current_charge += delta
		current_charge = min(current_charge, max_charge_time)
		var charge_percent = (current_charge / max_charge_time) * 100
		charge_bar.value = charge_percent

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()

	# Update Crosshair Color (Now ignores the floating lights!)
	if interaction_ray.is_colliding() and held_ball == null:
		var object_seen = interaction_ray.get_collider()
		if object_seen is RigidBody3D and not object_seen.is_in_group("floating_lights"):
			crosshair.color = color_hover
		else:
			crosshair.color = color_default
	else:
		crosshair.color = color_default

	# Push Logic (Player pushing balls)
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# Also added the group check here so you can push the floating lights around with your body!
		if collider is RigidBody3D and collider != held_ball:
			var push_direction = -collision.get_normal()
			collider.sleeping = false
			collider.apply_central_impulse(push_direction * push_force)
			
		if not is_on_floor():
			play_animation(&"Jump")
		elif Vector2(velocity.x, velocity.z).length() > 0.1:
			play_animation(&"Walk")
		else:
			play_animation(&"Idle")

func try_pickup_ball() -> void:
	interaction_ray.force_raycast_update()
	
	if interaction_ray.is_colliding():
		var object_seen = interaction_ray.get_collider()
		
		# ONLY pick it up if it's a RigidBody3D AND it's NOT a floating light
		if object_seen is RigidBody3D and not object_seen.is_in_group("floating_lights"):
			held_ball = object_seen
			
			held_ball.freeze = true
			held_ball.linear_velocity = Vector3.ZERO
			held_ball.angular_velocity = Vector3.ZERO
			
			var ball_shape = held_ball.get_node("CollisionShape3D")
			if ball_shape:
				ball_shape.disabled = true
			
			if held_ball.get_parent():
				held_ball.get_parent().remove_child(held_ball)
			hold_position.add_child(held_ball)
			
			held_ball.position = Vector3.ZERO
			held_ball.rotation = Vector3.ZERO

func charge_throw() -> void:
	if held_ball == null:
		return
		
	is_charging = false
	charge_bar.hide() 
	
	var charge_percent = current_charge / max_charge_time
	var final_force = lerp(min_throw_force, max_throw_force, charge_percent)
	
	var ball_to_throw = held_ball
	held_ball = null
	
	hold_position.remove_child(ball_to_throw)
	get_parent().add_child(ball_to_throw)
	
	ball_to_throw.global_position = hold_position.global_position
	
	var ball_shape = ball_to_throw.get_node("CollisionShape3D")
	if ball_shape:
		ball_shape.disabled = false
		
	ball_to_throw.freeze = false
	var throw_direction = -camera.global_transform.basis.z.normalized()
	
	ball_to_throw.linear_velocity = throw_direction * final_force
	
	current_charge = 0.0
	charge_bar.value = 0.0

func play_animation(anim_name: StringName) -> void:
	if anim_player.has_animation(anim_name) \
	and anim_player.current_animation != anim_name:
		anim_player.play(anim_name)
