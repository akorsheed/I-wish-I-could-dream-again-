extends SceneTree

func _init():
	print("Checking ResourceLoader for fbx...")
	var res = ResourceLoader.load("res://player/animations/idle.fbx")
	print("Loaded fbx directly? ", res)
	quit(0)
