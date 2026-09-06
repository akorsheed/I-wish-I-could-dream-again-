extends SceneTree

func _init():
	var scene = load("res://main.tscn")
	var inst = scene.instantiate()
	root.add_child(inst)
	
	for i in range(20):
		await process_frame
		
	var img = root.get_texture().get_image()
	img.save_png("res://screenshot_graves.png")
	print("Screenshot saved successfully!")
	inst.queue_free()
	quit(0)
