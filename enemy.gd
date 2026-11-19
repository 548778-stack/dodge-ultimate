extends CharacterBody3D

@export var min_throw_force: float = 10.0
@export var max_throw_force: float = 35.0
@export_range(0.0, 1.0) var throw_strength: float = 0.7
@export var throw_interval: float = 2.0

@export var player_path: NodePath
@export var divider_x: float = 0.0
@export var speed: float = 4.0
@export var gravity: float = ProjectSettings.get_setting(
    "physics/3d/default_gravity"
)

@onready var navigation_agent: NavigationAgent3D = get_node_or_null("NavigationAgent3D")
@onready var hold_position: Marker3D = get_node_or_null("HoldPosition")
@onready var pickup_area: Area3D = get_node_or_null("PickUpArea")
@onready var detection_area: Area3D = get_node_or_null("BallDetectionArea")
@onready var player: Node3D = get_node_or_null(player_path) as Node3D

var carried_ball: RigidBody3D
var detected_balls: Array[RigidBody3D] = []
var throw_timer: float = 0.0


func _ready() -> void:
	if is_instance_valid(detection_area):
		detection_area.body_entered.connect(_on_detection_body_entered)
		detection_area.body_exited.connect(_on_detection_body_exited)
	else:
		push_error("Enemy: BallDetectionArea node is missing.")

	if is_instance_valid(pickup_area):
		pickup_area.body_entered.connect(_on_pickup_body_entered)
	else:
		push_error("Enemy: PickUpArea node is missing.")

	if not is_instance_valid(navigation_agent):
		push_error("Enemy: NavigationAgent3D node is missing.")

	if not is_instance_valid(hold_position):
		push_error("Enemy: HoldPosition node is missing.")

	if not is_instance_valid(player):
		push_warning("Enemy: Set player_path to the Player node in the Inspector.")


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	if is_instance_valid(carried_ball):
		if is_instance_valid(hold_position):
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
		var ball := detected_balls[i]
		if not is_instance_valid(ball) or not ball.is_inside_tree() or ball.global_position.x >= divider_x:
			detected_balls.remove_at(i)

	var target := _get_nearest_ball()

	if target == null or not is_instance_valid(navigation_agent):
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	navigation_agent.target_position = target.global_position

	if not navigation_agent.is_navigation_finished():
		var direction := navigation_agent.get_next_path_position() - global_position
		direction.y = 0.0
		direction = direction.normalized()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	move_and_slide()


func _get_nearest_ball() -> RigidBody3D:
	var closest: RigidBody3D = null
	var closest_distance := INF

	for ball in detected_balls:
		if not is_instance_valid(ball) or not ball.is_inside_tree():
			continue

		var distance := global_position.distance_squared_to(ball.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest = ball

	return closest


func _on_detection_body_entered(body: Node3D) -> void:
	if body is RigidBody3D:
		var ball := body as RigidBody3D
		if ball.global_position.x < divider_x and not detected_balls.has(ball):
			detected_balls.append(ball)


func _on_detection_body_exited(body: Node3D) -> void:
	if body is RigidBody3D:
		detected_balls.erase(body)


func _on_pickup_body_entered(body: Node3D) -> void:
	if is_instance_valid(carried_ball):
		return
	if not body is RigidBody3D or not is_instance_valid(hold_position):
		return

	var ball := body as RigidBody3D

	if ball.global_position.x >= divider_x:
		return

	carried_ball = ball
	carried_ball.freeze = true
	carried_ball.linear_velocity = Vector3.ZERO
	carried_ball.angular_velocity = Vector3.ZERO
	carried_ball.reparent(hold_position, true)
	carried_ball.global_position = hold_position.global_position
	detected_balls.erase(carried_ball)


func can_detect_player() -> bool:
	return is_instance_valid(player) and player.global_position.x >= divider_x


func throw_ball_at_player() -> void:
	if not is_instance_valid(carried_ball) or not is_instance_valid(player):
		return
	if not is_instance_valid(hold_position):
		return

	throw_timer = 0.0

	var ball_to_throw := carried_ball
	carried_ball = null
	detected_balls.erase(ball_to_throw)

	var level := get_tree().current_scene
	if level == null:
		return

	ball_to_throw.reparent(level, true)
	ball_to_throw.global_position = hold_position.global_position
	ball_to_throw.freeze = false

	var throw_direction := player.global_position - ball_to_throw.global_position
	throw_direction.y += 1.0
	throw_direction = throw_direction.normalized()

	var final_force: float = lerpf(min_throw_force, max_throw_force, throw_strength)
	ball_to_throw.linear_velocity = throw_direction * final_force
