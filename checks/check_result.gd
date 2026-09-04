class_name CheckResult extends RefCounted

enum Difficulty {
	EASY,
	MEDIUM,
	HARD
}

var value
var has_succeeded: bool = false
var difficulty: Difficulty = Difficulty.EASY

func _init(check_succeeded: bool, check_difficulty: Difficulty, check_value = null) -> void:
	value = check_value
	has_succeeded = check_succeeded
	difficulty = check_difficulty


func get_display_string() -> String:
	return "[%s: %s]" % [
		Difficulty.keys()[difficulty].capitalize(),
		"Success" if has_succeeded else "Failure"
	]
