extends Node
## GameManager — global session state for the current play session.

# Current session state
var selected_stage: String = ""
var selected_chart: Dictionary = {}
var is_2p: bool = false
var current_scene_path: String = ""

# Player data (populated by SaveManager on load)
var high_scores: Dictionary = {}  # stage_id -> int
var max_combos: Dictionary = {}   # stage_id -> int
var stages_cleared: Array[String] = []
var total_battles: int = 0
var total_perfects: int = 0
var settings: Dictionary = {
	"master_volume": 1.0,
	"sfx_volume": 1.0,
	"music_volume": 1.0,
	"input_offset_ms": 0.0,
}

# Last battle results (for results screen)
var last_results: Dictionary = {}

func _ready() -> void:
	Events.scene_change_requested.connect(_on_scene_change_requested)

func change_scene(scene_path: String) -> void:
	current_scene_path = scene_path
	get_tree().change_scene_to_file(scene_path)

func _on_scene_change_requested(scene_path: String) -> void:
	change_scene(scene_path)

func record_battle_result(stage_id: String, score: int, max_combo: int, won: bool) -> void:
	total_battles += 1
	if won and stage_id not in stages_cleared:
		stages_cleared.append(stage_id)
	if not high_scores.has(stage_id) or score > high_scores[stage_id]:
		high_scores[stage_id] = score
	if not max_combos.has(stage_id) or max_combo > max_combos[stage_id]:
		max_combos[stage_id] = max_combo
