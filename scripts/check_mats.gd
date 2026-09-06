extends SceneTree

func _init():
	var p_scene = load("res://player/player.tscn")
	var p = p_scene.instantiate()
	root.add_child(p)
	
	for node in p.find_children("*", "MeshInstance3D"):
		var mi = node as MeshInstance3D
		print(mi.name, " surface count: ", mi.mesh.get_surface_count())
		for s in range(mi.mesh.get_surface_count()):
			var mat = mi.mesh.surface_get_material(s)
			var over = mi.get_surface_override_material(s)
			print("  surface ", s, " mat: ", mat, " override: ", over)
			
	p.queue_free()
	quit(0)
