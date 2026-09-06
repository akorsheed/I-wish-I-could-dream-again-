extends SceneTree

func _init():
	print("Loading idle.fbx...")
	var idle_res = load("res://player/animations/idle.fbx")
	print("idle_res: ", idle_res)
	if idle_res:
		var inst = idle_res.instantiate()
		var ap: AnimationPlayer = inst.find_child("AnimationPlayer", true, false)
		if ap:
			print("Idle anims: ", ap.get_animation_list())
		inst.queue_free()

	print("Loading run.fbx...")
	var run_res = load("res://player/animations/run.fbx")
	print("run_res: ", run_res)
	if run_res:
		var inst = run_res.instantiate()
		var ap: AnimationPlayer = inst.find_child("AnimationPlayer", true, false)
		if ap:
			print("Run anims: ", ap.get_animation_list())
		inst.queue_free()

	quit(0)
