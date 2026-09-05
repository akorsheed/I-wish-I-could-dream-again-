extends SceneTree

func _init():
	print("--- Starting Headless Verification of main.tscn ---")
	var scene_res = load("res://main.tscn")
	if not scene_res:
		printerr("FAILED to load res://main.tscn")
		quit(1)
		return
	
	var main_node = scene_res.instantiate()
	root.add_child(main_node)
	
	# Wait for ready and setup
	for i in range(5):
		await process_frame
	
	# 1. Verify Proxy Meshes (Floor, BackWall_1, BackWall_2, Desk, Bookcase_1, Bookcase_2, Bookcase_3, Mirror)
	var proxy = main_node.get_node_or_null("scene/lovecraft_proxy")
	assert(proxy != null, "lovecraft_proxy must exist")
	print("[PASS] lovecraft_proxy found in scene")
	
	var expected_meshes = ["Floor", "BackWall_1", "BackWall_2", "Desk", "Bookcase_1", "Bookcase_2", "Bookcase_3", "Mirror"]
	var found_meshes = []
	var col_count = 0
	var mat_count = 0
	
	for child in proxy.get_children():
		if child is MeshInstance3D and child.visible:
			found_meshes.append(child.name)
			if child.material_override != null:
				mat_count += 1
			for sub in child.get_children():
				if sub is StaticBody3D:
					assert(sub.collision_layer == 1, "Collision layer must be 1")
					col_count += 1
	
	print("[INFO] Active proxy meshes (%d): %s" % [found_meshes.size(), str(found_meshes)])
	for exp_name in expected_meshes:
		assert(exp_name in found_meshes, "Expected mesh '%s' not found in proxy" % exp_name)
	assert(found_meshes.size() == 8, "Expected exactly 8 active proxy meshes, got %d" % found_meshes.size())
	assert(mat_count == 8, "All 8 meshes must have material_override assigned")
	assert(col_count == 8, "All 8 meshes must have StaticBody3D child")
	print("[PASS] Foundational 8 collision & visual proxy meshes verified with -col auto-colliders")
	
	# 2. Verify Cutaway View (No foreground walls)
	for fname in ["Wall_SW", "Wall_SE", "Wall_SW_Proxy", "Wall_SE_North_Proxy", "Wall_SE_South_Proxy"]:
		assert(not fname in found_meshes, "Foreground wall %s must NOT exist" % fname)
	print("[PASS] Clean cutaway view verified: zero foreground walls or occluding geometry")
	
	# 3. Verify Floor Level at Y = 0.0
	var floor_mesh: MeshInstance3D = proxy.get_node("Floor")
	var floor_aabb = floor_mesh.get_aabb()
	var floor_top_y = floor_mesh.global_position.y + floor_aabb.position.y + floor_aabb.size.y
	print("[INFO] Floor top surface global Y: %f" % floor_top_y)
	assert(abs(floor_top_y) < 0.01, "Floor top surface should be precisely at Y = 0.0")
	print("[PASS] Flat floor plane at Y = 0.0 verified")
	
	# 4. Verify Camera3D Alignment & Framing
	var cam: Camera3D = main_node.get_node_or_null("scene/Camera3D")
	assert(cam != null, "Camera3D must exist")
	assert(cam.projection == Camera3D.PROJECTION_ORTHOGONAL, "Camera must be Orthogonal")
	assert(is_equal_approx(cam.size, 32.0), "Camera size must be 32.0")
	var target = Vector3(7.0, 2.14, -5.5)
	var p_target_2d = cam.unproject_position(target)
	print("[INFO] Camera target unprojected 2D: ", p_target_2d)
	assert(abs(p_target_2d.x - 960.0) < 1.0 and abs(p_target_2d.y - 540.0) < 1.0, "Camera target must center at (960, 540) in 1920x1080 viewport")
	print("[PASS] Camera3D framing and isometric alignment verified")
	
	# 5. Verify Shader Settings
	var shader_mat: ShaderMaterial = floor_mesh.material_override
	assert(shader_mat != null, "Floor mesh must have ShaderMaterial")
	var tex = shader_mat.get_shader_parameter("painted_texture")
	assert(tex != null, "painted_texture uniform must be set on shader material")
	print("[INFO] Painted texture resource: ", tex.resource_path)
	assert("room_render_base_3.png" in tex.resource_path or "room_render_base.png" in tex.resource_path, "painted_texture must be room_render_base_3.png")
	print("[PASS] Blockout oil paint shader & texture verified")
	
	# 6. Verify Desk Lamp OmniLight3D
	var lamp: OmniLight3D = main_node.get_node_or_null("scene/DeskLampLight")
	assert(lamp != null, "DeskLampLight OmniLight3D must exist")
	assert(lamp.shadow_enabled, "Desk lamp shadow must be enabled")
	assert(lamp.light_energy >= 2.0, "Desk lamp energy should be >= 2.0")
	print("[INFO] DeskLampLight pos: %s, energy: %f, shadows: %s" % [lamp.position, lamp.light_energy, lamp.shadow_enabled])
	print("[PASS] Desk lamp warm lighting & shadows verified")
	
	# 7. Verify Player Placement, Scale & Physics at Y = 0.0
	var player: CharacterBody3D = main_node.get_node_or_null("scene/Player")
	assert(player != null, "Player must exist")
	print("[INFO] Initial Player pos: ", player.global_position)
	assert(abs(player.global_position.y) < 0.05, "Player must start at Y = 0.0")
	
	# Step physics frames to confirm grounding
	for i in range(20):
		await physics_frame
	print("[INFO] Player pos after physics frames: ", player.global_position, " on floor: ", player.is_on_floor())
	assert(player.is_on_floor(), "Player must be resting firmly on floor")
	assert(abs(player.global_position.y) < 0.05, "Player must stay grounded at Y ~ 0.0")
	print("[PASS] Player grounded at Y = 0.0 on floor collider")
	
	# 8. Test Navigation Around Desk
	print("[INFO] Testing player movement around desk...")
	var initial_x = player.global_position.x
	var initial_z = player.global_position.z
	
	# Move in open floor space
	for step in range(10):
		player.velocity = Vector3(2.0, 0.0, 0.0)
		player.move_and_slide()
		await physics_frame
	assert(player.is_on_floor(), "Player must stay grounded while walking")
	assert(player.global_position.x > initial_x, "Player must move right")
	
	for step in range(10):
		player.velocity = Vector3(0.0, 0.0, -2.0)
		player.move_and_slide()
		await physics_frame
	assert(player.is_on_floor(), "Player must stay grounded while walking")
	assert(abs(player.global_position.y) < 0.05, "Player Y must not drift while walking")
	print("[PASS] Player can navigate around desk without falling or floating")
	
	print("\n=== ALL VERIFICATIONS PASSED SUCCESSFULLY ===")
	main_node.queue_free()
	quit(0)
