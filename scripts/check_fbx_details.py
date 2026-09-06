import bpy

# Load idle.fbx
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=r"C:\Users\start\Downloads\Graves_v3@Neutral Idle.fbx")

print("=== IDLE.FBX ===")
for obj in bpy.data.objects:
    print("Object:", obj.name, obj.type)
    if obj.type == 'ARMATURE':
        print("Bones:", len(obj.data.bones))
        print("Root bone:", [b.name for b in obj.data.bones if b.parent is None])

print("Actions:", [a.name for a in bpy.data.actions])

# Load running.fbx
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=r"C:\Users\start\Downloads\Graves_v3@Running.fbx")

print("\n=== RUNNING.FBX ===")
for obj in bpy.data.objects:
    print("Object:", obj.name, obj.type)
    if obj.type == 'ARMATURE':
        print("Bones:", len(obj.data.bones))
        print("Root bone:", [b.name for b in obj.data.bones if b.parent is None])

print("Actions:", [a.name for a in bpy.data.actions])
