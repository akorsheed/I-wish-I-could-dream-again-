extends RefCounted

var last_check_result: CheckResult

func process_active_check(_skill: String, _level: int) -> void:
	last_check_result = CheckResult.new(true, CheckResult.Difficulty.EASY)
