class_name DialogueEntry extends MarginContainer

signal option_selected(index: int)

const DialogueOptionScene = preload("res://dialogue_system/dialogue_option.tscn")

@onready var _text: RichTextLabel = $VBoxContainer/RichTextLabel
@onready var _options_list: Control = $VBoxContainer/options

var _option_selected: int = 0

var _options: Array = []

func set_content(speaker: Speaker, text: String, passive_check: String = "") -> void:
	if speaker.speaker_name == "":
		_text.text = text
		return

	if speaker.speaker_name == "<same>":
		_text.text = "[indent]%s" % text
		return

	var speaker_name = speaker.get_speaker_name().to_upper()

	var raw_speaker_block = "%s%s — " % [
		speaker_name,
		"" if passive_check == "" else " %s" % passive_check,
	]

	var raw_content = "%s%s" % [
		raw_speaker_block,
		text,
	]

	_text.text = raw_content

	await get_tree().process_frame

	var content = _text.text

	if _text.get_line_count() > 1:
		var r = _text.get_line_range(0)
		var indent_position = r.y + 1
		if indent_position < raw_speaker_block.length():
			indent_position = raw_speaker_block.length()
		content = content.insert(indent_position, "[indent]")

	content = content.substr(raw_speaker_block.length())
	var speaker_info = "[color=#%s]%s[/color]%s —" % [
		speaker.get_speaker_color(),
		speaker_name,
		"" if passive_check == "" else " [color=#636056]%s[/color]" % passive_check,
	]
	_text.text = "%s %s" % [ speaker_info, content ]


func set_options(options: Array[Dictionary]) -> void:
	_options = options
	_options_list.show()
	var index: int = 0
	for option in options:
		var o: DialogueOption = DialogueOptionScene.instantiate()
		_options_list.add_child(o)
		o.set_option(index, option)
		o.option_selected.connect(func():
			option_selected.emit(index)
		)
		index += 1
	select_option(0)


func select_option(index: int) -> void:
	_options_list.get_child(_option_selected).set_selected(false)
	_options_list.get_child(index).set_selected(true)
	_option_selected = index


func mark_as_read() -> void:
	self.modulate.a = 0.4
	_options_list.hide()


func get_option_data(index: int) -> Dictionary:
	return _options[index]


func get_number_of_options() -> int:
	return _options.size()
