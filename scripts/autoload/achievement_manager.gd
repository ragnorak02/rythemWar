extends Node
## AchievementManager — loads achievements from JSON, tracks progress, fires unlock signals.

var _achievements: Array = []
var _unlocked: Dictionary = {}  # achievement_id -> bool
var _battle_counters: Dictionary = {}  # reset each battle

func _ready() -> void:
	_load_achievements()
	Events.battle_started.connect(_on_battle_started)
	Events.battle_ended.connect(_on_battle_ended)
	Events.judgment_made.connect(_on_judgment_made)
	Events.combo_broken.connect(_on_combo_broken)

func _load_achievements() -> void:
	var file := FileAccess.open("res://achievements.json", FileAccess.READ)
	if file:
		var data: Dictionary = JSON.parse_string(file.get_as_text())
		file.close()
		if data.has("achievements"):
			_achievements = data["achievements"]
	for ach in _achievements:
		_unlocked[ach["id"]] = false

func is_unlocked(achievement_id: String) -> bool:
	return _unlocked.get(achievement_id, false)

func get_achievements() -> Array:
	return _achievements

func load_unlocked_state(unlocked_dict: Dictionary) -> void:
	for key in unlocked_dict:
		_unlocked[key] = unlocked_dict[key]

func get_unlocked_state() -> Dictionary:
	return _unlocked.duplicate()

func _on_battle_started(_stage_id: String) -> void:
	_battle_counters = {
		"perfects": 0,
		"combo": 0,
		"blocks": 0,
		"super_strikes": 0,
		"misses": 0,
		"total_notes": 0,
	}

func _on_judgment_made(player_id: int, grade: String, combo: int, note_type: String) -> void:
	_battle_counters["total_notes"] = _battle_counters.get("total_notes", 0) + 1

	if grade == Judgment.GRADE_PERFECT:
		_battle_counters["perfects"] = _battle_counters.get("perfects", 0) + 1
		_check_achievement("perfect_storm", _battle_counters["perfects"])

	if combo > _battle_counters.get("combo", 0):
		_battle_counters["combo"] = combo
		_check_achievement("combo_master", combo)

func _on_combo_broken(_player_id: int, final_combo: int) -> void:
	pass

func _on_battle_ended(winner: String) -> void:
	if winner == "player":
		GameManager.total_battles += 1
		_check_achievement("first_beat", 1)

		# Flawless victory check
		var results := GameManager.last_results
		if results.get("accuracy", 0.0) >= 100.0:
			_check_achievement("flawless_victory", 1)

		# War drum — check stages cleared
		_check_achievement("war_drum", GameManager.stages_cleared.size())

	# 2P battle check
	if GameManager.is_2p:
		_check_achievement("duo_harmony", 1)

func track_block() -> void:
	_battle_counters["blocks"] = _battle_counters.get("blocks", 0) + 1
	_check_achievement("iron_defense", _battle_counters["blocks"])

func track_super_strike() -> void:
	_battle_counters["super_strikes"] = _battle_counters.get("super_strikes", 0) + 1
	_check_achievement("super_striker", _battle_counters["super_strikes"])

func _check_achievement(achievement_id: String, current_value: int) -> void:
	if _unlocked.get(achievement_id, false):
		return

	for ach in _achievements:
		if ach["id"] == achievement_id:
			if current_value >= ach["target"]:
				_unlock(achievement_id, ach["title"])
			else:
				Events.achievement_progress.emit(achievement_id, current_value, ach["target"])
			break

func _unlock(achievement_id: String, title: String) -> void:
	_unlocked[achievement_id] = true
	Events.achievement_unlocked.emit(achievement_id, title)
