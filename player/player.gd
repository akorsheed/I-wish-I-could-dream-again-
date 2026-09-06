extends CharacterBody3D

@export var speed: float = 4.0
@export var acceleration: float = 18.0
@export var turn_speed: float = 12.0
@export var gravity: float = 9.8

@onready var visuals: Node3D = $Visuals
@onready var anim_player: AnimationPlayer = $Visuals.find_child("AnimationPlayer", true, false)

const PAINTERLY_SHADER = preload("res://shaders/character_painterly.gdshader")
const GRAVES_SCENE = preload("res://player/graves_character.tscn")

var can_move: bool = true

func _ready() -> void:
	if not visuals.has_node("graves_character"):
		var model = GRAVES_SCENE.instantiate()
		visuals.add_child(model)
	_setup_character_materials()
	var anim = get_animation_player()
	if anim:
		if not anim.has_animation("idle") or not anim.has_animation("run"):
			var anim_lib = load("res://player/animations/graves_animations.tres")
			if anim_lib:
				if anim.has_animation_library(""):
					anim.remove_animation_library("")
				anim.add_animation_library("", anim_lib)
		if anim.has_animation("idle"):
			anim.play("idle")

func get_animation_player() -> AnimationPlayer:
	if anim_player and is_instance_valid(anim_player):
		return anim_player
	if visuals:
		anim_player = visuals.find_child("AnimationPlayer", true, false)
	if not anim_player:
		anim_player = find_child("AnimationPlayer", true, false)
	return anim_player

func _setup_character_materials() -> void:
	for node in find_children("*", "MeshInstance3D"):
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		if not mesh_instance or not mesh_instance.mesh:
			continue
		for surface_idx in range(mesh_instance.mesh.get_surface_count()):
			# Preserve any surface override already assigned in the scene (e.g. hair material)
			if mesh_instance.get_surface_override_material(surface_idx) != null:
				continue
			var original_mat = mesh_instance.mesh.surface_get_material(surface_idx)
			var albedo_tex: Texture2D = null
			if original_mat is StandardMaterial3D:
				albedo_tex = original_mat.albedo_texture
			elif original_mat is BaseMaterial3D:
				albedo_tex = original_mat.albedo_texture

			var painterly_mat = ShaderMaterial.new()
			painterly_mat.shader = PAINTERLY_SHADER
			painterly_mat.set_shader_parameter("albedo_color", Color.WHITE)
			if albedo_tex:
				painterly_mat.set_shader_parameter("albedo_texture", albedo_tex)
				painterly_mat.set_shader_parameter("use_albedo_texture", true)
			else:
				painterly_mat.set_shader_parameter("use_albedo_texture", false)
			painterly_mat.set_shader_parameter("shadow_color", Color(0.2, 0.22, 0.28, 1.0))
			painterly_mat.set_shader_parameter("highlight_color", Color(1.0, 0.96, 0.88, 1.0))
			painterly_mat.set_shader_parameter("light_steps", 3)
			painterly_mat.set_shader_parameter("shadow_threshold", 0.38)
			painterly_mat.set_shader_parameter("shadow_boundary_width", 0.12)
			painterly_mat.set_shader_parameter("noise_scale", 280.0)
			painterly_mat.set_shader_parameter("noise_strength", 0.22)
			painterly_mat.set_shader_parameter("canvas_grain", 0.04)

			mesh_instance.set_surface_override_material(surface_idx, painterly_mat)

func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	if not can_move:
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)
		var anim = get_animation_player()
		if anim and anim.current_animation != "idle":
			anim.play("idle", 0.2)
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

	# When moving (velocity.length() > 0.1), smoothly interpolate Y-rotation to face movement direction
	var horiz_vel = Vector3(velocity.x, 0.0, velocity.z)
	if horiz_vel.length() > 0.1 and visuals:
		var target_yaw = atan2(horiz_vel.x, horiz_vel.z)
		visuals.rotation.y = lerp_angle(visuals.rotation.y, target_yaw, turn_speed * delta)
	elif move_dir.length_squared() > 0.01 and visuals:
		var target_yaw = atan2(move_dir.x, move_dir.z)
		visuals.rotation.y = lerp_angle(visuals.rotation.y, target_yaw, turn_speed * delta)

	# Animation playback control
	var anim = get_animation_player()
	if anim:
		if horiz_vel.length() > 0.1:
			if anim.current_animation != "run":
				anim.play("run", 0.2)
		else:
			if anim.current_animation != "idle":
				anim.play("idle", 0.2)
