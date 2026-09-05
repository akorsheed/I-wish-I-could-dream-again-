extends Node3D

@onready var _dialogue_drawer = $HUD/DialogueDrawer
@onready var _dialogue_list = $HUD/DialogueList
@onready var _player = get_node_or_null("scene/Player")

var is_dialogue_running: bool = false

func _ready() -> void:
	_dialogue_drawer.hide()
	var desk_area = get_node_or_null("scene/DeskInteractionArea")
	if not desk_area:
		desk_area = get_node_or_null("scene/RoomBlockout/InspectionDesk/InteractionArea")
	if desk_area and not desk_area.interacted.is_connected(_on_desk_interacted):
		desk_area.interacted.connect(_on_desk_interacted)


func _input(event: InputEvent) -> void:
	if not is_dialogue_running:
		return

	if event.is_action_pressed("ui_accept"):
		_dialogue_drawer.next()
	elif event.is_action_pressed("ui_down"):
		_dialogue_drawer.next_option()
	elif event.is_action_pressed("ui_up"):
		_dialogue_drawer.previous_option()


func _on_dialogue_drawer_dialogue_ended() -> void:
	_dialogue_drawer.hide()
	_dialogue_list.show()
	is_dialogue_running = false
	if _player:
		_player.can_move = true


func _on_test_dialogue_button_pressed() -> void:
	_start_dialogue("test")


func _on_intro_dialogue_pressed() -> void:
	_start_dialogue("intro")


func _on_passive_dialogue_pressed() -> void:
	_start_dialogue("passive")


func _on_active_dialogue_pressed() -> void:
	_start_dialogue("active")


func _on_variables_dialogue_button_pressed() -> void:
	_start_dialogue("variables")


func _on_desk_interacted() -> void:
	if not is_dialogue_running:
		_start_dialogue("intro")


func _start_dialogue(dialogue: String) -> void:
	_dialogue_list.hide()
	_dialogue_drawer.show()
	_dialogue_drawer.start(dialogue)
	is_dialogue_running = true
	if _player:
		_player.can_move = false


func _on_dialogue_drawer_active_check_started() -> void:
	$HUD/ActiveCheckAnimation.show()


func _on_dialogue_drawer_active_check_ended() -> void:
	$HUD/ActiveCheckAnimation.hide()


func _on_restart_scene_button_pressed() -> void:
	get_tree().reload_current_scene()
