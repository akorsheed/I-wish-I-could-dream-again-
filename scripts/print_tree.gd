extends SceneTree

func print_tree_node(node: Node, indent: String = ""):
	print(indent, node.name, " (", node.get_class(), ")")
	for c in node.get_children():
		print_tree_node(c, indent + "  ")

func _init():
	var scene = load("res://player/graves_character.tscn")
	var inst = scene.instantiate()
	print_tree_node(inst)
	inst.queue_free()
	quit(0)
