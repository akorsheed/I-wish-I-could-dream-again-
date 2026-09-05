"""
Headless Blender Python Script: Fix and Render Lovecraft Apartment Scene
Usage:
    & "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b -P scripts/render_lovecraft_scene.py
"""

import os
import math
import shutil
import bpy
import mathutils

def main():
    print("=" * 60)
    print("Starting Lovecraft Apartment Scene Fix and Render Pipeline")
    print("=" * 60)

    # File paths
    project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    input_gltf = r"C:\Users\start\Downloads\lovecrafts_apartment\scene.gltf"
    output_render_3 = os.path.join(project_root, "textures", "room_render_base_3.png")
    output_render_base = os.path.join(project_root, "textures", "room_render_base.png")
    output_proxy_path = os.path.join(project_root, "scenes", "lovecraft_proxy.glb")

    os.makedirs(os.path.dirname(output_render_3), exist_ok=True)
    os.makedirs(os.path.dirname(output_proxy_path), exist_ok=True)

    # -------------------------------------------------------------
    # 1. Reset Scene & Import glTF
    # -------------------------------------------------------------
    print(f"\n[Step 1] Importing model from: {input_gltf}")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=input_gltf)

    # -------------------------------------------------------------
    # 2. Cleanup: Remove Clutter, Fog, Backdrops, Floating Tentacles & Strays
    # -------------------------------------------------------------
    print("\n[Step 2] Detecting and removing clutter / fog / backdrop / tentacles / strays...")
    clutter_keywords = ["fog", "cloud", "smoke", "plane", "backdrop", "fon", "sphere", "ceil"]

    def get_descendants(root_obj):
        res = [root_obj]
        for ch in root_obj.children:
            res.extend(get_descendants(ch))
        return res

    to_delete = set()

    # 2a. Remove Armature and its entire hierarchy (tentacles, severed pieces, floating books)
    for obj_name in ["Armature", "LP", "LP_Tenta_0"]:
        found = bpy.data.objects.get(obj_name)
        if found:
            for d in get_descendants(found):
                to_delete.add(d)

    # 2b. Check keywords, foreground walls, foreground bookcases, and stray meshes outside room
    for obj in bpy.context.scene.objects:
        if not obj or obj.name not in bpy.data.objects:
            continue
        
        name_lower = obj.name.lower()
        mats = [m.name.lower() for m in obj.data.materials if m] if obj.type == 'MESH' and obj.data else []

        # Check clutter keywords
        if any(kw in name_lower for kw in clutter_keywords):
            to_delete.add(obj)
            continue

        # Check tentacle keywords in name or materials
        if any(kw in name_lower for kw in ["tenta", "monster", "appendage"]) or any("tenta" in m for m in mats):
            to_delete.add(obj)
            continue

        if obj.type == 'MESH':
            bbox = [obj.matrix_world @ mathutils.Vector(c) for c in obj.bound_box]
            min_v = mathutils.Vector((min(v[i] for v in bbox) for i in range(3)))
            max_v = mathutils.Vector((max(v[i] for v in bbox) for i in range(3)))
            center_v = (min_v + max_v) / 2.0

            # Preserve primary floor mesh
            if 'floor' in name_lower and max(obj.dimensions) > 5.0:
                continue

            # Remove hanging ceiling lampochka wires/bulbs
            if 'lampochka' in name_lower:
                to_delete.add(obj)
                continue

            # Strip all foreground objects (South-West border Y <= 1.0)
            # and all right border objects (South-East border X >= 14.0)
            if center_v.y <= 1.0 or center_v.x >= 14.0:
                to_delete.add(obj)
                continue

            # Strip meshes strictly outside room bounding walls
            # West wall at X=-1.0, North wall at Y=11.0
            if min_v.y > 11.2 or min_v.x < -1.5:
                to_delete.add(obj)
                continue

    print(f"  Total objects marked for removal: {len(to_delete)}")
    for obj in to_delete:
        if obj and obj.name in bpy.data.objects:
            bpy.data.objects.remove(obj, do_unlink=True)

    print(f"  Remaining objects in scene: {len(bpy.context.scene.objects)}")

    # -------------------------------------------------------------
    # 3. Locate Main Apartment Floor and Compute Bounds
    # -------------------------------------------------------------
    floor_obj = None
    for obj in bpy.context.scene.objects:
        if obj.type == 'MESH' and 'floor' in obj.name.lower() and max(obj.dimensions) > 5.0:
            floor_obj = obj
            break

    if not floor_obj:
        raise RuntimeError("Primary apartment floor mesh not found in scene!")

    bbox_world = [floor_obj.matrix_world @ mathutils.Vector(corner) for corner in floor_obj.bound_box]
    floor_min = mathutils.Vector((min(v[i] for v in bbox_world) for i in range(3)))
    floor_max = mathutils.Vector((max(v[i] for v in bbox_world) for i in range(3)))
    floor_center = (floor_min + floor_max) / 2.0
    floor_size = floor_max - floor_min

    print(f"\n[Floor Info]")
    print(f"  Floor Name: {floor_obj.name}")
    print(f"  Min: ({floor_min.x:.2f}, {floor_min.y:.2f}, {floor_min.z:.2f})")
    print(f"  Max: ({floor_max.x:.2f}, {floor_max.y:.2f}, {floor_max.z:.2f})")
    print(f"  Center: ({floor_center.x:.2f}, {floor_center.y:.2f}, {floor_center.z:.2f})")
    print(f"  Size: ({floor_size.x:.2f}, {floor_size.y:.2f}, {floor_size.z:.2f})")

    # -------------------------------------------------------------
    # 4. Orthographic Isometric Camera Setup
    # -------------------------------------------------------------
    print("\n[Step 3] Setting up Orthographic Isometric Camera...")
    cam_data = bpy.data.cameras.new("IsoCamera")
    cam_data.type = 'ORTHO'
    cam_data.clip_start = 0.1
    cam_data.clip_end = 200.0

    # Validated isometric orthographic framing:
    # ortho_scale = 32.0, target center at (7.0, 5.5, 2.4)
    ortho_scale = 32.0
    cam_data.ortho_scale = ortho_scale

    cam_obj = bpy.data.objects.new("IsoCamera", cam_data)
    bpy.context.scene.collection.objects.link(cam_obj)
    bpy.context.scene.camera = cam_obj

    # Classic isometric: Vector3(0.9553, 0.0, 0.7854) (54.736° X, 0° Y, 45° Z)
    cam_obj.rotation_euler = (0.9553, 0.0, 0.7854)
    bpy.context.view_layer.update()

    # Camera forward direction in world space (-Z local)
    cam_rot_mat = cam_obj.rotation_euler.to_matrix()
    view_vector = cam_rot_mat @ mathutils.Vector((0, 0, -1))

    # Center camera on room mid-height (Z=2.4) and Y=5.5
    target_center = mathutils.Vector((floor_center.x, 5.5, 2.4))
    cam_distance = 50.0
    cam_obj.location = target_center - view_vector * cam_distance
    bpy.context.view_layer.update()

    rot_deg = [math.degrees(a) for a in cam_obj.rotation_euler]
    print("=" * 40)
    print("CAMERA LOG:")
    print(f"  World Translation (Blender): ({cam_obj.location.x:.4f}, {cam_obj.location.y:.4f}, {cam_obj.location.z:.4f})")
    print(f"  Rotation Degrees (Blender):  ({rot_deg[0]:.4f}, {rot_deg[1]:.4f}, {rot_deg[2]:.4f})")
    print(f"  Rotation Euler (Radians):    ({cam_obj.rotation_euler[0]:.4f}, {cam_obj.rotation_euler[1]:.4f}, {cam_obj.rotation_euler[2]:.4f})")
    print(f"  Target Center (Blender):     ({target_center.x:.4f}, {target_center.y:.4f}, {target_center.z:.4f})")
    print(f"  Ortho Scale:                 {ortho_scale:.2f}")
    print(f"  Godot Translation (-0.26 Y): ({cam_obj.location.x:.4f}, {cam_obj.location.z - 0.26:.4f}, {-cam_obj.location.y:.4f})")
    print("=" * 40)

    # -------------------------------------------------------------
    # 5. Studio Lighting Setup
    # -------------------------------------------------------------
    print("\n[Step 4] Setting up Balanced Lighting...")
    world = bpy.data.worlds.new("LovecraftWorld")
    bpy.context.scene.world = world
    world.use_nodes = True
    bg_node = world.node_tree.nodes.get("Background")
    if bg_node:
        bg_node.inputs["Color"].default_value = (0.50, 0.52, 0.56, 1.0)
        bg_node.inputs["Strength"].default_value = 1.2

    key_light_data = bpy.data.lights.new("KeySun", 'SUN')
    key_light_data.energy = 2.5
    key_light_data.color = (1.0, 0.98, 0.94)
    key_light_obj = bpy.data.objects.new("KeySun", key_light_data)
    bpy.context.scene.collection.objects.link(key_light_obj)
    key_light_obj.rotation_euler = (math.radians(60), math.radians(10), math.radians(45))

    fill_light_data = bpy.data.lights.new("FillSun", 'SUN')
    fill_light_data.energy = 1.0
    fill_light_data.color = (0.95, 0.90, 0.85)
    fill_light_obj = bpy.data.objects.new("FillSun", fill_light_data)
    bpy.context.scene.collection.objects.link(fill_light_obj)
    fill_light_obj.rotation_euler = (math.radians(45), math.radians(-30), math.radians(-120))

    # -------------------------------------------------------------
    # 6. Render Reference Image
    # -------------------------------------------------------------
    print(f"\n[Step 5] Rendering Reference Image to: {output_render_3}")
    res_x = 1920
    res_y = 1080
    bpy.context.scene.render.engine = 'BLENDER_EEVEE'
    bpy.context.scene.render.resolution_x = res_x
    bpy.context.scene.render.resolution_y = res_y
    bpy.context.scene.render.film_transparent = True
    bpy.context.scene.render.image_settings.file_format = 'PNG'
    bpy.context.scene.render.image_settings.color_mode = 'RGBA'
    bpy.context.scene.render.filepath = output_render_3

    bpy.ops.render.render(write_still=True)

    if os.path.exists(output_render_3) and os.path.getsize(output_render_3) > 0:
        print(f"  SUCCESS: Render generated ({os.path.getsize(output_render_3):,} bytes)")
        print(f"  OUTPUT_IMAGE: {output_render_3}")
        # Copy to room_render_base.png as well
        shutil.copy2(output_render_3, output_render_base)
        print(f"  COPIED TO:   {output_render_base}")
    else:
        raise RuntimeError(f"Failed to render image to {output_render_3}")

    # -------------------------------------------------------------
    # 7. Generate Low-Poly Proxy with -col Suffixes
    # -------------------------------------------------------------
    print(f"\n[Step 6] Generating Low-Poly Proxy Geometry with -col suffixes...")

    def compute_aabb(obj):
        corners = [obj.matrix_world @ mathutils.Vector(c) for c in obj.bound_box]
        min_v = mathutils.Vector((min(v[i] for v in corners) for i in range(3)))
        max_v = mathutils.Vector((max(v[i] for v in corners) for i in range(3)))
        center_v = (min_v + max_v) / 2.0
        size_v = max_v - min_v
        return center_v, size_v

    def create_box_mesh(name, center, size, col):
        me = bpy.data.meshes.new(name)
        ob = bpy.data.objects.new(name, me)
        col.objects.link(ob)
        
        sx, sy, sz = size[0] / 2.0, size[1] / 2.0, size[2] / 2.0
        cx, cy, cz = center[0], center[1], center[2]
        
        verts = [
            (cx - sx, cy - sy, cz - sz),
            (cx + sx, cy - sy, cz - sz),
            (cx + sx, cy + sy, cz - sz),
            (cx - sx, cy + sy, cz - sz),
            (cx - sx, cy - sy, cz + sz),
            (cx + sx, cy - sy, cz + sz),
            (cx + sx, cy + sy, cz + sz),
            (cx - sx, cy + sy, cz + sz)
        ]
        # Counter-clockwise winding for outward-pointing normals
        faces = [
            (0, 3, 2, 1),  # Bottom (-Z)
            (4, 5, 6, 7),  # Top (+Z)
            (0, 1, 5, 4),  # Front (-Y)
            (1, 2, 6, 5),  # Right (+X)
            (2, 3, 7, 6),  # Back (+Y)
            (3, 0, 4, 7)   # Left (-X)
        ]
        me.from_pydata(verts, [], faces)
        me.update()
        return ob

    proxy_col = bpy.data.collections.new("ProxyCollection")
    bpy.context.scene.collection.children.link(proxy_col)
    proxy_objects = []

    # Required simplified collision boxes:
    # 1. Floor-col: (7.0, 5.0, 0.01) size (16.0, 12.0, 0.5) -> top surface at Z=0.26
    floor_col = create_box_mesh("Floor-col", (7.0, 5.0, 0.01), (16.0, 12.0, 0.5), proxy_col)
    proxy_objects.append(floor_col)

    # 2. BackWall_1-col: North-West back wall along X = -1.0
    bw1_col = create_box_mesh("BackWall_1-col", (-1.0, 5.0, 3.14), (0.4, 12.0, 5.76), proxy_col)
    proxy_objects.append(bw1_col)

    # 3. BackWall_2-col: North-East back wall along Y = 11.0
    bw2_col = create_box_mesh("BackWall_2-col", (7.0, 11.0, 3.14), (16.0, 0.4, 5.76), proxy_col)
    proxy_objects.append(bw2_col)

    # 4. Desk-col: Main desk
    desk_obj = None
    for obj in bpy.context.scene.objects:
        if 'pokritie' in obj.name.lower() and obj.type == 'MESH' and obj.matrix_world.translation.y > 0:
            desk_obj = obj
            break
    if desk_obj:
        d_center, d_size = compute_aabb(desk_obj)
        desk_col = create_box_mesh("Desk-col", d_center, d_size, proxy_col)
    else:
        desk_col = create_box_mesh("Desk-col", (2.08, 5.32, 1.22), (2.17, 3.75, 1.93), proxy_col)
    proxy_objects.append(desk_col)

    # 5. Bookcase_1-col: Rear bookcase 1 (X ~ 3.03, Y ~ 10.01)
    b1_obj = bpy.data.objects.get("book_cabinet.002_book_cabinet_0")
    if b1_obj:
        b1_center, b1_size = compute_aabb(b1_obj)
        b1_col = create_box_mesh("Bookcase_1-col", b1_center, b1_size, proxy_col)
    else:
        b1_col = create_box_mesh("Bookcase_1-col", (3.03, 10.01, 2.81), (3.13, 1.01, 5.11), proxy_col)
    proxy_objects.append(b1_col)

    # 6. Bookcase_2-col: Rear bookcase 2 (X ~ 7.09, Y ~ 10.01)
    b2_obj = bpy.data.objects.get("book_cabinet.003_book_cabinet_0")
    if b2_obj:
        b2_center, b2_size = compute_aabb(b2_obj)
        b2_col = create_box_mesh("Bookcase_2-col", b2_center, b2_size, proxy_col)
    else:
        b2_col = create_box_mesh("Bookcase_2-col", (7.09, 10.01, 2.81), (3.13, 1.01, 5.11), proxy_col)
    proxy_objects.append(b2_col)

    # 7. Mirror-col: Standing ornate mirror along North-East wall
    mirror_col = create_box_mesh("Mirror-col", (10.3, 10.45, 2.5), (1.6, 0.6, 4.5), proxy_col)
    proxy_objects.append(mirror_col)

    # 8. Bookcase_3-col: Bookcase to the right of the mirror along North-East wall
    b3_col = create_box_mesh("Bookcase_3-col", (13.2, 10.01, 2.81), (2.6, 1.01, 5.11), proxy_col)
    proxy_objects.append(b3_col)

    print(f"  Created {len(proxy_objects)} proxy collision/geometry meshes:")
    for p in proxy_objects:
        print(f"    - {p.name}: center={[round(x, 2) for x in p.location]} dims={[round(x, 2) for x in p.dimensions]}")

    # Select ONLY proxy objects for export
    bpy.ops.object.select_all(action='DESELECT')
    for p in proxy_objects:
        p.select_set(True)
    bpy.context.view_layer.objects.active = proxy_objects[0]

    print(f"\n[Step 7] Exporting Low-Poly Proxy to: {output_proxy_path}")
    bpy.ops.export_scene.gltf(
        filepath=output_proxy_path,
        use_selection=True,
        export_apply=True
    )

    if os.path.exists(output_proxy_path) and os.path.getsize(output_proxy_path) > 0:
        print(f"  SUCCESS: Proxy model exported ({os.path.getsize(output_proxy_path):,} bytes)")
        print(f"  OUTPUT_PROXY: {output_proxy_path}")
    else:
        raise RuntimeError(f"Failed to export proxy model to {output_proxy_path}")

    print("\n" + "=" * 60)
    print("Lovecraft Apartment Scene Pipeline Finished Successfully!")
    print(f"Rendered Image (3): {output_render_3}")
    print(f"Rendered Image:     {output_render_base}")
    print(f"Proxy Model:        {output_proxy_path}")
    print("=" * 60)

if __name__ == "__main__":
    main()

