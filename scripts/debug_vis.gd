extends SceneTree

func _init():
	var scene = load("res://main.tscn")
	var inst = scene.instantiate()
	root.add_child(inst)
	
	for i in range(20):
		await process_frame
		
	var p = inst.find_child("Player", true, false)
	print("Player in tree: ", p.is_inside_tree())
	print("Player visible in tree: ", p.is_visible_in_tree())
	print("Player global transform: ", p.global_transform)
	
	for c in p.find_children("*", "MeshInstance3D"):
		var mi: MeshInstance3D = c
		print("Mesh: ", mi.name, " vis_in_tree: ", mi.is_visible_in_tree(), " aabb: ", mi.get_aabb(), " global_aabb: ", mi.global_transform * mi.get_aabb())
		for s in range(mi.mesh.get_surface_count()):
			print("   s", s, " active mat: ", mi.get_active_material(s))
			
	inst.queue_free()
	quit(0)
