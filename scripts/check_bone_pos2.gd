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
	var f_l_bone = skel.find_bone("footIK_L")
	var f_r_bone = skel.find_bone("footIK_R")
	
	var run_fbx = load("res://player/animations/run.fbx")
	var fbx_inst = run_fbx.instantiate()
	var fbx_ap: AnimationPlayer = fbx_inst.find_child("AnimationPlayer", true, false)
	var fbx_anim = fbx_ap.get_animation("mixamo_com").duplicate()
	
	for t in range(fbx_anim.get_track_count() - 1, -1, -1):
		var p = str(fbx_anim.track_get_path(t))
		if p == "Graves_Rig":
			fbx_anim.remove_track(t)
			
	var lib = AnimationLibrary.new()
	lib.add_animation("run_test", fbx_anim)
	ap.add_animation_library("test", lib)
	ap.play("test/run_test")
	
	for i in range(10):
		await process_frame
		
	print("--- RUN WITH GRAVES_RIG TRACKS REMOVED ---")
	print("Pelvis global: ", skel.to_global(skel.get_bone_global_pose(p_bone).origin))
	print("Head global: ", skel.to_global(skel.get_bone_global_pose(h_bone).origin))
	print("Foot L global: ", skel.to_global(skel.get_bone_global_pose(f_l_bone).origin))
	print("Foot R global: ", skel.to_global(skel.get_bone_global_pose(f_r_bone).origin))
	
	model.queue_free()
	fbx_inst.queue_free()
	quit(0)
