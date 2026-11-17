extends CharacterBody3D

@export var speed: float = 4.0
@export var gravity: float = ProjectSettings.get_setting(
    "physics/3d/default_gravity"
)

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var hold_position: Marker3D = $HoldPosition
@onready var pickup_area: Area3D = $PickUpArea

var carried_ball: RigidBody3D
var nearby_balls: Array[RigidBody3D] = []


func _ready() -> void:
	pickup_area.body_entered.connect(_on_pickup_area_body_entered)
	pickup_area.body_exited.connect(_on_pickup_area_body_exited)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	if is_instance_valid(carried_ball):
		carried_ball.global_position = hold_position.global_position
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return
	else:
		carried_ball = null

	# Remove balls that have been deleted.
	for i in range(nearby_balls.size() - 1, -1, -1):
		if not is_instance_valid(nearby_balls[i]):
			nearby_balls.remove_at(i)

	if nearby_balls.is_empty():
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	var target_ball: RigidBody3D = nearby_balls[0]
	navigation_agent.target_position = target_ball.global_position

	if not navigation_agent.is_navigation_finished():
		var next_position := navigation_agent.get_next_path_position()
		var direction := next_position - global_position
		direction.y = 0.0
		direction = direction.normalized()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	move_and_slide()


func _on_pickup_area_body_entered(body: Node3D) -> void:
	if body is RigidBody3D:
		var ball := body as RigidBody3D
		if not nearby_balls.has(ball):
			nearby_balls.append(ball)

		# Pick it up when it enters the area.
		carried_ball = ball
		ball.freeze = true
		ball.linear_velocity = Vector3.ZERO
		ball.angular_velocity = Vector3.ZERO
		ball.reparent(hold_position, true)
		ball.global_position = hold_position.global_position


func _on_pickup_area_body_exited(body: Node3D) -> void:
	if body is RigidBody3D:
		nearby_balls.erase(body)
