extends Node2D
## Main test scene — temporary Phase 1 entry point.
## Sets up a RhythmLane with the easy chart and starts playback.

var _rhythm_lane: Node2D = null
var _title_label: Label = null
var _info_label: Label = null
var _chart_data: Dictionary = {}

func _ready() -> void:
	# Dark background
	RenderingServer.set_default_clear_color(Color(0.08, 0.06, 0.12))

	_load_chart()
	_build_ui()
	_setup_lane()
	_start_playback()

func _load_chart() -> void:
	var file := FileAccess.open("res://data/charts/stage_easy_01.json", FileAccess.READ)
	if file:
		_chart_data = JSON.parse_string(file.get_as_text())
		file.close()

func _build_ui() -> void:
	# Title
	_title_label = Label.new()
	_title_label.text = "RhythmWar — %s" % _chart_data.get("title", "Test")
	_title_label.position = Vector2(20, 10)
	_title_label.add_theme_font_size_override("font_size", 24)
	_title_label.add_theme_color_override("font_color", Color(0.94, 0.78, 0.31))
	add_child(_title_label)

	# Controls info
	_info_label = Label.new()
	_info_label.text = "Controls: A=face_y  S=face_x  D=face_a  F=face_b  |  Controller: A/B/X/Y"
	_info_label.position = Vector2(20, 680)
	_info_label.add_theme_font_size_override("font_size", 14)
	_info_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	add_child(_info_label)

	# Score display
	var score_label := Label.new()
	score_label.name = "ScoreLabel"
	score_label.text = "Score: 0"
	score_label.position = Vector2(1050, 10)
	score_label.add_theme_font_size_override("font_size", 20)
	score_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(score_label)

	# BPM display
	var bpm_label := Label.new()
	bpm_label.text = "BPM: %d" % _chart_data.get("bpm", 100)
	bpm_label.position = Vector2(1050, 40)
	bpm_label.add_theme_font_size_override("font_size", 16)
	bpm_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	add_child(bpm_label)

func _setup_lane() -> void:
	_rhythm_lane = Node2D.new()
	_rhythm_lane.set_script(preload("res://scripts/rhythm/rhythm_lane.gd"))
	_rhythm_lane.position = Vector2(200, 360)  # Center of screen
	add_child(_rhythm_lane)
	_rhythm_lane.setup_lane(1)
	_rhythm_lane.load_chart(_chart_data)

	Events.judgment_made.connect(_on_judgment_made)
	Events.song_finished.connect(_on_song_finished)

func _start_playback() -> void:
	# Create a silent placeholder audio stream since we don't have a real track
	var stream := _create_placeholder_audio()
	var bpm: float = _chart_data.get("bpm", 100.0)
	var offset: float = _chart_data.get("offset_sec", 0.0)
	Conductor.play_song(stream, bpm, offset)

func _create_placeholder_audio() -> AudioStream:
	# Generate a short silent audio stream (15 seconds)
	var sample_rate := 44100
	var duration := 15.0
	var num_samples := int(sample_rate * duration)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	# 8-bit silence is 128 (center point)
	var data := PackedByteArray()
	data.resize(num_samples)
	data.fill(128)
	stream.data = data
	return stream

func _on_judgment_made(_player_id: int, _grade: String, _combo: int, _note_type: String) -> void:
	var score_node := get_node_or_null("ScoreLabel")
	if score_node and _rhythm_lane:
		score_node.text = "Score: %d" % _rhythm_lane.score

func _on_song_finished() -> void:
	if _rhythm_lane:
		var results: Dictionary = _rhythm_lane.get_results()
		_title_label.text = "Song Complete! Score: %d  Max Combo: %d  Accuracy: %.1f%%" % [
			results["score"], results["combo"], results["accuracy"]
		]

func _input(event: InputEvent) -> void:
	# R to restart
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		get_tree().reload_current_scene()
	# Escape to quit
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().quit()
