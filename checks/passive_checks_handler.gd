extends RefCounted


func handle_passive_check(passive_check_name: String) -> CheckResult:
	if passive_check_name == "passive_check_123":
		var value = "limbic" if randf() > 0.5 else "inland"
		return CheckResult.new(true, CheckResult.Difficulty.MEDIUM, value)
	if passive_check_name.begins_with("passive_check_intro_"): # pass all intro dialogue checks
		return CheckResult.new(true, CheckResult.Difficulty.EASY)
	return CheckResult.new(false, CheckResult.Difficulty.EASY)
