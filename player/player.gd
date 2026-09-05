extends CharacterBody3D

@export var speed: float = 4.5
@export var acceleration: float = 18.0
@export var turn_speed: float = 12.0
@export var gravity: float = 9.8

@onready var visuals: Node3D = $Visuals

var can_move: bool = true

func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	if not can_move:
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)
		move_and_slide()
		return

	# Determine input direction
	var input_x: float = 0.0
	var input_y: float = 0.0

	# Check custom or standard actions and physical keys
	if Input.is_action_pressed("move_left") or Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		input_x -= 1.0
	if Input.is_action_pressed("move_right") or Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		input_x += 1.0
	if Input.is_action_pressed("move_up") or Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		input_y -= 1.0
	if Input.is_action_pressed("move_down") or Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		input_y += 1.0

	var raw_input = Vector2(input_x, input_y).normalized()

	# Align movement with isometric camera projection (45-degree angle)
	var cam = get_viewport().get_camera_3d()
	var move_dir = Vector3.ZERO

	if cam:
		var cam_forward = -cam.global_transform.basis.z
		cam_forward.y = 0.0
		cam_forward = cam_forward.normalized()

		var cam_right = cam.global_transform.basis.x
		cam_right.y = 0.0
		cam_right = cam_right.normalized()

		move_dir = (cam_right * raw_input.x + cam_forward * -raw_input.y).normalized()
	else:
		# Fallback isometric vectors
		var iso_forward = Vector3(-1, 0, -1).normalized()
		var iso_right = Vector3(1, 0, -1).normalized()
		move_dir = (iso_right * raw_input.x + iso_forward * -raw_input.y).normalized()

	var target_vel_x = move_dir.x * speed
	var target_vel_z = move_dir.z * speed

	velocity.x = move_toward(velocity.x, target_vel_x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_vel_z, acceleration * delta)

	move_and_slide()

	# Smoothly rotate visuals towards movement direction
	if move_dir.length_squared() > 0.01 and visuals:
		var target_yaw = atan2(move_dir.x, move_dir.z)
		visuals.rotation.y = lerp_angle(visuals.rotation.y, target_yaw, turn_speed * delta)
