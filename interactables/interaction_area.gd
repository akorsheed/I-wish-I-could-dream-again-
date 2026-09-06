extends Area3D

signal interacted

@export var prompt_text: String = "[E] Inspect Case Notes"
## 3D height offset above the interaction area origin where the 2D floating HUD pill anchors
@export var prompt_offset_3d: Vector3 = Vector3(0.0, 1.8, 0.0)

var player_in_range: bool = false
var _camera: Camera3D
var _prompt_ui: Control
var _prompt_label: Label

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Hide legacy 3D label so it doesn't render blurred under post-processing
	var legacy_label = get_node_or_null("PromptLabel")
	if legacy_label:
		legacy_label.visible = false
		
	_resolve_prompt_ui()

func _resolve_prompt_ui() -> void:
	if not _prompt_ui:
		_prompt_ui = get_tree().root.find_child("InteractionPrompt", true, false) as Control
		if _prompt_ui:
			_prompt_label = _prompt_ui.find_child("Label", true, false) as Label
			_prompt_ui.visible = false

func _process(_delta: float) -> void:
	if not player_in_range:
		return

	if Input.is_action_just_pressed("interact") or Input.is_physical_key_pressed(KEY_E):
		interacted.emit()

	# Position the 2D HUD pill right above the 3D desk/interaction object in screen space
	if _prompt_ui and _prompt_ui.visible:
		_update_prompt_position()

func _update_prompt_position() -> void:
	if not is_instance_valid(_camera):
		_camera = get_viewport().get_camera_3d()
	if is_instance_valid(_camera) and _prompt_ui:
		var screen_pos = _camera.unproject_position(global_position + prompt_offset_3d)
		_prompt_ui.global_position = screen_pos - (_prompt_ui.size * 0.5)

func _on_body_entered(body: Node3D) -> void:
	if body.name == "Player" or body is CharacterBody3D:
		player_in_range = true
		_resolve_prompt_ui()
		if _prompt_ui:
			if _prompt_label:
				_prompt_label.text = prompt_text
			_prompt_ui.visible = true
			_update_prompt_position()

func _on_body_exited(body: Node3D) -> void:
	if body.name == "Player" or body is CharacterBody3D:
		player_in_range = false
		if _prompt_ui:
			_prompt_ui.visible = false
