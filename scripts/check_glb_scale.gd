extends SceneTree

func _init():
	var idle_scene = load("res://player/animations/idle.fbx")
	var inst = idle_scene.instantiate()
	var skel: Skeleton3D = inst.find_child("Skeleton3D", true, false)
	print("FBX skel bone count: ", skel.get_bone_count())
	print("FBX Pelvis rest: ", skel.get_bone_rest(skel.find_bone("pelvis")).origin)
	var rig = inst.find_child("Graves_Rig", true, false)
	print("FBX rig scale: ", rig.scale)
	print("FBX rig transform: ", rig.transform)
	inst.queue_free()
	quit(0)
