class_name Speaker extends Resource

@export
var speaker_name: String = ""

@export
var speaker_color: Color = Color(1, 1, 1)

@export_file
var portrait_path: String

func get_speaker_name() -> String:
	return tr(speaker_name)


func get_speaker_color() -> String:
	return speaker_color.to_html()
