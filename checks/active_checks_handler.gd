extends RefCounted

var last_check_result: CheckResult

func process_active_check(skill: String, level: int):
	last_check_result = CheckResult.new(randf() > 0.5, CheckResult.Difficulty.EASY)
