import bpy

path_fbx = r"C:\Users\start\Downloads\Graves_v3.fbx"
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=path_fbx)
print("Objects in Graves_v3.fbx:", [o.name for o in bpy.data.objects])
print("Meshes in Graves_v3.fbx:", [o.name for o in bpy.data.objects if o.type == 'MESH'])
print("Actions in Graves_v3.fbx:", [a.name for a in bpy.data.actions])
