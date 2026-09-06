extends SceneTree

func _init():
	var scene = load("res://main.tscn")
	var inst = scene.instantiate()
	root.add_child(inst)
	
	for i in range(5):
		await process_frame
		
	var cam: Camera3D = inst.find_child("Camera3D", true, false)
	var player = inst.find_child("Player", true, false)
	var screen_pos = cam.unproject_position(player.global_position)
	print("Player screen pos: ", screen_pos)
	
	var mesh = player.find_child("head_necro_hair_LOD0_001", true, false)
	print("Hair mesh screen pos: ", cam.unproject_position(mesh.global_position))
	
	var head_pos = mesh.global_position + Vector3(0, 4.0, 0)
	print("Head screen pos: ", cam.unproject_position(head_pos))
	
	inst.queue_free()
	quit(0)
