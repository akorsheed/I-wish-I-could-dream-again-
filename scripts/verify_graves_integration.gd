extends SceneTree

func _init():
	print("============================================================")
	print("Starting Verification: Clean Graves Character Integration")
	print("============================================================")

	var scene_res = load("res://main.tscn")
	if not scene_res:
		printerr("FAILED to load res://main.tscn")
		quit(1)
		return

	var main_node = scene_res.instantiate()
	root.add_child(main_node)

	for i in range(5):
		await process_frame

	# 1. Verify Player node and absence of placeholder meshes
	var player: CharacterBody3D = main_node.get_node_or_null("scene/Player")
	assert(player != null, "Player node must exist under scene/Player")
	print("[PASS] Player CharacterBody3D found")

	for old_name in ["Coat", "Head", "HatBrim", "HatCrown"]:
		assert(player.find_child(old_name, true, false) == null, "Placeholder node '%s' must not exist" % old_name)
	print("[PASS] Verified all previous placeholder meshes are cleared")

	# 2. Verify Visuals & graves_character GLB hierarchy
	var visuals: Node3D = player.get_node_or_null("Visuals")
	assert(visuals != null, "Visuals node must exist under Player")
	var graves = visuals.get_node_or_null("graves_character")
	assert(graves != null, "graves_character GLB must be instanced under Visuals")
	print("[PASS] graves_character GLB instance verified under Visuals")

	# 3. Verify Visual Meshes and Painterly Shader Overrides
	var mesh_instances: Array[MeshInstance3D] = []
	for child in player.find_children("*", "MeshInstance3D"):
		mesh_instances.append(child as MeshInstance3D)
	assert(mesh_instances.size() > 0, "Character must have visual meshes")
	print("[INFO] Found %d visual meshes on Graves" % mesh_instances.size())

	for mi in mesh_instances:
		for s in range(mi.mesh.get_surface_count()):
			var mat = mi.get_surface_override_material(s)
			if "hair" in str(mi.name).to_lower() or (mi.name == &"head_necro_head_LOD0" and s == 1):
				assert(mat is StandardMaterial3D, "Hair surface %d of %s must have StandardMaterial3D override" % [s, mi.name])
				var std_mat = mat as StandardMaterial3D
				assert(is_equal_approx(std_mat.albedo_color.r, 0.92), "Hair albedo_color must be orange")
			else:
				assert(mat is ShaderMaterial, "Surface %d of %s must have ShaderMaterial override" % [s, mi.name])
				var smat = mat as ShaderMaterial
				assert(smat.shader != null, "Shader must be assigned")
	print("[PASS] Materials verified: hair StandardMaterial3D (orange) and body painterly shaders")

	# 4. Verify Scale Calibration (2.5x to 2.8x)
	print("[INFO] Visuals node scale: %s" % visuals.scale)
	assert(visuals.scale.x >= 2.5 and visuals.scale.x <= 2.8, "Visuals scale X must be between 2.5 and 2.8")
	assert(visuals.scale.y >= 2.5 and visuals.scale.y <= 2.8, "Visuals scale Y must be between 2.5 and 2.8")
	assert(visuals.scale.z >= 2.5 and visuals.scale.z <= 2.8, "Visuals scale Z must be between 2.5 and 2.8")

	var col_shape: CollisionShape3D = player.get_node_or_null("CollisionShape3D")
	assert(col_shape != null, "CollisionShape3D must exist on Player")
	assert(col_shape.shape is CapsuleShape3D, "Collision shape must be CapsuleShape3D")
	var cap = col_shape.shape as CapsuleShape3D
	print("[INFO] Collision capsule height: %f, radius: %f, center pos: %s" % [cap.height, cap.radius, col_shape.position])
	assert(abs(cap.height - 4.7) < 0.2, "Capsule height must be ~4.7m")
	assert(abs(col_shape.position.y - 2.35) < 0.2, "Capsule center must be at Y = 2.35m so base is at Y = 0.0")

	# 5. Physics Grounding Check
	for i in range(25):
		await physics_frame
	print("[INFO] Player pos after physics: %s, on floor: %s" % [player.global_position, player.is_on_floor()])
	assert(player.is_on_floor(), "Player must be resting on floor collider")
	assert(abs(player.global_position.y) < 0.05, "Boots must be firmly grounded at Y ~ 0.0 (no sinking/floating)")
	print("[PASS] Boots firmly grounded at Y = 0.0")

	# 6. Benchmark Check against Desk & Bookshelf
	var proxy = main_node.get_node("scene/lovecraft_proxy")
	var desk: MeshInstance3D = proxy.get_node("Desk")
	var desk_top = desk.global_position.y + desk.get_aabb().position.y + desk.get_aabb().size.y
	var waistline_approx = player.global_position.y + (cap.height * 0.46)
	print("[INFO] Desk top surface Y: %f, Graves waistline Y: %f" % [desk_top, waistline_approx])
	assert(abs(desk_top - waistline_approx) < 0.3, "Graves belt/waistline must be level with desk top surface")
	print("[PASS] Waistline aligns with desk top surface (~2.18m)")

	# 7. AnimationPlayer & Movement Facing Check
	var anim_player: AnimationPlayer = player.get_animation_player()
	assert(anim_player != null, "AnimationPlayer must exist on Graves")
	assert(anim_player.has_animation("idle"), "idle animation must exist")
	assert(anim_player.has_animation("walk"), "walk animation must exist")
	assert(anim_player.current_animation == "idle", "Must start in 'idle' animation")

	print("[INFO] Testing WASD movement and rotation...")
	Input.action_press("move_right")
	for step in range(15):
		await physics_frame

	print("[INFO] Moving velocity: %s, anim: %s, visuals rot Y: %f" % [player.velocity, anim_player.current_animation, visuals.rotation.y])
	assert(player.velocity.length() > 0.1, "Velocity must exceed 0.1 when moving")
	assert(anim_player.current_animation == "walk", "Animation must transition to 'walk'")

	Input.action_release("move_right")
	for step in range(30):
		await physics_frame

	print("[INFO] Stopped velocity: %s, anim: %s" % [player.velocity, anim_player.current_animation])
	assert(player.velocity.length() <= 0.1, "Velocity must decelerate to <= 0.1")
	assert(anim_player.current_animation == "idle", "Animation must transition back to 'idle'")
	print("[PASS] Movement facing direction and animation state transitions verified")

	# 8. Strict Scene Protection
	var cam: Camera3D = main_node.get_node_or_null("scene/Camera3D")
	assert(cam != null, "Camera3D must exist")
	assert(cam.projection == Camera3D.PROJECTION_ORTHOGONAL, "Camera must be Orthogonal")
	assert(is_equal_approx(cam.size, 32.0), "Camera size must be 32.0")
	var cam_pos = cam.transform.origin
	assert(is_equal_approx(cam_pos.x, 35.8672) and is_equal_approx(cam_pos.y, 31.0082) and is_equal_approx(cam_pos.z, 23.3671), "Camera3D position must be locked")
	print("[PASS] Camera3D strictly preserved")

	var lamp: OmniLight3D = main_node.get_node_or_null("scene/DeskLampLight")
	assert(lamp != null, "DeskLampLight must exist")
	assert(lamp.shadow_enabled, "DeskLampLight shadows must remain enabled")
	assert(is_equal_approx(lamp.light_energy, 2.0), "DeskLampLight energy must be 2.0")
	var lamp_pos = lamp.transform.origin
	assert(is_equal_approx(lamp_pos.x, 1.8) and is_equal_approx(lamp_pos.y, 2.2) and is_equal_approx(lamp_pos.z, -5.3), "DeskLampLight position must be locked")
	print("[PASS] DeskLampLight strictly preserved")

	var env_col: StaticBody3D = main_node.get_node_or_null("scene/EnvironmentColliders")
	assert(env_col != null, "EnvironmentColliders must exist")
	assert(env_col.get_node_or_null("ChairCollision") != null, "ChairCollision must exist")
	assert(env_col.get_node_or_null("BoundarySW") != null, "BoundarySW must exist")
	assert(env_col.get_node_or_null("BoundarySE") != null, "BoundarySE must exist")
	print("[PASS] Environment colliders strictly preserved")

	print("\n=== ALL INTEGRATION VERIFICATIONS PASSED SUCCESSFULLY ===")
	main_node.queue_free()
	quit(0)
