extends Node
## SaveManager — FileAccess binary persistence at user://rhythmwar_save.dat

const SAVE_PATH := "user://rhythmwar_save.dat"
const SAVE_VERSION := 1

func _ready() -> void:
	load_game()

func save_game() -> void:
	var data := {
		"version": SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"high_scores": GameManager.high_scores,
		"max_combos": GameManager.max_combos,
		"stages_cleared": GameManager.stages_cleared,
		"total_battles": GameManager.total_battles,
		"total_perfects": GameManager.total_perfects,
		"settings": GameManager.settings,
		"achievements_unlocked": AchievementManager.get_unlocked_state(),
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(data)
		file.close()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return

	var data: Variant = file.get_var()
	file.close()

	if data is not Dictionary:
		return

	# Restore state
	if data.has("high_scores"):
		GameManager.high_scores = data["high_scores"]
	if data.has("max_combos"):
		GameManager.max_combos = data["max_combos"]
	if data.has("stages_cleared"):
		GameManager.stages_cleared = data["stages_cleared"]
	if data.has("total_battles"):
		GameManager.total_battles = data["total_battles"]
	if data.has("total_perfects"):
		GameManager.total_perfects = data["total_perfects"]
	if data.has("settings"):
		for key in data["settings"]:
			GameManager.settings[key] = data["settings"][key]
	if data.has("achievements_unlocked"):
		AchievementManager.load_unlocked_state(data["achievements_unlocked"])

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
