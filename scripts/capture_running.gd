extends SceneTree

func _init():
	var scene = load("res://main.tscn")
	var inst = scene.instantiate()
	root.add_child(inst)
	
	var player = inst.find_child("Player", true, false)
	
	# Simulate moving forward/right for several frames
	Input.action_press("move_right")
	
	for i in range(25):
		await physics_frame
		
	var ap: AnimationPlayer = player.get_animation_player()
	print("Playing animation: ", ap.current_animation, " time: ", ap.current_animation_position)
	
	for i in range(5):
		await process_frame
		
	var img = root.get_texture().get_image()
	img.save_png("res://screenshot_graves_running.png")
	print("Running screenshot saved successfully!")
	
	Input.action_release("move_right")
	inst.queue_free()
	quit(0)
