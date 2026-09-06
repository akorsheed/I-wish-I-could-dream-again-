extends SceneTree

func _init():
	var scene = load("res://player/graves_character.tscn")
	var inst = scene.instantiate()
	var skel: Skeleton3D = inst.find_child("Skeleton3D", true, false)
	print("Skeleton children count: ", skel.get_child_count())
	for i in range(skel.get_child_count()):
		var c = skel.get_child(i)
		print("  child ", i, ": ", c.name, " (", c.get_class(), ")")
		if c is MeshInstance3D:
			print("    mesh: ", c.mesh)
			print("    skin: ", c.skin)
			print("    skeleton: ", c.skeleton)
	inst.queue_free()
	quit(0)
