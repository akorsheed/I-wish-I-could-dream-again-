extends SceneTree

func _init():
	var gltf = GLTFDocument.new()
	var state = GLTFState.new()
	gltf.append_from_file("res://player/graves_character.glb", state)
	var model = gltf.generate_scene(state)
	root.add_child(model)
	
	for i in range(5):
		await process_frame
		
	var ap: AnimationPlayer = model.find_child("AnimationPlayer", true, false)
	print("Original GLB animations: ", ap.get_animation_list())
	ap.play("idle")
	
	for i in range(5):
		await process_frame
		
	var hair = model.find_child("head_necro_hair_LOD0_001", true, false)
	print("Original GLB hair global pos: ", hair.global_position)
	
	model.queue_free()
	quit(0)
