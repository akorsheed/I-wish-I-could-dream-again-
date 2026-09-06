extends SceneTree

func _init():
	print("--- Generating res://player/graves_character.tscn from GLB ---")
	
	# Use GLTFDocument to import cleanly without depending on runtime resource loader for glb
	var gltf_doc = GLTFDocument.new()
	var gltf_state = GLTFState.new()
	var error = gltf_doc.append_from_file("res://player/graves_character.glb", gltf_state)
	if error != OK:
		printerr("GLTFDocument failed to load res://player/graves_character.glb, error: ", error)
		# Fallback: try load()
		var res = load("res://player/graves_character.glb")
		if res:
			var node = res.instantiate()
			_save_node_as_scene(node, "res://player/graves_character.tscn")
			quit(0)
			return
		quit(1)
		return
	
	var root_node = gltf_doc.generate_scene(gltf_state)
	if not root_node:
		printerr("Failed to generate scene from GLTFState")
		quit(1)
		return
	
	_save_node_as_scene(root_node, "res://player/graves_character.tscn")
	quit(0)

func _save_node_as_scene(root_node: Node, save_path: String) -> void:
	# Set owner recursively so all children serialize into the .tscn
	_set_owner_recursive(root_node, root_node)
	
	var packed_scene = PackedScene.new()
	var pack_err = packed_scene.pack(root_node)
	if pack_err != OK:
		printerr("Failed to pack scene, error: ", pack_err)
		quit(1)
		return
	
	var save_err = ResourceSaver.save(packed_scene, save_path)
	if save_err != OK:
		printerr("Failed to save scene to ", save_path, ", error: ", save_err)
		quit(1)
		return
	
	print("[SUCCESS] Successfully generated and saved: ", save_path)
	root_node.queue_free()

func _set_owner_recursive(node: Node, root_node: Node) -> void:
	for child in node.get_children():
		child.owner = root_node
		_set_owner_recursive(child, root_node)
