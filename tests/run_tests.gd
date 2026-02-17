extends SceneTree
## Headless test runner — runs test suite and outputs JSON results.

func _init() -> void:
	var test_suite = load("res://scripts/tests/test_suite.gd").new()
	var results: Dictionary = test_suite.run_all()

	# Format for launcher contract
	var output := {
		"gameId": "rythemWar",
		"status": "passed" if results["failures"] == 0 else "failed",
		"testsTotal": results["total"],
		"testsPassed": results["passed"],
		"details": results["details"],
	}

	print(JSON.stringify(output))
	quit()
