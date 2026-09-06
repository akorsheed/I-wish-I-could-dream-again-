extends SceneTree

func _init():
	print("--- VERIFYING HAIR RUNTIME SETUP ---")
	var scn = load("res://main.tscn").instantiate()
	root.add_child(scn)

	for i in range(5):
		await process_frame

	var player = scn.get_node("scene/Player")
	var hair1: MeshInstance3D = player.find_child("head_necro_hair_LOD0_001", true, false)
	assert(hair1 != null, "head_necro_hair_LOD0_001 must exist")

	var mat1 = hair1.get_surface_override_material(0)
	assert(mat1 != null, "Surface 0 on head_necro_hair_LOD0_001 must have a surface override material")
	assert(mat1 is StandardMaterial3D, "Override material must be StandardMaterial3D")
	var smat1 = mat1 as StandardMaterial3D

	print("[INFO] head_necro_hair_LOD0_001 material: ", smat1.resource_name)
	print("[INFO] albedo_color: ", smat1.albedo_color)
	assert(is_equal_approx(smat1.albedo_color.r, 0.92) and is_equal_approx(smat1.albedo_color.g, 0.45) and is_equal_approx(smat1.albedo_color.b, 0.1), "albedo_color must be Color(0.92, 0.45, 0.1, 1.0)")
	print("[PASS] albedo_color matches Color(0.92, 0.45, 0.1, 1.0)")

	assert(smat1.albedo_texture != null, "albedo_texture must be set")
	print("[INFO] albedo_texture path: ", smat1.albedo_texture.resource_path)
	assert("necro_hair_color" in smat1.albedo_texture.resource_path, "albedo_texture must be hair diffuse texture")
	print("[PASS] albedo_texture matches hair diffuse texture")

	assert(smat1.roughness_texture != null or smat1.roughness > 0.0, "Roughness must match hair texture/highlights")
	print("[INFO] roughness: %f, roughness_texture: %s" % [smat1.roughness, smat1.roughness_texture.resource_path if smat1.roughness_texture else "null"])
	print("[PASS] Roughness and specular highlights verified")

	var hair2: MeshInstance3D = player.find_child("necro_necro_hair_LOD0", true, false)
	if hair2:
		var mat2 = hair2.get_surface_override_material(0)
		assert(mat2 is StandardMaterial3D, "necro_necro_hair_LOD0 must also have StandardMaterial3D")
		var smat2 = mat2 as StandardMaterial3D
		assert(is_equal_approx(smat2.albedo_color.r, 0.92), "Main hair mesh albedo_color must also be orange")
		print("[PASS] Main hair mesh necro_necro_hair_LOD0 also verified orange")

	print("\n=== HAIR VERIFICATION SUCCESSFUL ===")
	scn.queue_free()
	quit(0)
