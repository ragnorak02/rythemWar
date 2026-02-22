extends RefCounted
## TestSuite — unit tests for RhythmWar core systems.

var _total: int = 0
var _passed: int = 0
var _failures: int = 0
var _details: Array = []

func run_all() -> Dictionary:
	_total = 0
	_passed = 0
	_failures = 0
	_details = []

	# Judgment tests
	_test_judgment_perfect()
	_test_judgment_great()
	_test_judgment_good()
	_test_judgment_bad()
	_test_judgment_miss()
	_test_judgment_symmetry()

	# Combo tests
	_test_combo_keeps_on_perfect()
	_test_combo_keeps_on_great()
	_test_combo_keeps_on_good()
	_test_combo_breaks_on_bad()
	_test_combo_breaks_on_miss()

	# Score tests
	_test_score_values()

	# Damage multiplier tests
	_test_damage_multiplier_perfect()
	_test_damage_multiplier_miss()

	# Chart data tests
	_test_chart_sort_order()
	_test_chart_required_fields()

	return {
		"total": _total,
		"passed": _passed,
		"failures": _failures,
		"details": _details,
	}

func _assert(condition: bool, test_name: String, message: String = "") -> void:
	_total += 1
	if condition:
		_passed += 1
		_details.append({"name": test_name, "status": "passed"})
	else:
		_failures += 1
		_details.append({"name": test_name, "status": "failed", "message": message})

# --- Judgment Window Tests ---

func _test_judgment_perfect() -> void:
	var grade := Judgment.evaluate(5.0, 5.03)  # 30ms diff
	_assert(grade == Judgment.GRADE_PERFECT, "judgment_perfect_within_window",
		"Expected PERFECT for 30ms diff, got %s" % grade)

func _test_judgment_great() -> void:
	var grade := Judgment.evaluate(5.0, 5.06)  # 60ms diff
	_assert(grade == Judgment.GRADE_GREAT, "judgment_great_within_window",
		"Expected GREAT for 60ms diff, got %s" % grade)

func _test_judgment_good() -> void:
	var grade := Judgment.evaluate(5.0, 5.10)  # 100ms diff
	_assert(grade == Judgment.GRADE_GOOD, "judgment_good_within_window",
		"Expected GOOD for 100ms diff, got %s" % grade)

func _test_judgment_bad() -> void:
	var grade := Judgment.evaluate(5.0, 5.13)  # 130ms diff
	_assert(grade == Judgment.GRADE_BAD, "judgment_bad_within_window",
		"Expected BAD for 130ms diff, got %s" % grade)

func _test_judgment_miss() -> void:
	var grade := Judgment.evaluate(5.0, 5.20)  # 200ms diff
	_assert(grade == Judgment.GRADE_MISS, "judgment_miss_beyond_window",
		"Expected MISS for 200ms diff, got %s" % grade)

func _test_judgment_symmetry() -> void:
	var grade_early := Judgment.evaluate(5.05, 5.0)  # Early hit
	var grade_late := Judgment.evaluate(5.0, 5.05)   # Late hit
	_assert(grade_early == grade_late, "judgment_symmetry_early_late",
		"Expected same grade for early/late, got %s vs %s" % [grade_early, grade_late])

# --- Combo Tests ---

func _test_combo_keeps_on_perfect() -> void:
	_assert(Judgment.keeps_combo(Judgment.GRADE_PERFECT), "combo_keeps_on_perfect")

func _test_combo_keeps_on_great() -> void:
	_assert(Judgment.keeps_combo(Judgment.GRADE_GREAT), "combo_keeps_on_great")

func _test_combo_keeps_on_good() -> void:
	_assert(Judgment.keeps_combo(Judgment.GRADE_GOOD), "combo_keeps_on_good")

func _test_combo_breaks_on_bad() -> void:
	_assert(not Judgment.keeps_combo(Judgment.GRADE_BAD), "combo_breaks_on_bad")

func _test_combo_breaks_on_miss() -> void:
	_assert(not Judgment.keeps_combo(Judgment.GRADE_MISS), "combo_breaks_on_miss")

# --- Score Tests ---

func _test_score_values() -> void:
	_assert(Judgment.SCORE_VALUES[Judgment.GRADE_PERFECT] == 300, "score_perfect_300")
	_assert(Judgment.SCORE_VALUES[Judgment.GRADE_GREAT] == 200, "score_great_200")
	_assert(Judgment.SCORE_VALUES[Judgment.GRADE_GOOD] == 100, "score_good_100")
	_assert(Judgment.SCORE_VALUES[Judgment.GRADE_BAD] == 50, "score_bad_50")
	_assert(Judgment.SCORE_VALUES[Judgment.GRADE_MISS] == 0, "score_miss_0")

# --- Damage Multiplier Tests ---

func _test_damage_multiplier_perfect() -> void:
	var mult := Judgment.get_damage_multiplier(Judgment.GRADE_PERFECT)
	_assert(mult == 1.5, "damage_mult_perfect_1.5",
		"Expected 1.5, got %f" % mult)

func _test_damage_multiplier_miss() -> void:
	var mult := Judgment.get_damage_multiplier(Judgment.GRADE_MISS)
	_assert(mult == 0.25, "damage_mult_miss_0.25",
		"Expected 0.25 (soft failure), got %f" % mult)

# --- Chart Data Tests ---

func _test_chart_sort_order() -> void:
	var file := FileAccess.open("res://data/charts/stage_easy_01.json", FileAccess.READ)
	if not file:
		_assert(false, "chart_file_exists", "Could not open easy chart")
		return
	var data: Dictionary = JSON.parse_string(file.get_as_text())
	file.close()

	var notes: Array = data.get("notes", [])
	var sorted := true
	for i in range(1, notes.size()):
		if notes[i]["time"] < notes[i - 1]["time"]:
			sorted = false
			break
	_assert(sorted, "chart_notes_sorted_by_time")

func _test_chart_required_fields() -> void:
	var file := FileAccess.open("res://data/charts/stage_easy_01.json", FileAccess.READ)
	if not file:
		_assert(false, "chart_required_fields_file", "Could not open chart")
		return
	var data: Dictionary = JSON.parse_string(file.get_as_text())
	file.close()

	_assert(data.has("stage_id"), "chart_has_stage_id")
	_assert(data.has("bpm"), "chart_has_bpm")
	_assert(data.has("notes"), "chart_has_notes")
	_assert(data["notes"].size() > 0, "chart_has_notes_non_empty")
