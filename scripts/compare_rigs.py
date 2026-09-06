import bpy

path_blend = r"C:\Users\start\Downloads\Graves_v3.blend"
bpy.ops.wm.open_mainfile(filepath=path_blend)
blend_bone_names = set(b.name for b in bpy.data.objects['Graves_Rig'].data.bones)

path_fbx = r"c:\Workspace\I-wish-I-could-dream-again-\player\animations\idle.fbx"
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=path_fbx)
fbx_bone_names = set(b.name for b in bpy.data.objects['Graves_Rig'].data.bones)

print("In both:", len(blend_bone_names.intersection(fbx_bone_names)))
print("In blend only:", len(blend_bone_names - fbx_bone_names), list(blend_bone_names - fbx_bone_names)[:5])
print("In fbx only:", len(fbx_bone_names - blend_bone_names), list(fbx_bone_names - blend_bone_names)[:5])
