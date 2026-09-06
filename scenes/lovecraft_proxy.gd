@tool
extends Node3D

@export var material: Material = preload("res://materials/blockout_material.tres")

const FOREGROUND_WALLS = ["Wall_SW_Proxy", "Wall_SE_North_Proxy", "Wall_SE_South_Proxy"]

func _ready() -> void:
	_setup_proxies()

func _setup_proxies() -> void:
	for child in get_children():
		# Remove foreground wall segments (Cutaway Dollhouse View)
		if child.name in FOREGROUND_WALLS or child.name.begins_with("Wall_SW") or child.name.begins_with("Wall_SE"):
			child.visible = false
			child.queue_free()
			continue

		if child is MeshInstance3D:
			if child.name == "Desk" or child.name.begins_with("Desk"):
				child.material_override = preload("res://materials/desk_holdout_material.tres")
				child.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			elif material:
				child.material_override = material

			for sub in child.get_children():
				if sub is StaticBody3D:
					sub.collision_layer = 1
					sub.collision_mask = 2
