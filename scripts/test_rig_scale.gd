extends SceneTree

func _init():
	var scn = load("res://player/player.tscn")
	var inst = scn.instantiate()
	root.add_child(inst)
	
	for i in range(5):
		await process_frame
		
	var rig = inst.find_child("Graves_Rig", true, false)
	print("Current rig scale: ", rig.scale)
	
	# Try setting rig scale to 1.0
	rig.scale = Vector3.ONE
	
	for i in range(5):
		await process_frame
		
	var skel: Skeleton3D = inst.find_child("Skeleton3D", true, false)
	var hair = inst.find_child("head_necro_hair_LOD0_001", true, false)
	print("Hair global pos after rig.scale=1: ", hair.global_position)
	print("Rig global scale: ", rig.global_transform.basis.get_scale())
	
	inst.queue_free()
	quit(0)
