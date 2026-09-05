extends Area3D

signal interacted

@export var prompt_text: String = "[E] Inspect Desk"
@onready var prompt_label: Label3D = $PromptLabel

var player_in_range: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if prompt_label:
		prompt_label.text = prompt_text
		prompt_label.visible = false

func _process(_delta: float) -> void:
	if not player_in_range:
		return

	if Input.is_action_just_pressed("interact") or Input.is_physical_key_pressed(KEY_E):
		# Trigger interaction
		interacted.emit()

func _on_body_entered(body: Node3D) -> void:
	if body.name == "Player" or body is CharacterBody3D:
		player_in_range = true
		if prompt_label:
			prompt_label.visible = true

func _on_body_exited(body: Node3D) -> void:
	if body.name == "Player" or body is CharacterBody3D:
		player_in_range = false
		if prompt_label:
			prompt_label.visible = false
