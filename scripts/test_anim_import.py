import bpy

path_fbx = r"C:\Users\start\Downloads\Graves_v3@Neutral Idle.fbx"
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=path_fbx)
for a in bpy.data.actions:
    print("Action name:", a.name)
    print("Action dir:", [x for x in dir(a) if not x.startswith('_')])
    if hasattr(a, 'fcurves'):
        print("fcurves length:", len(a.fcurves))
    elif hasattr(a, 'curves'):
        print("curves length:", len(a.curves))
