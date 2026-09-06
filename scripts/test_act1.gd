extends SceneTree

func _init() -> void:
	print("--- Starting Act 1 Verification Tests ---")
	
	# 1. Test Speaker Resources
	print("\n[Test 1] Testing Speaker Resources...")
	var required_speakers = [
		"SHARP_GUILT",
		"FADING_LOGIC",
		"PRIMARY_NARRATOR",
		"CHRONIC_SHAME",
		"NOSTALGIC_ACHE",
		"CYNICAL_DETACHMENT",
		"OBSESSIVE_DREAD"
	]
	for spk in required_speakers:
		var path = "res://speakers/%s.tres" % spk
		assert(ResourceLoader.exists(path), "Speaker resource not found: " + path)
		var res = load(path)
		assert(res != null, "Failed to load speaker: " + spk)
		assert(res.speaker_name != "", "Speaker name empty: " + spk)
		print("  - OK: Speaker %s (%s, color: %s)" % [spk, res.speaker_name, res.get_speaker_color()])

	# 2. Test Clyde Dialogues
	print("\n[Test 2] Testing Clyde Dialogues...")
	var dialogues = ["act1_bookcase", "act1_window", "act1_desk"]
	for d in dialogues:
		var clyde = ClydeDialogue.new()
		clyde.load_dialogue(d)
		var first_content = clyde.get_content()
		assert(first_content != null, "First line was null for: " + d)
		assert(first_content.type == ClydeDialogue.CONTENT_TYPE_LINE, "Expected line type for: " + d)
		print("  - OK: Dialogue %s loaded. First speaker: %s, text preview: %s..." % [d, first_content.speaker, first_content.text.substr(0, 40)])

	# 3. Test Main Scene Instantiation & Verification
	print("\n[Test 3] Testing Scene Nodes & Rendering Settings...")
	var main_scene = load("res://main.tscn")
	assert(main_scene != null, "Failed to load main.tscn")
	var root = main_scene.instantiate()
	root_node_test(root)
	root.queue_free()

	print("\n=== ALL ACT 1 TESTS PASSED SUCCESSFULLY! ===")
	quit(0)

func root_node_test(root: Node) -> void:
	# Check Holdout Desk & Collision
	var desk = root.find_child("Desk", true, false) as MeshInstance3D
	assert(desk != null, "Desk node not found")
	assert(desk.material_override != null, "Desk has no material_override")
	assert(desk.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "Desk should have cast_shadow off")
	print("  - OK: Desk holdout mesh configured with material %s and shadow_casting_setting=OFF" % desk.material_override.resource_path)

	var desk_body = desk.find_child("StaticBody3D", true, false) as StaticBody3D
	assert(desk_body != null, "Desk StaticBody3D not found")
	assert(desk_body.collision_layer == 1, "Desk StaticBody3D must have collision_layer=1")
	var desk_col = desk_body.find_child("CollisionShape3D", true, false) as CollisionShape3D
	assert(desk_col != null, "Desk CollisionShape3D not found")
	assert(desk_col.shape is BoxShape3D, "Desk CollisionShape3D must be a BoxShape3D")
	var box = desk_col.shape as BoxShape3D
	assert(box.size.x >= 2.0 and box.size.y >= 2.0, "Desk collider box size too small")
	print("  - OK: Desk StaticBody3D has collision_layer=1, BoxShape3D size=%s, transform=%s" % [box.size, desk_col.transform.origin])

	# Check Player
	var player = root.find_child("Player", true, false) as CharacterBody3D
	assert(player != null, "Player not found")
	assert(player.collision_layer == 2, "Player must be on layer 2")
	assert(player.collision_mask == 1, "Player mask must be 1")
	assert(player.floor_max_angle <= 0.79, "Player floor_max_angle must be <= 0.79 rad (45 deg)")
	assert(player.floor_snap_length <= 0.3, "Player floor_snap_length must be <= 0.3m")
	print("  - OK: Player CharacterBody3D layer=%d, mask=%d, floor_max_angle=%.3f, floor_snap_length=%.2f" % [player.collision_layer, player.collision_mask, player.floor_max_angle, player.floor_snap_length])

	# Check Lights
	var desk_lamp = root.find_child("DeskLampLight", true, false) as Light3D
	assert(desk_lamp != null, "DeskLampLight not found")
	assert(desk_lamp.shadow_enabled, "DeskLampLight shadow must be enabled")
	assert((desk_lamp.light_cull_mask & 2) != 0, "DeskLampLight must include Layer 2 for player")
	print("  - OK: DeskLampLight has shadow_enabled=true and light_cull_mask=%d" % desk_lamp.light_cull_mask)

	var dir_light = root.find_child("DirectionalLight3D", true, false) as DirectionalLight3D
	assert(dir_light != null, "DirectionalLight3D not found")
	assert(dir_light.visible, "DirectionalLight3D must be visible")
	assert(dir_light.shadow_enabled, "DirectionalLight3D shadow must be enabled")
	assert((dir_light.light_cull_mask & 2) != 0, "DirectionalLight3D must include Layer 2 for player")
	print("  - OK: DirectionalLight3D visible=true, shadow_enabled=true, light_cull_mask=%d" % dir_light.light_cull_mask)

	# Check Interaction Areas
	var bookcase_area = root.find_child("BookcaseInteractionArea", true, false)
	assert(bookcase_area != null, "BookcaseInteractionArea not found")
	assert(bookcase_area.prompt_text == "[E] Search Reference", "BookcaseInteractionArea wrong prompt: " + bookcase_area.prompt_text)
	print("  - OK: BookcaseInteractionArea configured with prompt '%s'" % bookcase_area.prompt_text)

	var window_area = root.find_child("WindowInteractionArea", true, false)
	assert(window_area != null, "WindowInteractionArea not found")
	assert(window_area.prompt_text == "[E] Look Through Pane", "WindowInteractionArea wrong prompt: " + window_area.prompt_text)
	print("  - OK: WindowInteractionArea configured with prompt '%s'" % window_area.prompt_text)

	var desk_area = root.find_child("DeskInteractionArea", true, false)
	assert(desk_area != null, "DeskInteractionArea not found")
	assert(desk_area.prompt_text == "[E] Sit at Desk", "DeskInteractionArea wrong prompt: " + desk_area.prompt_text)
	print("  - OK: DeskInteractionArea configured with prompt '%s'" % desk_area.prompt_text)

	# Check HUD elements
	var fade_overlay = root.find_child("FadeOverlay", true, false) as ColorRect
	assert(fade_overlay != null, "FadeOverlay not found")
	print("  - OK: FadeOverlay configured under HUD")

	var act_end = root.find_child("ActEndContainer", true, false)
	assert(act_end != null, "ActEndContainer not found")
	print("  - OK: ActEndContainer configured under HUD")
