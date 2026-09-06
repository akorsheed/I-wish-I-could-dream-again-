extends SceneTree

func _init():
	var idle_res = load("res://player/animations/idle.fbx")
	var inst = idle_res.instantiate()
	var ap: AnimationPlayer = inst.find_child("AnimationPlayer", true, false)
	var anim: Animation = ap.get_animation("mixamo_com")
	print("Track count: ", anim.get_track_count())
	for i in range(min(5, anim.get_track_count())):
		print("Track ", i, ": ", anim.track_get_path(i))
	inst.queue_free()
	quit(0)
