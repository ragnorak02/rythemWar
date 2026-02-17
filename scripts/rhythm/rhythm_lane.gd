extends Node2D
## RhythmLane — per-player lane. Owns a NoteSpawner, handles _input(),
## tracks combo, displays judgment text. Supports direction combos and RT modifier.

const JUDGMENT_LINE_X := 150.0
const LANE_HEIGHT := 60.0

var player_id: int = 1
var combo: int = 0
var max_combo: int = 0
var score: int = 0
var total_hits: int = 0
var total_misses: int = 0
var perfects: int = 0
var greats: int = 0
var goods: int = 0
var bads: int = 0

var _spawner: Node = null
var _judgment_label: Label = null
var _combo_label: Label = null
var _result_type_label: Label = null
var _judgment_line: ColorRect = null
var _button_actions: Dictionary = {}
var _direction_actions: Array[String] = []
var _modifier_action: String = ""

# Direction combo state
var _held_direction: String = ""  # "up", "down", "left", "right" or ""
var _modifier_held: bool = false

func _ready() -> void:
	_setup_button_mapping()
	_build_visuals()
	_setup_spawner()
	Events.note_missed.connect(_on_note_missed)

func setup_lane(p_player_id: int) -> void:
	player_id = p_player_id
	_setup_button_mapping()

func _setup_button_mapping() -> void:
	var prefix: String = "p%d_" % player_id
	_button_actions = {
		prefix + "face_a": "face_a",
		prefix + "face_b": "face_b",
		prefix + "face_x": "face_x",
		prefix + "face_y": "face_y",
	}
	_direction_actions = [
		prefix + "up",
		prefix + "down",
		prefix + "left",
		prefix + "right",
	]
	_modifier_action = prefix + "modifier"

func _build_visuals() -> void:
	# Judgment line (vertical bar where notes should be hit)
	_judgment_line = ColorRect.new()
	_judgment_line.size = Vector2(4, LANE_HEIGHT + 20)
	_judgment_line.position = Vector2(JUDGMENT_LINE_X - 2, -(LANE_HEIGHT / 2) - 10)
	_judgment_line.color = Color(1.0, 1.0, 1.0, 0.6)
	add_child(_judgment_line)

	# Lane background
	var lane_bg := ColorRect.new()
	lane_bg.size = Vector2(800, LANE_HEIGHT)
	lane_bg.position = Vector2(0, -(LANE_HEIGHT / 2))
	lane_bg.color = Color(0.1, 0.1, 0.15, 0.5)
	add_child(lane_bg)
	lane_bg.z_index = -1

	# Judgment text display
	_judgment_label = Label.new()
	_judgment_label.text = ""
	_judgment_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_judgment_label.position = Vector2(JUDGMENT_LINE_X - 60, -80)
	_judgment_label.size = Vector2(120, 40)
	_judgment_label.add_theme_font_size_override("font_size", 28)
	add_child(_judgment_label)

	# Combo counter
	_combo_label = Label.new()
	_combo_label.text = ""
	_combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_combo_label.position = Vector2(JUDGMENT_LINE_X - 40, -50)
	_combo_label.size = Vector2(80, 30)
	_combo_label.add_theme_font_size_override("font_size", 18)
	_combo_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 0.8))
	add_child(_combo_label)

	# Result type label (SUPER STRIKE, BLOCK, etc.)
	_result_type_label = Label.new()
	_result_type_label.text = ""
	_result_type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_type_label.position = Vector2(JUDGMENT_LINE_X - 80, -110)
	_result_type_label.size = Vector2(160, 30)
	_result_type_label.add_theme_font_size_override("font_size", 16)
	_result_type_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.0))
	add_child(_result_type_label)

func _setup_spawner() -> void:
	_spawner = Node.new()
	_spawner.set_script(preload("res://scripts/rhythm/note_spawner.gd"))
	add_child(_spawner)
	_spawner.setup(self, player_id)

func load_chart(chart_data: Dictionary) -> void:
	_spawner.load_chart(chart_data)
	_reset_stats()

func _reset_stats() -> void:
	combo = 0
	max_combo = 0
	score = 0
	total_hits = 0
	total_misses = 0
	perfects = 0
	greats = 0
	goods = 0
	bads = 0

func _process(_delta: float) -> void:
	# Track held directions and modifier
	_update_held_inputs()

func _update_held_inputs() -> void:
	var prefix: String = "p%d_" % player_id
	_modifier_held = Input.is_action_pressed(_modifier_action)

	_held_direction = ""
	if Input.is_action_pressed(prefix + "up"):
		_held_direction = "up"
	elif Input.is_action_pressed(prefix + "down"):
		_held_direction = "down"
	elif Input.is_action_pressed(prefix + "left"):
		_held_direction = "left"
	elif Input.is_action_pressed(prefix + "right"):
		_held_direction = "right"

func _input(event: InputEvent) -> void:
	if not Conductor.is_playing():
		return

	for action_name in _button_actions:
		if event.is_action_pressed(action_name):
			_on_button_pressed(_button_actions[action_name])
			get_viewport().set_input_as_handled()
			return

func _on_button_pressed(button_name: String) -> void:
	var note: Node2D = _spawner.get_hittable_note(button_name)
	if note == null:
		return

	var grade: String = Judgment.evaluate(Conductor.song_position, note.note_time)

	if grade == Judgment.GRADE_MISS:
		return  # Too far, let it auto-miss

	# Determine result type based on modifier/direction state
	var result_type: String = _determine_result_type(note.note_type)

	note.hit(grade)

	# Update combo
	if Judgment.keeps_combo(grade):
		combo += 1
		if combo > max_combo:
			max_combo = combo
		total_hits += 1
	else:
		if combo > 0:
			Events.combo_broken.emit(player_id, combo)
		combo = 0
		total_hits += 1  # BAD is still a hit, just breaks combo

	# Track grade counts
	match grade:
		Judgment.GRADE_PERFECT: perfects += 1
		Judgment.GRADE_GREAT: greats += 1
		Judgment.GRADE_GOOD: goods += 1
		Judgment.GRADE_BAD: bads += 1

	# Score with combo multiplier
	var combo_mult: float = 1.0 + (combo * 0.1)
	var result_bonus: float = _get_result_type_bonus(result_type)
	score += int(Judgment.SCORE_VALUES[grade] * combo_mult * result_bonus)

	# Emit signals
	Events.judgment_made.emit(player_id, grade, combo, note.note_type)
	Events.note_hit.emit(player_id, note.note_type, grade)

	# Show feedback
	_show_judgment(grade)
	_show_result_type(result_type)
	_update_combo_display()

func _determine_result_type(note_type: String) -> String:
	## Determine attack result based on modifier and direction held:
	## - No modifier, no direction: "normal" attack/defend
	## - Modifier held + attack note: "super_strike" (extra damage)
	## - Modifier held + defend note: "super_counter" (counter-attack)
	## - Direction held + attack: "directed_attack" (targets specific unit)
	## - Direction held + defend: "block" (reduces incoming damage)
	if _modifier_held:
		if note_type == "attack":
			return "super_strike"
		else:
			return "super_counter"
	elif _held_direction != "":
		if note_type == "defend":
			return "block"
		else:
			return "directed_attack"
	return "normal"

func _get_result_type_bonus(result_type: String) -> float:
	match result_type:
		"super_strike": return 1.5
		"super_counter": return 1.3
		"directed_attack": return 1.2
		"block": return 1.1
		_: return 1.0

func _on_note_missed(missed_player_id: int, _note_type: String) -> void:
	if missed_player_id != player_id:
		return
	total_misses += 1
	if combo > 0:
		Events.combo_broken.emit(player_id, combo)
	combo = 0
	_show_judgment(Judgment.GRADE_MISS)
	_update_combo_display()

func _show_judgment(grade: String) -> void:
	_judgment_label.text = grade
	_judgment_label.add_theme_color_override("font_color", Judgment.get_grade_color(grade))
	# Animate: pop in and fade
	_judgment_label.scale = Vector2(1.3, 1.3)
	_judgment_label.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(_judgment_label, "scale", Vector2(1.0, 1.0), 0.15)
	tween.parallel().tween_property(_judgment_label, "modulate:a", 0.0, 0.8).set_delay(0.3)

func _show_result_type(result_type: String) -> void:
	if result_type == "normal":
		return
	var display_name: String = ""
	var color: Color = Color.WHITE
	match result_type:
		"super_strike":
			display_name = "SUPER STRIKE"
			color = Color(1.0, 0.3, 0.0)
		"super_counter":
			display_name = "SUPER COUNTER"
			color = Color(0.0, 0.8, 1.0)
		"directed_attack":
			display_name = "DIRECTED"
			color = Color(0.8, 1.0, 0.3)
		"block":
			display_name = "BLOCK"
			color = Color(0.3, 0.5, 1.0)

	_result_type_label.text = display_name
	_result_type_label.add_theme_color_override("font_color", color)
	_result_type_label.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(_result_type_label, "modulate:a", 0.0, 0.6).set_delay(0.3)

func _update_combo_display() -> void:
	if combo >= 2:
		_combo_label.text = "%d COMBO" % combo
		_combo_label.modulate.a = 1.0
	else:
		_combo_label.text = ""

func get_accuracy() -> float:
	var total: int = total_hits + total_misses
	if total == 0:
		return 0.0
	return float(total_hits) / float(total) * 100.0

func get_results() -> Dictionary:
	return {
		"player_id": player_id,
		"score": score,
		"combo": max_combo,
		"accuracy": get_accuracy(),
		"perfects": perfects,
		"greats": greats,
		"goods": goods,
		"bads": bads,
		"misses": total_misses,
		"total_notes": total_hits + total_misses,
	}
