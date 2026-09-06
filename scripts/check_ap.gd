extends SceneTree

func _init():
	var scene = load("res://player/graves_character.tscn")
	var inst = scene.instantiate()
	var ap: AnimationPlayer = inst.find_child("AnimationPlayer", true, false)
	print("AP path: ", inst.get_path_to(ap))
	print("AP root_node: ", ap.root_node)
	print("Skeleton path relative to AP root: ", ap.get_node_or_null(NodePath(str(ap.root_node) + "/Graves_Rig/Skeleton3D")))
	inst.queue_free()
	quit(0)
