extends RefCounted

func handle_passive_check(_passive_check_name: String) -> CheckResult:
	return CheckResult.new(true, CheckResult.Difficulty.EASY)
