extends SceneTree

func _init():
	print("--- Setting up Graves animations cleanly ---")
	var idle_fbx = load("res://player/animations/idle.fbx")
	var run_fbx = load("res://player/animations/run.fbx")
	
	var idle_inst = idle_fbx.instantiate()
	var run_inst = run_fbx.instantiate()
	
	var idle_ap: AnimationPlayer = idle_inst.find_child("AnimationPlayer", true, false)
	var run_ap: AnimationPlayer = run_inst.find_child("AnimationPlayer", true, false)
	
	var idle_anim: Animation = idle_ap.get_animation("mixamo_com").duplicate()
	var run_anim: Animation = run_ap.get_animation("mixamo_com").duplicate()
	
	idle_anim.loop_mode = Animation.LOOP_LINEAR
	run_anim.loop_mode = Animation.LOOP_LINEAR
	
	# Strip Graves_Rig root tracks from idle_anim
	for t in range(idle_anim.get_track_count() - 1, -1, -1):
		if str(idle_anim.track_get_path(t)) == "Graves_Rig":
			idle_anim.remove_track(t)
			
	# Strip Graves_Rig root tracks from run_anim
	for t in range(run_anim.get_track_count() - 1, -1, -1):
		if str(run_anim.track_get_path(t)) == "Graves_Rig":
			run_anim.remove_track(t)
			
	print("Clean idle track count: ", idle_anim.get_track_count())
	print("Clean run track count: ", run_anim.get_track_count())
	
	var anim_lib = AnimationLibrary.new()
	anim_lib.add_animation("idle", idle_anim)
	anim_lib.add_animation("run", run_anim)
	
	# Save library resource
	var err_save_res = ResourceSaver.save(anim_lib, "res://player/animations/graves_animations.tres")
	print("Saved graves_animations.tres result: ", err_save_res)
	
	# Load graves_character scene
	var scn = load("res://player/graves_character.tscn")
	var char_inst = scn.instantiate()
	var ap: AnimationPlayer = char_inst.find_child("AnimationPlayer", true, false)
	
	# Reset rig transform to clean default if needed
	var rig = char_inst.find_child("Graves_Rig", true, false)
	if rig:
		rig.position = Vector3.ZERO
		rig.rotation = Vector3.ZERO
	
	if ap.has_animation_library(""):
		ap.remove_animation_library("")
	ap.add_animation_library("", anim_lib)
	ap.autoplay = "idle"
	
	print("AnimationPlayer libraries: ", ap.get_animation_library_list())
	print("AnimationPlayer animations: ", ap.get_animation_list())
	
	# Set owner recursively to char_inst so it packs cleanly
	_set_owner_recursive(char_inst, char_inst)
	var packed = PackedScene.new()
	var pack_err = packed.pack(char_inst)
	if pack_err == OK:
		var save_err = ResourceSaver.save(packed, "res://player/graves_character.tscn")
		print("Saved graves_character.tscn result: ", save_err)
	else:
		printerr("Failed to pack scene: ", pack_err)
		
	idle_inst.queue_free()
	run_inst.queue_free()
	char_inst.queue_free()
	quit(0)

func _set_owner_recursive(node: Node, root_node: Node) -> void:
	for child in node.get_children():
		child.owner = root_node
		_set_owner_recursive(child, root_node)
