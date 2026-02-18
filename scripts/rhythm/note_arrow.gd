extends Node2D
## NoteArrow — a single scrolling note in the rhythm lane.
## Graphics V1: custom _draw() diamond shape with button-colored glow and letter.

const SCROLL_SPEED := 400.0  # pixels per second of song time
const HIT_X := 150.0         # X position of the judgment line (target)
const SPAWN_X := 900.0       # X position where notes spawn (right side)
const DESPAWN_X := -100.0    # X position where missed notes are removed
const NOTE_SIZE := 20.0      # Half-size of the diamond

var note_time: float = 0.0   # target time in song seconds
var button: String = ""       # "face_a", "face_b", "face_x", "face_y"
var note_type: String = "attack"  # "attack" or "defend"
var was_hit: bool = false
var was_missed: bool = false
var player_id: int = 1

# Visual
var _label: Label = null
var _base_color: Color = Color.WHITE
var _current_color: Color = Color.WHITE
var _glow_phase: float = 0.0

func _ready() -> void:
	_base_color = _get_button_color()
	_current_color = _base_color
	_glow_phase = randf() * TAU  # Random start phase for shimmer
	_build_label()

func setup(p_note_time: float, p_button: String, p_type: String, p_player_id: int = 1) -> void:
	note_time = p_note_time
	button = p_button
	note_type = p_type
	player_id = p_player_id

func _build_label() -> void:
	# Button label centered on diamond
	_label = Label.new()
	_label.text = _get_button_label()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.size = Vector2(40, 40)
	_label.position = Vector2(-20, -20)
	_label.add_theme_font_size_override("font_size", 14)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.z_index = 1
	add_child(_label)

func _process(_delta: float) -> void:
	if was_hit or was_missed:
		return

	# Position based on song time difference
	var time_diff: float = note_time - Conductor.song_position
	position.x = HIT_X + (time_diff * SCROLL_SPEED)

	# Glow phase for shimmer
	_glow_phase += _delta * 4.0

	queue_redraw()

	# Auto-miss if scrolled past
	if position.x < DESPAWN_X:
		_on_missed()

func _draw() -> void:
	var s := NOTE_SIZE
	var glow_pulse := 0.8 + 0.2 * sin(_glow_phase)

	# Outer glow (larger, transparent)
	var glow_color := Color(_current_color.r, _current_color.g, _current_color.b, 0.2 * glow_pulse)
	var glow_points := PackedVector2Array([
		Vector2(0, -(s + 4)), Vector2(s + 4, 0),
		Vector2(0, s + 4), Vector2(-(s + 4), 0)
	])
	draw_colored_polygon(glow_points, glow_color)

	# Diamond body
	var body_points := PackedVector2Array([
		Vector2(0, -s), Vector2(s, 0),
		Vector2(0, s), Vector2(-s, 0)
	])
	draw_colored_polygon(body_points, _current_color.darkened(0.2))

	# Inner highlight (smaller diamond, lighter)
	var inner_s := s * 0.6
	var inner_points := PackedVector2Array([
		Vector2(0, -inner_s), Vector2(inner_s, 0),
		Vector2(0, inner_s), Vector2(-inner_s, 0)
	])
	draw_colored_polygon(inner_points, _current_color.lightened(0.15))

	# Border outline
	var border_color := _current_color.lightened(0.3)
	border_color.a = 0.7
	draw_polyline(PackedVector2Array([
		Vector2(0, -s), Vector2(s, 0),
		Vector2(0, s), Vector2(-s, 0), Vector2(0, -s)
	]), border_color, 1.5)

	# Defend notes get a small shield icon at bottom
	if note_type == "defend":
		var shield_color := Color(0.4, 0.6, 1.0, 0.5)
		draw_arc(Vector2(0, s + 6), 4.0, PI, TAU, 8, shield_color, 1.5)

func hit(grade: String) -> void:
	was_hit = true
	_current_color = Judgment.get_grade_color(grade)
	queue_redraw()
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.4, 1.4), 0.08)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_callback(queue_free)

func _on_missed() -> void:
	if was_missed or was_hit:
		return
	was_missed = true
	Events.note_missed.emit(player_id, button)
	_current_color = Judgment.get_grade_color(Judgment.GRADE_MISS)
	queue_redraw()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)

func _get_button_color() -> Color:
	match button:
		"face_a": return Color(0.2, 0.8, 0.3)   # Green (A)
		"face_b": return Color(0.9, 0.2, 0.2)   # Red (B)
		"face_x": return Color(0.2, 0.5, 1.0)   # Blue (X)
		"face_y": return Color(1.0, 0.8, 0.0)   # Yellow (Y)
		_:        return Color.WHITE

func _get_button_label() -> String:
	match button:
		"face_a": return "A"
		"face_b": return "B"
		"face_x": return "X"
		"face_y": return "Y"
		_:        return "?"
