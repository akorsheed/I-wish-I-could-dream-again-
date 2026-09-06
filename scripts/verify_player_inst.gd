extends SceneTree

func _init():
	var p_scene = load("res://player/player.tscn")
	var p = p_scene.instantiate()
	root.add_child(p)
	
	var ap: AnimationPlayer = p.get_animation_player()
	print("Player anim player found: ", ap != null)
	if ap:
		print("Animations available in Player: ", ap.get_animation_list())
		print("Has idle: ", ap.has_animation("idle"), " has run: ", ap.has_animation("run"))
	
	p.queue_free()
	quit(0)
