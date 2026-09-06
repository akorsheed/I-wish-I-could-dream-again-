extends SceneTree

func _init():
	var idle_scene = load("res://player/animations/idle.fbx")
	var run_scene = load("res://player/animations/run.fbx")
	
	var idle_inst = idle_scene.instantiate()
	var run_inst = run_scene.instantiate()
	
	var idle_ap: AnimationPlayer = idle_inst.find_child("AnimationPlayer", true, false)
	var run_ap: AnimationPlayer = run_inst.find_child("AnimationPlayer", true, false)
	
	var idle_anim = idle_ap.get_animation("mixamo_com").duplicate()
	var run_anim = run_ap.get_animation("mixamo_com").duplicate()
	
	idle_anim.loop_mode = Animation.LOOP_LINEAR
	run_anim.loop_mode = Animation.LOOP_LINEAR
	
	var char_scene = load("res://player/graves_character.tscn")
	var char_inst = char_scene.instantiate()
	root.add_child(char_inst)
	
	var ap: AnimationPlayer = char_inst.find_child("AnimationPlayer", true, false)
	var lib: AnimationLibrary
	if ap.has_animation_library(""):
		lib = ap.get_animation_library("")
	else:
		lib = AnimationLibrary.new()
		ap.add_animation_library("", lib)
	
	if lib.has_animation("idle"):
		lib.remove_animation("idle")
	if lib.has_animation("walk"):
		lib.remove_animation("walk")
	if lib.has_animation("run"):
		lib.remove_animation("run")
		
	lib.add_animation("idle", idle_anim)
	lib.add_animation("run", run_anim)
	
	print("New animation list in player: ", ap.get_animation_list())
	
	ap.play("idle")
	for i in range(10):
		await process_frame
		
	var skel: Skeleton3D = char_inst.find_child("Skeleton3D", true, false)
	var b_idx = skel.find_bone("spine_0")
	print("spine_0 pose rotation during idle: ", skel.get_bone_pose_rotation(b_idx))
	
	ap.play("run")
	for i in range(10):
		await process_frame
	print("spine_0 pose rotation during run: ", skel.get_bone_pose_rotation(b_idx))
	
	char_inst.queue_free()
	idle_inst.queue_free()
	run_inst.queue_free()
	quit(0)
