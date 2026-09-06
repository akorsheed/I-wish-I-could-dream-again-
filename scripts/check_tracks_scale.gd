extends SceneTree

func _init():
	var scene = load("res://player/player.tscn")
	var inst = scene.instantiate()
	root.add_child(inst)
	
	var mi = inst.find_child("head_necro_head_LOD0", true, false)
	print("Mesh parent: ", mi.get_parent().name)
	print("Mesh local transform: ", mi.transform)
	print("Mesh global transform: ", mi.global_transform)
	print("Skeleton transform: ", mi.get_parent().transform)
	print("Graves_Rig transform: ", mi.get_parent().get_parent().transform)
	print("graves_character transform: ", mi.get_parent().get_parent().get_parent().transform)
	print("Visuals transform: ", inst.find_child("Visuals", true, false).transform)
	
	inst.queue_free()
	quit(0)
