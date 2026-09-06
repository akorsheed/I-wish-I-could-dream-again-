extends MarginContainer

signal dialogue_ended
signal active_check_started
signal active_check_ended

const SPEAKER_RESOURCES_FOLDER: String = "res://speakers/"

const DialogueEntryScene = preload("res://dialogue_system/dialogue_entry.tscn")
const DialogueEndScene = preload("res://dialogue_system/end_button.tscn")

var game_data = preload("res://data/game_data.gd").new()

@onready var _dialogue_entries_container: Control = $PanelContainer/ScrollContainer/inner_container/dialogue_entries
@onready var _scroll_container: ScrollContainer = $PanelContainer/ScrollContainer
@onready var _scroll_bar: ScrollBar = _scroll_container.get_v_scroll_bar()

@onready var _speaker_picture_container: PanelContainer = $PortraitContainer/PanelContainer
@onready var _speaker_picture: TextureRect = $PortraitContainer/PanelContainer/TextureRect

@onready var _continue_button: Button = $PanelContainer/ScrollContainer/inner_container/ContinueButton

var _is_waiting_for_choice: bool = false
var _has_ended: bool = false

var _last_speaker: String = ""
var _current_option: int = 0

var _current_dialogue_name: String = ""
var _dialogue: ClydeDialogue

var _last_entry: DialogueEntry

func _ready() -> void:
	_scroll_bar.changed.connect(_on_scroll_bar_changed)

func start(dialogue_name: String) -> void:
	_reset_state()
	_current_dialogue_name = dialogue_name
	_dialogue = ClydeDialogue.new()
	_dialogue.load_dialogue(dialogue_name)

	# Design Blueprint: All mental voices and passive checks pass linearly without RNG checks
	_dialogue.on_external_variable_fetch(func(variable_name: String):
		if variable_name.begins_with("passive_check"):
			return true

		if variable_name == "active_check_result":
			return true

		return game_data.get_variable(variable_name)
	)

	_dialogue.on_external_variable_update(func(variable_name: String, value):
		game_data.set_variable(variable_name, value)
	)

	_dialogue.event_triggered.connect(_on_event_triggered)
	
	var dialogue_data = game_data.get_dialogue_data(dialogue_name)
	if dialogue_data:
		_dialogue.load_data(dialogue_data)

	next()

func _reset_state() -> void:
	_has_ended = false
	_last_speaker = ""
	_current_option = 0
	_clear_entries()

func next() -> void:
	if _has_ended:
		dialogue_ended.emit()
		return

	if _is_waiting_for_choice:
		_select_option(_current_option)
		return

	var content = _dialogue.get_content()
	_mark_last_entry_as_read()

	match content.type:
		ClydeDialogue.CONTENT_TYPE_LINE:
			_handle_line(content)
		ClydeDialogue.CONTENT_TYPE_OPTIONS:
			_handle_options(content)
		ClydeDialogue.CONTENT_TYPE_END:
			_handle_end()

func _handle_line(content: Dictionary) -> void:
	# Ignore active-check-start tags so dialogue flows continuously and linearly
	if content.tags.has("active-check-start"):
		next()
		return

	_add_line(content)

	if content.tags.has("end"):
		_handle_end()
	else:
		_continue_button.modulate.a = 1.0
		_continue_button.show()

func _handle_options(content: Dictionary) -> void:
	_add_options_entry(content)
	_is_waiting_for_choice = true
	_continue_button.modulate.a = 0.0

func _handle_end() -> void:
	_add_dialogue_end_entry()
	_continue_button.modulate.a = 0.0
	_continue_button.hide()
	game_data.store_dialogue_data(_current_dialogue_name, _dialogue.get_data())

func _add_line(content: Dictionary) -> void:
	var entry: DialogueEntry = _create_entry(content)
	_last_entry = entry

func _add_options_entry(content: Dictionary) -> void:
	var entry: DialogueEntry = _create_entry(content)
	var options: Array[Dictionary] = []
	options.append_array(content.options)
	entry.set_options(options)
	entry.option_selected.connect(_on_option_clicked)
	_last_entry = entry

func _create_entry(content: Dictionary) -> DialogueEntry:
	var entry: DialogueEntry = DialogueEntryScene.instantiate()
	_dialogue_entries_container.add_child(entry)
	var speaker_resource = _get_speaker_resource(content.speaker)
	entry.set_content(speaker_resource, "" if content.text == null else content.text, "")

	if speaker_resource.portrait_path != "" and ResourceLoader.exists(speaker_resource.portrait_path):
		_speaker_picture_container.show()
		_speaker_picture.texture = load(speaker_resource.portrait_path)
	else:
		_speaker_picture_container.hide()

	return entry

func _add_dialogue_end_entry() -> void:
	var button: Button = DialogueEndScene.instantiate()
	button.pressed.connect(func():
		dialogue_ended.emit()
	)
	_dialogue_entries_container.add_child(button)
	_has_ended = true

func next_option() -> void:
	if not _is_waiting_for_choice:
		return

	if _current_option >= _last_entry.get_number_of_options() - 1:
		return

	_current_option += 1
	_last_entry.select_option(_current_option)

func previous_option() -> void:
	if not _is_waiting_for_choice:
		return

	if _current_option == 0:
		return
	_current_option -= 1
	_last_entry.select_option(_current_option)

func _get_speaker_resource(speaker_name) -> Speaker:
	var speaker = Speaker.new()

	if speaker_name == null:
		return speaker

	var speaker_path = "%s%s.tres" % [SPEAKER_RESOURCES_FOLDER, speaker_name]

	if ResourceLoader.exists(speaker_path):
		speaker = load(speaker_path)
	else:
		speaker.speaker_name = speaker_name

	if speaker_name == _last_speaker:
		speaker.speaker_name = "<same>"

	_last_speaker = speaker_name
	return speaker

func _on_scroll_bar_changed() -> void:
	var scroll_value = _scroll_bar.max_value
	if scroll_value != _scroll_container.scroll_vertical:
		@warning_ignore("narrowing_conversion")
		_scroll_container.scroll_vertical = scroll_value

func _on_option_clicked(index: int) -> void:
	_current_option = index
	_select_option(index)

func _select_option(index: int) -> void:
	_is_waiting_for_choice = false
	_dialogue.choose(index)
	_mark_last_entry_as_read()
	_add_line(_last_entry.get_option_data(_current_option))
	_current_option = 0
	next()

func _mark_last_entry_as_read() -> void:
	if _last_entry != null:
		_last_entry.mark_as_read()

func _clear_entries() -> void:
	for c in _dialogue_entries_container.get_children():
		c.queue_free()

func _on_event_triggered(event_name: String, _params: Array) -> void:
	if event_name == "active_check":
		# In our linear narrative blueprint, checks resolve immediately without pausing or rolling dice
		next()

func _on_continue_button_pressed() -> void:
	if _continue_button.modulate.a == 0.0:
		return
	next()
