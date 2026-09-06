extends SceneTree

func _init():
	var scene = load("res://main.tscn")
	var inst = scene.instantiate()
	root.add_child(inst)
	
	for i in range(10):
		await process_frame
		
	var cam: Camera3D = inst.find_child("Camera3D", true, false)
	var player = inst.find_child("Player", true, false)
	
	print("Camera global pos: ", cam.global_position)
	print("Player global pos: ", player.global_position)
	
	var unproj = cam.unproject_position(player.global_position + Vector3(0, 2.0, 0))
	print("Player center screen pos (1920x1080): ", unproj)
	
	var is_behind = cam.is_position_behind(player.global_position)
	print("Is player behind camera: ", is_behind)
	
	inst.queue_free()
	quit(0)
