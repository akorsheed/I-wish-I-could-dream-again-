extends SceneTree

func _init():
	var run_res = load("res://player/animations/run.fbx")
	var inst = run_res.instantiate()
	var ap: AnimationPlayer = inst.find_child("AnimationPlayer", true, false)
	var anim: Animation = ap.get_animation("mixamo_com").duplicate()
	
	# Find track 0 (Graves_Rig position)
	for t in range(anim.get_track_count()):
		if anim.track_get_path(t) == NodePath("Graves_Rig") and anim.track_get_type(t) == Animation.TYPE_POSITION_3D:
			var init_val = anim.track_get_key_value(t, 0)
			for k in range(anim.track_get_key_count(t)):
				var v = anim.track_get_key_value(t, k)
				# keep Y bobbing, lock X and Z
				anim.track_set_key_value(t, k, Vector3(init_val.x, v.y, init_val.z))
	
	anim.loop_mode = Animation.LOOP_LINEAR
	print("Adjusted run animation to in-place!")
	inst.queue_free()
	quit(0)
