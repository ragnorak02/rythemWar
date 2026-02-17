extends Node2D
## NoteArrow — a single scrolling note in the rhythm lane.
## Position is calculated from Conductor.song_position each frame (not velocity*delta).

const SCROLL_SPEED := 400.0  # pixels per second of song time
const HIT_X := 150.0         # X position of the judgment line (target)
const SPAWN_X := 900.0       # X position where notes spawn (right side)
const DESPAWN_X := -100.0    # X position where missed notes are removed

var note_time: float = 0.0   # target time in song seconds
var button: String = ""       # "face_a", "face_b", "face_x", "face_y"
var note_type: String = "attack"  # "attack" or "defend"
var was_hit: bool = false
var was_missed: bool = false
var player_id: int = 1

# Visual
var _arrow_rect: ColorRect = null
var _label: Label = null
var _base_color: Color = Color.WHITE

func _ready() -> void:
	_base_color = _get_button_color()
	_build_visuals()

func setup(p_note_time: float, p_button: String, p_type: String, p_player_id: int = 1) -> void:
	note_time = p_note_time
	button = p_button
	note_type = p_type
	player_id = p_player_id

func _build_visuals() -> void:
	# Arrow body
	_arrow_rect = ColorRect.new()
	_arrow_rect.size = Vector2(40, 40)
	_arrow_rect.position = Vector2(-20, -20)
	_arrow_rect.color = _base_color
	add_child(_arrow_rect)

	# Button label
	_label = Label.new()
	_label.text = _get_button_label()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.size = Vector2(40, 40)
	_label.position = Vector2(-20, -20)
	_label.add_theme_font_size_override("font_size", 16)
	_label.add_theme_color_override("font_color", Color.BLACK)
	add_child(_label)

func _process(_delta: float) -> void:
	if was_hit or was_missed:
		return

	# Position based on song time difference (not velocity*delta)
	var time_diff: float = note_time - Conductor.song_position
	position.x = HIT_X + (time_diff * SCROLL_SPEED)

	# Auto-miss if scrolled past
	if position.x < DESPAWN_X:
		_on_missed()

func hit(grade: String) -> void:
	was_hit = true
	# Flash and fade out
	var grade_color: Color = Judgment.get_grade_color(grade)
	_arrow_rect.color = grade_color
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_callback(queue_free)

func _on_missed() -> void:
	if was_missed or was_hit:
		return
	was_missed = true
	Events.note_missed.emit(player_id, button)
	# Fade out red
	_arrow_rect.color = Judgment.get_grade_color(Judgment.GRADE_MISS)
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
