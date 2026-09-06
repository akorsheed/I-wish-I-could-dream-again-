extends SceneTree

func _init():
	var scene = load("res://main.tscn")
	var inst = scene.instantiate()
	root.add_child(inst)
	
	for i in range(5):
		await process_frame
		
	var player = inst.find_child("Player", true, false)
	print("Player: ", player)
	print("Player visible: ", player.visible)
	print("Player global_position: ", player.global_position)
	
	var visuals = player.find_child("Visuals", true, false)
	print("Visuals visible: ", visuals.visible)
	print("Visuals scale: ", visuals.scale)
	print("Visuals global_position: ", visuals.global_position)
	
	for c in player.find_children("*", "MeshInstance3D"):
		var mi: MeshInstance3D = c
		print("Mesh: ", mi.name, " visible: ", mi.visible, " global_pos: ", mi.global_position)
		
	inst.queue_free()
	quit(0)
