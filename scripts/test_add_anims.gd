extends SceneTree

func _init():
	print("Testing loading animations from FBX...")
	var idle_scene = load("res://player/animations/idle.fbx")
	var run_scene = load("res://player/animations/run.fbx")
	
	var idle_inst = idle_scene.instantiate()
	var run_inst = run_scene.instantiate()
	
	var idle_ap: AnimationPlayer = idle_inst.find_child("AnimationPlayer", true, false)
	var run_ap: AnimationPlayer = run_inst.find_child("AnimationPlayer", true, false)
	
	var idle_anim: Animation = idle_ap.get_animation("mixamo_com").duplicate()
	var run_anim: Animation = run_ap.get_animation("mixamo_com").duplicate()
	
	idle_anim.loop_mode = Animation.LOOP_LINEAR
	run_anim.loop_mode = Animation.LOOP_LINEAR
	
	print("Idle length: ", idle_anim.length)
	print("Run length: ", run_anim.length)
	
	# Test saving as .res or .tres animation library, or directly saving in player scene
	var lib = AnimationLibrary.new()
	lib.add_animation("idle", idle_anim)
	lib.add_animation("run", run_anim)
	
	var err = ResourceSaver.save(lib, "res://player/animations/graves_animations.res")
	print("Saved lib result: ", err)
	
	idle_inst.queue_free()
	run_inst.queue_free()
	quit(0)
