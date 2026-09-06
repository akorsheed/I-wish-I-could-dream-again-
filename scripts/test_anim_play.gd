extends SceneTree

func _init():
	var char_scene = load("res://player/graves_character.tscn")
	var char_inst = char_scene.instantiate()
	root.add_child(char_inst)
	
	var ap: AnimationPlayer = char_inst.find_child("AnimationPlayer", true, false)
	var lib = load("res://player/animations/graves_animations.res")
	ap.add_animation_library("", lib)
	
	print("Assigned library. Animations: ", ap.get_animation_list())
	ap.play("idle")
	
	for i in range(10):
		await process_frame
		
	var skel: Skeleton3D = char_inst.find_child("Skeleton3D", true, false)
	print("Pelvis bone pose after playing idle: ", skel.get_bone_pose_position(skel.find_bone("pelvis")))
	print("Pelvis rest position: ", skel.get_bone_rest(skel.find_bone("pelvis")).origin)
	
	char_inst.queue_free()
	quit(0)
