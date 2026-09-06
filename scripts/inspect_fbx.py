import bpy

for fbx_name in ["idle.fbx", "run.fbx"]:
    path = f"c:/Workspace/I-wish-I-could-dream-again-/player/animations/{fbx_name}"
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=path)
    print(f"=== {fbx_name} ===")
    print("Objects:", [o.name for o in bpy.data.objects])
    print("Actions:", [a.name for a in bpy.data.actions])
    for a in bpy.data.actions:
        print(f"  Action {a.name}: frame_range={a.frame_range}, length={a.frame_range[1] - a.frame_range[0]}")
