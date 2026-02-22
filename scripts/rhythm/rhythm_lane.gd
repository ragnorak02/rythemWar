extends Node2D
## RhythmLane — per-player lane. Owns a NoteSpawner, handles _input(),
## tracks combo, displays judgment text. Supports direction combos and RT modifier.
## Graphics V1: shader judgment line, shader lane BG, particle judgment feedback.

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
var _judgment_particles: CPUParticles2D = null
var _button_actions: Dictionary = {}
var _direction_actions: Array[String] = []
var _modifier_action: String = ""

# Direction combo state
var _held_direction: String = ""  # "up", "down", "left", "right" or ""
var _modifier_held: bool = false

# Soft failure: consecutive miss tracking for grace period
var _consecutive_misses: int = 0

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
	# Lane background with shader
	var lane_bg := ColorRect.new()
	lane_bg.size = Vector2(800, LANE_HEIGHT)
	lane_bg.position = Vector2(0, -(LANE_HEIGHT / 2))
	lane_bg.z_index = -1
	var lane_shader := load("res://assets/shaders/rhythm_lane.gdshader")
	if lane_shader:
		var mat := ShaderMaterial.new()
		mat.shader = lane_shader
		lane_bg.material = mat
	else:
		lane_bg.color = Color(0.1, 0.1, 0.15, 0.5)
	add_child(lane_bg)

	# Judgment line with glow shader
	_judgment_line = ColorRect.new()
	_judgment_line.size = Vector2(12, LANE_HEIGHT + 30)
	_judgment_line.position = Vector2(JUDGMENT_LINE_X - 6, -(LANE_HEIGHT / 2) - 15)
	var line_shader := load("res://assets/shaders/judgment_line_glow.gdshader")
	if line_shader:
		var mat := ShaderMaterial.new()
		mat.shader = line_shader
		mat.set_shader_parameter("glow_color", Color(1.0, 0.95, 0.7, 0.9))
		mat.set_shader_parameter("pulse_speed", 3.0)
		_judgment_line.material = mat
	else:
		_judgment_line.color = Color(1.0, 1.0, 1.0, 0.6)
	add_child(_judgment_line)

	# Judgment feedback particles (burst on Perfect/Great)
	_judgment_particles = CPUParticles2D.new()
	_judgment_particles.position = Vector2(JUDGMENT_LINE_X, 0)
	_judgment_particles.emitting = false
	_judgment_particles.one_shot = true
	_judgment_particles.amount = 12
	_judgment_particles.lifetime = 0.5
	_judgment_particles.explosiveness = 1.0
	_judgment_particles.direction = Vector2(0, -1)
	_judgment_particles.spread = 120.0
	_judgment_particles.initial_velocity_min = 60.0
	_judgment_particles.initial_velocity_max = 120.0
	_judgment_particles.gravity = Vector2(0, 80)
	_judgment_particles.scale_amount_min = 2.0
	_judgment_particles.scale_amount_max = 4.0
	_judgment_particles.color = Color(1.0, 0.84, 0.0)
	add_child(_judgment_particles)

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
	_consecutive_misses = 0

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

	# Reset consecutive miss tracker on any successful hit
	_consecutive_misses = 0

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

	# Play judgment SFX
	match grade:
		Judgment.GRADE_PERFECT: SfxManager.play("judgment_perfect")
		Judgment.GRADE_GREAT: SfxManager.play("judgment_great")
		Judgment.GRADE_GOOD: SfxManager.play("judgment_good")
		Judgment.GRADE_BAD: SfxManager.play("judgment_bad")

	# Show feedback
	_show_judgment(grade)
	_show_result_type(result_type)
	_update_combo_display()

	# Particle burst for good hits
	_emit_judgment_particles(grade)

func _determine_result_type(note_type: String) -> String:
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
	SfxManager.play("attack_miss")
	total_misses += 1
	_consecutive_misses += 1
	# Grace period: combo only breaks after MISS_GRACE_COUNT consecutive misses
	if Judgment.should_break_combo(Judgment.GRADE_MISS, _consecutive_misses):
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

func _emit_judgment_particles(grade: String) -> void:
	if grade == Judgment.GRADE_PERFECT:
		_judgment_particles.amount = 16
		_judgment_particles.color = Color(1.0, 0.84, 0.0)  # Gold
		_judgment_particles.restart()
		_judgment_particles.emitting = true
	elif grade == Judgment.GRADE_GREAT:
		_judgment_particles.amount = 10
		_judgment_particles.color = Color(0.0, 1.0, 0.4)  # Green
		_judgment_particles.restart()
		_judgment_particles.emitting = true

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
