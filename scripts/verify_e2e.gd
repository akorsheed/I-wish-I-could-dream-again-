extends SceneTree

func _init():
	print("==================================================")
	print("STARTING COMPREHENSIVE END-TO-END VERIFICATION")
	print("==================================================")
	
	var main_scene = load("res://main.tscn")
	if not main_scene:
		printerr("[FAIL] Could not load res://main.tscn")
		quit(1)
		return
		
	var main = main_scene.instantiate()
	root.add_child(main)
	
	# 1. Camera check
	var cam: Camera3D = main.find_child("Camera3D", true, false)
	assert(cam != null, "Camera3D not found")
	print("[PASS] Camera3D found at: ", cam.position, " size: ", cam.size, " proj: ", cam.projection)
	assert(cam.projection == Camera3D.PROJECTION_ORTHOGONAL, "Camera projection changed!")
	assert(is_equal_approx(cam.size, 32.0), "Camera size changed!")
	
	# 2. Desk lamp check
	var lamp: OmniLight3D = main.find_child("DeskLampLight", true, false)
	assert(lamp != null, "DeskLampLight not found")
	print("[PASS] DeskLampLight found at: ", lamp.position, " energy: ", lamp.light_energy)
	
	# 3. Environment colliders check
	var colliders = main.find_child("EnvironmentColliders", true, false)
	assert(colliders != null, "EnvironmentColliders not found")
	var chair = colliders.find_child("ChairCollision", true, false)
	var sw = colliders.find_child("BoundarySW", true, false)
	var se = colliders.find_child("BoundarySE", true, false)
	assert(chair != null and sw != null and se != null, "Colliders missing!")
	print("[PASS] All environment colliders intact: Chair, BoundarySW, BoundarySE")
	
	# 4. Player node check
	var player = main.find_child("Player", true, false)
	assert(player != null, "Player node not found")
	print("[PASS] Player found at: ", player.position)
	assert(player.position.y == 0.0, "Player not grounded at Y=0")
	
	# 5. Collision capsule check
	var col_shape: CollisionShape3D = player.find_child("CollisionShape3D", true, false)
	assert(col_shape != null, "CollisionShape3D not found on Player")
	var capsule: CapsuleShape3D = col_shape.shape as CapsuleShape3D
	assert(capsule != null, "Player shape is not CapsuleShape3D")
	print("[PASS] Player CapsuleShape3D height: ", capsule.height, " radius: ", capsule.radius)
	assert(is_equal_approx(capsule.height, 4.7), "Capsule height != 4.7")
	assert(is_equal_approx(capsule.radius, 0.7), "Capsule radius != 0.7")
	
	# 6. Visuals & Scale check
	var visuals = player.find_child("Visuals", true, false)
	assert(visuals != null, "Visuals node not found")
	print("[PASS] Visuals scale: ", visuals.scale)
	assert(is_equal_approx(visuals.scale.x, 2.7), "Visuals scale != 2.7")
	
	# 7. AnimationPlayer check
	var ap: AnimationPlayer = player.get_animation_player()
	assert(ap != null, "AnimationPlayer not found on Graves model")
	print("[PASS] AnimationPlayer found. Animations: ", ap.get_animation_list())
	assert(ap.has_animation("idle"), "idle animation missing")
	assert(ap.has_animation("run"), "run animation missing")
	var idle_clip = ap.get_animation("idle")
	var run_clip = ap.get_animation("run")
	assert(idle_clip.loop_mode == Animation.LOOP_LINEAR, "idle not looping linear")
	assert(run_clip.loop_mode == Animation.LOOP_LINEAR, "run not looping linear")
	print("[PASS] Both idle and run have loop_mode == LOOP_LINEAR")
	
	# 8. Hair material check
	var hair_mesh: MeshInstance3D = player.find_child("head_necro_hair_LOD0_001", true, false)
	assert(hair_mesh != null, "Hair mesh not found")
	var hair_override = hair_mesh.get_surface_override_material(0)
	assert(hair_override != null, "Hair material override missing")
	var orange_color = hair_override.albedo_color
	print("[PASS] Hair albedo_color: ", orange_color)
	assert(is_equal_approx(orange_color.r, 0.92) and is_equal_approx(orange_color.g, 0.45) and is_equal_approx(orange_color.b, 0.1), "Hair color mismatch!")
	
	# 9. Test Idle Playback
	for i in range(5):
		await process_frame
	print("[PASS] Current animation during idle: ", ap.current_animation)
	assert(ap.current_animation == "idle", "Did not start in idle")
	
	# 10. Simulate movement & Run Playback
	player.velocity = Vector3(3.0, 0, 0)
	# Trigger physics process
	player._physics_process(0.016)
	print("[PASS] Movement triggered: velocity.length() = ", player.velocity.length())
	print("[PASS] Current animation during move: ", ap.current_animation)
	assert(ap.current_animation == "run", "Did not transition to run!")
	
	# 11. Simulate stop & return to Idle
	player.velocity = Vector3.ZERO
	player._physics_process(0.016)
	print("[PASS] Movement stopped: velocity.length() = ", player.velocity.length())
	print("[PASS] Current animation after stop: ", ap.current_animation)
	assert(ap.current_animation == "idle", "Did not transition back to idle!")
	
	print("==================================================")
	print("ALL END-TO-END VERIFICATION CHECKS PASSED!")
	print("==================================================")
	
	main.queue_free()
	quit(0)
