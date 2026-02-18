extends Node2D
## UnitTelegraph — on-unit button prompt + feedback display.
## Shows button icon above the active engagement's player unit.
## Glow intensifies as note approaches judgment window.
## Hit/miss feedback text floats up and fades.

var _button_name: String = ""
var _time_until: float = 999.0
var _is_showing: bool = false
var _feedback_text: String = ""
var _feedback_color: Color = Color.WHITE
var _feedback_alpha: float = 0.0
var _feedback_y_offset: float = 0.0
var _glow_intensity: float = 0.0
var _pulse_phase: float = 0.0

# Ability prompt state
var _ability_button: String = ""
var _ability_showing: bool = false

const ICON_RADIUS := 16.0
const SHOW_THRESHOLD := 1.5     # Show button 1.5s before hit
const PULSE_THRESHOLD := 0.5    # Start pulsing 0.5s before hit
const FEEDBACK_DURATION := 0.8

func _process(delta: float) -> void:
	if _is_showing or _ability_showing:
		_pulse_phase += delta * 6.0
		# Glow intensifies as note approaches
		if _time_until <= PULSE_THRESHOLD:
			_glow_intensity = 1.0 - (_time_until / PULSE_THRESHOLD)
		else:
			_glow_intensity = 0.3

	# Feedback fade
	if _feedback_alpha > 0:
		_feedback_alpha -= delta / FEEDBACK_DURATION
		_feedback_y_offset -= delta * 40.0
		if _feedback_alpha <= 0:
			_feedback_text = ""

	queue_redraw()

func _draw() -> void:
	# Draw button telegraph
	if _is_showing or _ability_showing:
		var btn: String = _button_name if _is_showing else _ability_button
		_draw_button_icon(Vector2(0, -10), btn)

	# Draw feedback text
	if _feedback_alpha > 0 and _feedback_text != "":
		_draw_feedback()

func _draw_button_icon(center: Vector2, btn: String) -> void:
	var color := _get_button_color(btn)
	var pulse := 0.8 + 0.2 * sin(_pulse_phase)

	# Outer glow
	var glow_alpha := _glow_intensity * 0.4 * pulse
	draw_circle(center, ICON_RADIUS + 6, Color(color.r, color.g, color.b, glow_alpha))

	# Circle background
	var bg_alpha := 0.6 + _glow_intensity * 0.3
	draw_circle(center, ICON_RADIUS, Color(0.1, 0.1, 0.15, bg_alpha))

	# Circle border with color
	var border_alpha := 0.7 + _glow_intensity * 0.3
	draw_arc(center, ICON_RADIUS, 0, TAU, 24, Color(color.r, color.g, color.b, border_alpha * pulse), 2.5)

	# Button letter
	var letter := _get_button_letter(btn)
	# Draw the letter using draw_string if available, otherwise use a simple approach
	# Since we can't easily get a font ref in _draw(), we use a centered approach
	var font := ThemeDB.fallback_font
	if font:
		var text_size := font.get_string_size(letter, HORIZONTAL_ALIGNMENT_CENTER, -1, 18)
		draw_string(font, center - Vector2(text_size.x / 2, -6), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)

func _draw_feedback() -> void:
	var pos := Vector2(0, -30 + _feedback_y_offset)
	var font := ThemeDB.fallback_font
	if font:
		var c := Color(_feedback_color.r, _feedback_color.g, _feedback_color.b, _feedback_alpha)
		var text_size := font.get_string_size(_feedback_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16)
		draw_string(font, pos - Vector2(text_size.x / 2, 0), _feedback_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, c)

func show_button(button_name: String, time_until: float) -> void:
	_button_name = button_name
	_time_until = time_until
	_is_showing = true

func hide_button() -> void:
	_is_showing = false
	_button_name = ""
	_time_until = 999.0
	_glow_intensity = 0.0

func show_feedback(grade: String) -> void:
	_feedback_text = grade
	_feedback_color = Judgment.get_grade_color(grade)
	_feedback_alpha = 1.0
	_feedback_y_offset = 0.0
	hide_button()

func show_ability_prompt(ability_id: String, button_name: String) -> void:
	_ability_button = button_name
	_ability_showing = true
	_glow_intensity = 0.8

func hide_ability_prompt() -> void:
	_ability_showing = false
	_ability_button = ""

func update_time(time_until: float) -> void:
	_time_until = time_until

func _get_button_color(btn: String) -> Color:
	match btn:
		"face_a": return Color(0.2, 0.8, 0.3)   # Green (A)
		"face_b": return Color(0.9, 0.2, 0.2)   # Red (B)
		"face_x": return Color(0.2, 0.5, 1.0)   # Blue (X)
		"face_y": return Color(1.0, 0.8, 0.0)   # Yellow (Y)
		_:        return Color.WHITE

func _get_button_letter(btn: String) -> String:
	match btn:
		"face_a": return "A"
		"face_b": return "B"
		"face_x": return "X"
		"face_y": return "Y"
		_:        return "?"
