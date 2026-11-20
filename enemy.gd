extends CharacterBody3D

@export var player_path: NodePath
@export var divider_x: float = 0.0
@export var speed: float = 4.0
@export var gravity: float = ProjectSettings.get_setting(
    "physics/3d/default_gravity"
)

@export var min_throw_force: float = 10.0
@export var max_throw_force: float = 35.0
@export_range(0.0, 1.0) var throw_strength: float = 0.7
@export var throw_interval: float = 2.0
@export var aim_height_offset: float = 1.5
@export var dodge_speed: float = 6.0
@export var dodge_duration: float = 0.45
@export var dodge_cooldown: float = 1.2

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var hold_position: Marker3D = $HoldPosition
@onready var pickup_area: Area3D = $PickUpArea
@onready var detection_area: Area3D = $BallDetectionArea
@onready var player: Node3D = get_node_or_null(player_path) as Node3D

var carried_ball: RigidBody3D
var detected_balls: Array[RigidBody3D] = []
var throw_timer: float = 0.0
var dodge_timer: float = 0.0
var dodge_cooldown_timer: float = 0.0
var dodge_direction: Vector3 = Vector3.ZERO

func _ready() -> void:
	detection_area.body_entered.connect(_on_detection_body_entered)
	detection_area.body_exited.connect(_on_detection_body_exited)
	pickup_area.body_entered.connect(_on_pickup_body_entered)


func _physics_process(delta: float) -> void:
	dodge_cooldown_timer = maxf(0.0, dodge_cooldown_timer - delta)

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	# While dodging, move sideways and skip normal navigation.
	if dodge_timer > 0.0:
		dodge_timer = maxf(0.0, dodge_timer - delta)
		velocity.x = dodge_direction.x * dodge_speed
		velocity.z = dodge_direction.z * dodge_speed
		move_and_slide()
		return

	try_dodge()

	# try_dodge() may have started a dodge this frame.
	if dodge_timer > 0.0:
		velocity.x = dodge_direction.x * dodge_speed
		velocity.z = dodge_direction.z * dodge_speed
		move_and_slide()
		return

	if is_instance_valid(carried_ball):
		carried_ball.global_position = hold_position.global_position

		velocity.x = 0.0
		velocity.z = 0.0
		throw_timer += delta

		if can_detect_player() and throw_timer >= throw_interval:
			throw_ball_at_player()

		move_and_slide()
		return
	else:
		carried_ball = null

	for i in range(detected_balls.size() - 1, -1, -1):
		var ball: RigidBody3D = detected_balls[i]
		if not is_instance_valid(ball) or ball.global_position.x >= divider_x:
			detected_balls.remove_at(i)

	var target_ball: RigidBody3D = _get_nearest_ball()

	if target_ball == null:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	navigation_agent.target_position = target_ball.global_position

	if not navigation_agent.is_navigation_finished():
		var direction: Vector3 = (
			navigation_agent.get_next_path_position() - global_position
		)
		direction.y = 0.0
		direction = direction.normalized()

		velocity.x = direction.x * speed
		velocity.z = direction.z * speed

		if direction.length_squared() > 0.001:
			look_at(global_position + direction, Vector3.UP)
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	move_and_slide()


func _get_nearest_ball() -> RigidBody3D:
	var closest: RigidBody3D = null
	var closest_distance: float = INF

	for ball in detected_balls:
		if not is_instance_valid(ball):
			continue
		if ball.global_position.x >= divider_x:
			continue

		var distance: float = global_position.distance_squared_to(
			ball.global_position
		)
		if distance < closest_distance:
			closest_distance = distance
			closest = ball

	return closest


func _on_detection_body_entered(body: Node3D) -> void:
	if body is RigidBody3D:
		var ball: RigidBody3D = body as RigidBody3D
		if ball.global_position.x < divider_x and not detected_balls.has(ball):
			detected_balls.append(ball)


func _on_detection_body_exited(body: Node3D) -> void:
	if body is RigidBody3D:
		detected_balls.erase(body)


func _on_pickup_body_entered(body: Node3D) -> void:
	if is_instance_valid(carried_ball):
		return
	if not body is RigidBody3D:
		return

	var ball: RigidBody3D = body as RigidBody3D

	# Only pick up balls on the enemy's side.
	if ball.global_position.x >= divider_x:
		return

	carried_ball = ball
	carried_ball.freeze = true
	carried_ball.sleeping = false
	carried_ball.linear_velocity = Vector3.ZERO
	carried_ball.angular_velocity = Vector3.ZERO
	carried_ball.global_position = hold_position.global_position
	detected_balls.erase(carried_ball)
	throw_timer = 0.0


func can_detect_player() -> bool:
	return is_instance_valid(player) and player.global_position.x >= divider_x


func throw_ball_at_player() -> void:
	if not is_instance_valid(carried_ball) or not is_instance_valid(player):
		return

	var ball: RigidBody3D = carried_ball
	carried_ball = null
	detected_balls.erase(ball)
	throw_timer = 0.0

	var start: Vector3 = ball.global_position
	var target: Vector3 = player.global_position
	target.y += aim_height_offset

	var horizontal: Vector3 = Vector3(
		target.x - start.x,
		0.0,
		target.z - start.z
	)
	var distance: float = horizontal.length()

	if distance < 0.1:
		return

	var direction: Vector3 = horizontal.normalized()
	var launch_speed: float = lerpf(
		min_throw_force,
		max_throw_force,
		throw_strength
	)

	# Increase the upward component with distance to account for gravity.
	var gravity_strength: float = maxf(gravity, 0.01)
	var flight_time: float = maxf(distance / launch_speed, 0.2)
	var vertical_speed: float = (
		(target.y - start.y + 0.5 * gravity_strength * flight_time * flight_time)
		/ flight_time
	)

	ball.freeze = false
	ball.sleeping = false
	ball.linear_velocity = direction * launch_speed + Vector3.UP * vertical_speed

func try_dodge() -> void:
	if dodge_cooldown_timer > 0.0 or not is_instance_valid(player):
		return

	var to_player: Vector3 = player.global_position - global_position
	to_player.y = 0.0

	if to_player.length() > 8.0:
		return

	# Only dodge when the player is roughly in front of the enemy.
	var forward: Vector3 = -global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()

	if forward.dot(to_player.normalized()) < 0.3:
		return

	var sideways: Vector3 = Vector3(-to_player.z, 0.0, to_player.x).normalized()
	dodge_direction = sideways if randf() < 0.5 else -sideways

	dodge_timer = dodge_duration
	dodge_cooldown_timer = dodge_cooldown
