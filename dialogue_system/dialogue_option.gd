class_name DialogueOption extends PanelContainer

signal option_selected

enum OptionType {
	REGULAR,
	RED,
	WHITE,
}

const NORMAL_COLOR = Color("#c2512bff")
const SELECTED_COLOR = Color("#ffffff")

const CHECK_COLOR = Color(0.094, 0.094, 0.094, 1.0)

const RED_BG = Color("#c6512e")
const RED_BG_SELETED = Color("8a3820ff")
const WHITE_BG = Color("#847f71")
const WHITE_BG_SELECTED = Color("57534bff")
const TRANSPARENT_BG = Color("#ffffff00")

@onready var _number: Label = $HBoxContainer/opt_number
@onready var _button: Button = $HBoxContainer/opt_label

var _option_type: OptionType = OptionType.REGULAR

var _is_selected: bool = false

func set_option(index: int, option: Dictionary) -> void:
	_number.text = "%s." % (index + 1)
	_button.text = option.text
	if option.visited:
		self.modulate.a = 0.7

	if option.tags.has("white-check"):
		_option_type = OptionType.WHITE

	if option.tags.has("red-check"):
		_option_type = OptionType.RED

	_set_style(false)


func _on_opt_label_pressed() -> void:
	option_selected.emit()


func set_selected(is_selected: bool) -> void:
	_is_selected = is_selected
	_set_style(is_selected)


func set_bg_color(colour: Color) -> void:
	var panel = self.get_theme_stylebox("panel")
	panel.bg_color = colour


func set_font_color(colour: Color) -> void:
	_button.add_theme_color_override("font_color", colour)


func _on_opt_label_mouse_entered() -> void:
	if not _is_selected:
		_set_style(true)


func _on_opt_label_mouse_exited() -> void:
	if not _is_selected:
		_set_style(false)


func _set_style(is_selected: bool) -> void:
	if is_selected:
		set_font_color(SELECTED_COLOR)
		match _option_type:
			OptionType.RED:
				set_bg_color(RED_BG_SELETED)
			OptionType.WHITE:
				set_bg_color(WHITE_BG_SELECTED)
			_:
				set_bg_color(TRANSPARENT_BG)
	else:
		match _option_type:
			OptionType.RED:
				set_bg_color(RED_BG)
				set_font_color(CHECK_COLOR)
			OptionType.WHITE:
				set_bg_color(WHITE_BG)
				set_font_color(CHECK_COLOR)
			_:
				set_bg_color(TRANSPARENT_BG)
				set_font_color(NORMAL_COLOR)
