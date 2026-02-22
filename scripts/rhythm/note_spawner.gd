extends Node
## NoteSpawner — queue-based chart playback.
## Maintains sorted note array and spawn pointer, spawns notes with lookahead.

const LOOKAHEAD_SEC := 2.0  # spawn notes this many seconds before their hit time

var _chart_notes: Array = []  # sorted by time
var _spawn_index: int = 0
var _active_notes: Array = []  # currently visible NoteArrow nodes
var _note_scene: PackedScene = null
var _lane_node: Node2D = null
var _player_id: int = 1

# Unit-based button remapping: maps original chart button -> active unit's button
var _button_remap: Dictionary = {}

func setup(lane: Node2D, player_id: int = 1) -> void:
	_lane_node = lane
	_player_id = player_id
	_note_scene = preload("res://scenes/rhythm/NoteArrow.tscn")

func load_chart(chart_data: Dictionary) -> void:
	for note in _active_notes:
		if is_instance_valid(note):
			note.queue_free()
	_chart_notes.clear()
	_spawn_index = 0
	_active_notes.clear()

	if chart_data.has("notes"):
		_chart_notes = chart_data["notes"].duplicate()
		# Sort by time ascending
		_chart_notes.sort_custom(func(a, b): return a["time"] < b["time"])

func _process(_delta: float) -> void:
	if not Conductor.is_playing():
		return
	_spawn_upcoming_notes()
	_clean_dead_notes()

func _spawn_upcoming_notes() -> void:
	while _spawn_index < _chart_notes.size():
		var note_data: Dictionary = _chart_notes[_spawn_index]
		var time_until: float = note_data["time"] - Conductor.song_position
		if time_until > LOOKAHEAD_SEC:
			break
		_spawn_note(note_data)
		_spawn_index += 1

func _spawn_note(note_data: Dictionary) -> void:
	var arrow: Node2D = _note_scene.instantiate()
	_lane_node.add_child(arrow)
	arrow.setup(
		note_data["time"],
		note_data.get("button", "face_a"),
		note_data.get("type", "attack"),
		_player_id
	)
	arrow.position.y = 0
	_active_notes.append(arrow)

func _clean_dead_notes() -> void:
	_active_notes = _active_notes.filter(func(n): return is_instance_valid(n) and not n.is_queued_for_deletion())

func set_button_remap(remap: Dictionary) -> void:
	## Set button remap so all chart buttons map to the active unit's button.
	_button_remap = remap

## Find closest active note matching the pressed button within judgment range
func get_hittable_note(pressed_button: String) -> Node2D:
	var best_note: Node2D = null
	var best_diff: float = INF

	for note in _active_notes:
		if not is_instance_valid(note) or note.was_hit or note.was_missed:
			continue
		# Apply remap: the note's chart button maps to the active unit's assigned button
		var effective_button: String = _button_remap.get(note.button, note.button)
		if effective_button != pressed_button:
			continue

		var diff: float = absf(Conductor.song_position - note.note_time)
		if diff < best_diff and diff <= Judgment.BAD_WINDOW:
			best_diff = diff
			best_note = note

	return best_note

## Get all active notes near a given time (for judgment)
func get_notes_near_time(target_time: float, window: float = Judgment.BAD_WINDOW) -> Array:
	var result: Array = []
	for note in _active_notes:
		if not is_instance_valid(note) or note.was_hit or note.was_missed:
			continue
		if absf(note.note_time - target_time) <= window:
			result.append(note)
	return result

func get_total_notes() -> int:
	return _chart_notes.size()

func get_remaining_notes() -> int:
	var active_count: int = 0
	for note in _active_notes:
		if is_instance_valid(note) and not note.was_hit and not note.was_missed:
			active_count += 1
	var unspawned: int = _chart_notes.size() - _spawn_index
	return active_count + unspawned
