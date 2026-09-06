extends SceneTree

func _init():
	var run_res = load("res://player/animations/run.fbx")
	var inst = run_res.instantiate()
	var ap: AnimationPlayer = inst.find_child("AnimationPlayer", true, false)
	var anim: Animation = ap.get_animation("mixamo_com")
	for i in range(anim.get_track_count()):
		if anim.track_get_type(i) == Animation.TYPE_POSITION_3D:
			print("Pos track ", i, ": ", anim.track_get_path(i))
	inst.queue_free()
	quit(0)
