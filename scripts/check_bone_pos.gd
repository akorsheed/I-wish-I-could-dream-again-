extends SceneTree

func _init():
	var gltf = GLTFDocument.new()
	var state = GLTFState.new()
	gltf.append_from_file("res://player/graves_character.glb", state)
	var model = gltf.generate_scene(state)
	root.add_child(model)
	
	for i in range(5):
		await process_frame
		
	var ap: AnimationPlayer = model.find_child("AnimationPlayer", true, false)
	var skel: Skeleton3D = model.find_child("Skeleton3D", true, false)
	var p_bone = skel.find_bone("pelvis")
	var h_bone = skel.find_bone("head")
	
	print("--- REST POSE ---")
	print("Pelvis rest: ", skel.get_bone_rest(p_bone).origin)
	print("Head rest: ", skel.get_bone_rest(h_bone).origin)
	print("Pelvis global: ", skel.to_global(skel.get_bone_global_pose(p_bone).origin))
	print("Head global: ", skel.to_global(skel.get_bone_global_pose(h_bone).origin))
	
	print("\n--- PLAYING ORIGINAL GLB IDLE ---")
	ap.play("idle")
	for i in range(5):
		await process_frame
	print("Pelvis global: ", skel.to_global(skel.get_bone_global_pose(p_bone).origin))
	print("Head global: ", skel.to_global(skel.get_bone_global_pose(h_bone).origin))
	
	print("\n--- PLAYING FBX IDLE ---")
	var fbx_lib = load("res://player/animations/graves_animations.tres")
	ap.remove_animation_library("")
	ap.add_animation_library("", fbx_lib)
	ap.play("idle")
	for i in range(5):
		await process_frame
	print("Pelvis global: ", skel.to_global(skel.get_bone_global_pose(p_bone).origin))
	print("Head global: ", skel.to_global(skel.get_bone_global_pose(h_bone).origin))
	
	model.queue_free()
	quit(0)
