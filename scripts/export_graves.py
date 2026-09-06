"""
Headless Blender Python Script: Clean Graves Character Model Export
Usage:
    & "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b -P scripts/export_graves.py
"""

import os
import math
import bpy
import mathutils

def main():
    print("=" * 60)
    print("Starting Clean Graves Character Model Export Pipeline")
    print("=" * 60)

    input_blend = r"C:\Users\start\Downloads\Graves_v3.blend"
    project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    output_glb = os.path.join(project_root, "player", "graves_character.glb")

    os.makedirs(os.path.dirname(output_glb), exist_ok=True)

    print(f"\n[Step 1] Loading source blend file: {input_blend}")
    bpy.ops.wm.open_mainfile(filepath=input_blend)

    # -------------------------------------------------------------
    # 2. Cleanup: Strip extra cameras, lights, and helper meshes
    # -------------------------------------------------------------
    print("\n[Step 2] Cleaning scene objects...")
    meshes_coll = bpy.data.collections.get("Meshes")
    rig_obj = bpy.data.objects.get("Graves_Rig") or bpy.data.objects.get("rig")

    if not meshes_coll or not rig_obj:
        raise RuntimeError("Required collection 'Meshes' or object 'Graves_Rig' not found!")

    valid_objects = set(meshes_coll.objects) | {rig_obj}

    to_delete = [obj for obj in bpy.data.objects if obj not in valid_objects]
    print(f"  Removing {len(to_delete)} non-character objects (helpers, lights, shapes)...")
    for obj in to_delete:
        bpy.data.objects.remove(obj, do_unlink=True)

    # Link rig and meshes directly to scene root collection
    scene_coll = bpy.context.scene.collection
    if rig_obj.name not in scene_coll.objects:
        scene_coll.objects.link(rig_obj)
    for m in meshes_coll.objects:
        if m.name not in scene_coll.objects:
            scene_coll.objects.link(m)

    # Unhide everything
    rig_obj.hide_render = False
    rig_obj.hide_viewport = False
    rig_obj.hide_set(False)
    for m in meshes_coll.objects:
        m.hide_render = False
        m.hide_viewport = False
        m.hide_set(False)

    bpy.context.view_layer.update()

    # -------------------------------------------------------------
    # 3. Setup Standard Principled BSDF with Color Textures
    # -------------------------------------------------------------
    print("\n[Step 3] Configuring standard Principled BSDF nodes for glTF export...")
    for mat in bpy.data.materials:
        if not mat.node_tree:
            continue
        
        # Find diffuse color image
        color_img = None
        for n in mat.node_tree.nodes:
            if n.type == 'TEX_IMAGE' and n.image:
                if 'color' in n.image.name.lower():
                    color_img = n.image
                    break
        
        # If no image with 'color' in name, check any non-ao/non-rough image
        if not color_img:
            for n in mat.node_tree.nodes:
                if n.type == 'TEX_IMAGE' and n.image and 'rough' not in n.image.name.lower() and 'ao' not in n.image.name.lower() and 'norm' not in n.image.name.lower():
                    color_img = n.image
                    break

        if color_img:
            print(f"  Mat '{mat.name}': assigning color texture '{color_img.name}'")
            # Find or create Principled BSDF
            bsdf = None
            for n in mat.node_tree.nodes:
                if n.type == 'BSDF_PRINCIPLED':
                    bsdf = n
                    break
            if not bsdf:
                bsdf = mat.node_tree.nodes.new(type='ShaderNodeBsdfPrincipled')
                bsdf.location = (0, 0)
            
            # Find or create Image Texture node connected to Base Color
            tex_node = mat.node_tree.nodes.new(type='ShaderNodeTexImage')
            tex_node.image = color_img
            tex_node.location = (-300, 0)
            mat.node_tree.links.new(tex_node.outputs['Color'], bsdf.inputs['Base Color'])

            out_node = None
            for n in mat.node_tree.nodes:
                if n.type == 'OUTPUT_MATERIAL':
                    out_node = n
                    break
            if not out_node:
                out_node = mat.node_tree.nodes.new(type='ShaderNodeOutputMaterial')
                out_node.location = (300, 0)
            
            mat.node_tree.links.new(bsdf.outputs['BSDF'], out_node.inputs['Surface'])

    # -------------------------------------------------------------
    # 4. Measure & Rescale Character to 1.75m with Boots at Z = 0.0
    # -------------------------------------------------------------
    print("\n[Step 4] Rescaling character to ~1.75m height grounded at Z = 0.0...")
    bpy.context.view_layer.update()

    min_z = 999999.0
    max_z = -999999.0
    for obj in meshes_coll.objects:
        if obj.type == 'MESH':
            for c in obj.bound_box:
                world_c = obj.matrix_world @ mathutils.Vector(c)
                min_z = min(min_z, world_c.z)
                max_z = max(max_z, world_c.z)

    current_height = max_z - min_z
    target_height = 1.75
    scale_factor = target_height / current_height
    print(f"  Initial character height: {current_height:.4f}m (Z min: {min_z:.4f}m, max: {max_z:.4f}m)")
    print(f"  Applying scale factor: {scale_factor:.6f}")

    rig_obj.scale = rig_obj.scale * scale_factor
    bpy.context.view_layer.update()

    # Re-measure
    min_z_new = 999999.0
    max_z_new = -999999.0
    for obj in meshes_coll.objects:
        if obj.type == 'MESH':
            for c in obj.bound_box:
                world_c = obj.matrix_world @ mathutils.Vector(c)
                min_z_new = min(min_z_new, world_c.z)
                max_z_new = max(max_z_new, world_c.z)

    # Offset rig if boots not at 0.0
    if abs(min_z_new) > 0.002:
        rig_obj.location.z -= min_z_new
        bpy.context.view_layer.update()
        min_z_new -= min_z_new

    print(f"  Final character height: {max_z_new - min_z_new:.4f}m (Z min: {min_z_new:.4f}m, max: {max_z_new:.4f}m)")
    print(f"  Boots pivot: Z = {rig_obj.location.z:.4f}m")

    # -------------------------------------------------------------
    # 5. Create Loopable Idle and Walk Animations
    # -------------------------------------------------------------
    print("\n[Step 5] Generating loopable Idle and Walk animations...")
    bpy.context.view_layer.objects.active = rig_obj
    rig_obj.select_set(True)

    # Ensure animation data
    if not rig_obj.animation_data:
        rig_obj.animation_data_create()

    # 5a. Idle Animation (60 frames, 30 fps = 2.0s loop)
    idle_action = bpy.data.actions.new(name="idle")
    rig_obj.animation_data.action = idle_action

    key_bones = {
        "spine_0": ("rotation_euler", [(0, (0, 0, 0)), (30, (0.015, 0, 0)), (60, (0, 0, 0))]),
        "spine_1": ("rotation_euler", [(0, (0, 0, 0)), (30, (0.02, 0, 0)), (60, (0, 0, 0))]),
        "neck": ("rotation_euler", [(0, (0, 0, 0)), (30, (-0.01, 0, 0)), (60, (0, 0, 0))]),
        "head": ("rotation_euler", [(0, (0, 0, 0)), (30, (-0.01, 0, 0)), (60, (0, 0, 0))]),
        "arm_L": ("rotation_euler", [(0, (0, 0, 0)), (30, (0, 0, 0.02)), (60, (0, 0, 0))]),
        "arm_R": ("rotation_euler", [(0, (0, 0, 0)), (30, (0, 0, -0.02)), (60, (0, 0, 0))]),
    }

    for bname, (prop, kfs) in key_bones.items():
        pbone = rig_obj.pose.bones.get(bname)
        if not pbone:
            continue
        pbone.rotation_mode = 'XYZ'
        for frame, val in kfs:
            pbone.rotation_euler = val
            pbone.keyframe_insert(data_path="rotation_euler", frame=frame)

    # Push idle to NLA track
    idle_track = rig_obj.animation_data.nla_tracks.new()
    idle_track.name = "idle_track"
    idle_strip = idle_track.strips.new("idle", 0, idle_action)
    idle_strip.action = idle_action

    # 5b. Walk Animation (30 frames, 30 fps = 1.0s loop)
    walk_action = bpy.data.actions.new(name="walk")
    rig_obj.animation_data.action = walk_action

    walk_bones = {
        "pelvis": ("location", [
            (0, (0, 0, 0)),
            (7.5, (0, 0, -0.01)),
            (15, (0, 0, 0)),
            (22.5, (0, 0, -0.01)),
            (30, (0, 0, 0))
        ]),
        "leg_L": ("rotation_euler", [
            (0, (0.35, 0, 0)),
            (7.5, (0.0, 0, 0)),
            (15, (-0.35, 0, 0)),
            (22.5, (0.1, 0, 0)),
            (30, (0.35, 0, 0))
        ]),
        "leg_R": ("rotation_euler", [
            (0, (-0.35, 0, 0)),
            (7.5, (0.1, 0, 0)),
            (15, (0.35, 0, 0)),
            (22.5, (0.0, 0, 0)),
            (30, (-0.35, 0, 0))
        ]),
        "knee_L": ("rotation_euler", [
            (0, (0.0, 0, 0)),
            (7.5, (0.45, 0, 0)),
            (15, (0.05, 0, 0)),
            (22.5, (0.1, 0, 0)),
            (30, (0.0, 0, 0))
        ]),
        "knee_R": ("rotation_euler", [
            (0, (0.05, 0, 0)),
            (7.5, (0.1, 0, 0)),
            (15, (0.0, 0, 0)),
            (22.5, (0.45, 0, 0)),
            (30, (0.05, 0, 0))
        ]),
        "arm_L": ("rotation_euler", [
            (0, (-0.25, 0, 0)),
            (15, (0.25, 0, 0)),
            (30, (-0.25, 0, 0))
        ]),
        "arm_R": ("rotation_euler", [
            (0, (0.25, 0, 0)),
            (15, (-0.25, 0, 0)),
            (30, (0.25, 0, 0))
        ]),
    }

    for bname, (prop, kfs) in walk_bones.items():
        pbone = rig_obj.pose.bones.get(bname)
        if not pbone:
            continue
        pbone.rotation_mode = 'XYZ'
        for frame, val in kfs:
            if prop == "location":
                pbone.location = val
                pbone.keyframe_insert(data_path="location", frame=frame)
            elif prop == "rotation_euler":
                pbone.rotation_euler = val
                pbone.keyframe_insert(data_path="rotation_euler", frame=frame)

    # Push walk to NLA track
    walk_track = rig_obj.animation_data.nla_tracks.new()
    walk_track.name = "walk_track"
    walk_strip = walk_track.strips.new("walk", 0, walk_action)
    walk_strip.action = walk_action

    # -------------------------------------------------------------
    # 6. Export to glTF Binary (.glb)
    # -------------------------------------------------------------
    print(f"\n[Step 6] Exporting glTF binary to: {output_glb}")

    # Select rig and meshes for export
    bpy.ops.object.select_all(action='DESELECT')
    rig_obj.select_set(True)
    for m in meshes_coll.objects:
        m.select_set(True)

    bpy.ops.export_scene.gltf(
        filepath=output_glb,
        export_format='GLB',
        use_selection=True,
        export_apply=False,
        export_animations=True,
        export_nla_strips=True,
        export_materials='EXPORT',
        export_image_format='AUTO'
    )

    print(f"Export completed! File size: {os.path.getsize(output_glb) / (1024*1024):.2f} MB")
    print("=" * 60)

if __name__ == "__main__":
    main()
