extends Node2D
## Unit — individual soldier in an army.
## State machine: IDLE, ATTACK_CUE, ATTACKING, DEFEND_CUE, DEFENDING, HIT, DEAD
## Graphics V1: custom _draw() soldier silhouette with idle bob, attack, hurt, death anims.

enum State { IDLE, ATTACK_CUE, ATTACKING, DEFEND_CUE, DEFENDING, HIT, DEAD }

signal state_changed(new_state: State)
signal unit_died()

var unit_index: int = 0
var army_side: String = "player"  # "player" or "enemy"
var max_hp: int = 100
var hp: int = 100
var base_damage: int = 15
var defense: int = 5
var is_alive: bool = true
var engagement_index: int = -1  # Which engagement cluster this unit belongs to

# Unit type properties
var unit_type_id: String = "soldier"
var assigned_button: String = "face_a"
var hold_release: bool = false
var weapon_style: String = "sword"

var _telegraph: Node2D = null

var _state: State = State.IDLE
var _flash_timer: float = 0.0
var _original_color: Color = Color.WHITE
var _draw_color: Color = Color.WHITE
var _damage_boost_turns: int = 0
var _shield_turns: int = 0

# Visual state for _draw()
var _idle_bob: float = 0.0
var _shield_alpha: float = 0.0
var _boost_alpha: float = 0.0

# Turn ownership dim/glow
var _dim_amount: float = 0.0
var _target_dim: float = 0.0
var _active_glow_phase: float = 0.0

# Enemy attack telegraph
var _attack_telegraph_active: bool = false
var _attack_telegraph_timer: float = 0.0
const ATTACK_TELEGRAPH_DURATION := 0.6

# HP bar nodes (still ColorRect for clean UI rendering)
var _hp_bar_bg: ColorRect = null
var _hp_bar_fill: ColorRect = null

const BODY_SIZE := Vector2(24, 36)
const HP_BAR_WIDTH := 28.0
const HP_BAR_HEIGHT := 4.0

func _ready() -> void:
	_build_visuals()

func setup(p_index: int, p_side: String, p_color: Color) -> void:
	unit_index = p_index
	army_side = p_side
	_original_color = p_color
	_draw_color = p_color
	queue_redraw()

func setup_type(type_data: Dictionary) -> void:
	## Apply unit type stats, button, weapon style, and color tint.
	unit_type_id = type_data.get("id", "soldier")
	assigned_button = type_data.get("button", "face_a")
	hold_release = type_data.get("hold_release", false)
	weapon_style = type_data.get("weapon_style", "sword")
	base_damage = type_data.get("base_damage", 15)
	defense = type_data.get("defense", 5)
	max_hp = type_data.get("max_hp", 100)
	hp = max_hp
	_update_hp_bar()
	# Blend type tint 30% with army color
	var type_tint: Color = _get_type_tint(unit_type_id)
	_original_color = _original_color.lerp(type_tint, 0.3)
	_draw_color = _original_color
	queue_redraw()

func _get_type_tint(type_id: String) -> Color:
	match type_id:
		"soldier": return Color(0.5, 0.5, 0.6)
		"archer":  return Color(0.3, 0.7, 0.3)
		"mage":    return Color(0.6, 0.3, 0.9)
		"heavy":   return Color(0.7, 0.5, 0.2)
		"elite":   return Color(0.9, 0.8, 0.3)
		_:         return Color(0.5, 0.5, 0.5)

func _build_visuals() -> void:
	# HP bar background
	_hp_bar_bg = ColorRect.new()
	_hp_bar_bg.size = Vector2(HP_BAR_WIDTH, HP_BAR_HEIGHT)
	_hp_bar_bg.position = Vector2(-HP_BAR_WIDTH / 2, -BODY_SIZE.y / 2 - 10)
	_hp_bar_bg.color = Color(0.2, 0.2, 0.2, 0.8)
	add_child(_hp_bar_bg)

	# HP bar fill
	_hp_bar_fill = ColorRect.new()
	_hp_bar_fill.size = Vector2(HP_BAR_WIDTH, HP_BAR_HEIGHT)
	_hp_bar_fill.position = _hp_bar_bg.position
	_hp_bar_fill.color = Color(0.2, 0.9, 0.3)
	add_child(_hp_bar_fill)

	# HP bar border
	var hp_border := ColorRect.new()
	hp_border.size = Vector2(HP_BAR_WIDTH + 2, HP_BAR_HEIGHT + 2)
	hp_border.position = _hp_bar_bg.position - Vector2(1, 1)
	hp_border.color = Color(0.4, 0.4, 0.5, 0.6)
	hp_border.z_index = -1
	add_child(hp_border)

func _process(delta: float) -> void:
	# Idle bob animation
	if _state == State.IDLE and is_alive:
		_idle_bob = sin(Time.get_ticks_msec() * 0.003 + unit_index * 1.2) * 2.0
	else:
		_idle_bob = 0.0

	# Flash timer
	if _flash_timer > 0:
		_flash_timer -= delta
		_draw_color = Color.WHITE if fmod(_flash_timer, 0.1) > 0.05 else _original_color
		if _flash_timer <= 0:
			_draw_color = _original_color

	# Turn ownership dim smoothing
	_dim_amount = move_toward(_dim_amount, _target_dim, delta * 2.0)

	# Active glow phase (for gold pulse when not dimmed and alive)
	if _dim_amount < 0.01 and is_alive and _target_dim == 0.0:
		_active_glow_phase += delta * 4.0
	else:
		_active_glow_phase = 0.0

	# Enemy attack telegraph countdown
	if _attack_telegraph_active:
		_attack_telegraph_timer -= delta
		if _attack_telegraph_timer <= 0:
			_attack_telegraph_active = false

	# Buff visual alpha decay
	if _shield_turns > 0:
		_shield_alpha = 0.3
	else:
		_shield_alpha = move_toward(_shield_alpha, 0.0, delta * 2.0)

	if _damage_boost_turns > 0:
		_boost_alpha = 0.4
	else:
		_boost_alpha = move_toward(_boost_alpha, 0.0, delta * 2.0)

	queue_redraw()

func _draw() -> void:
	var facing: float = 1.0 if army_side == "player" else -1.0
	var bob := Vector2(0, _idle_bob)

	# Apply turn ownership dim to draw color
	var effective_color: Color = _draw_color.darkened(_dim_amount)

	# --- Active glow arc (gold pulse when it's your turn) ---
	if _active_glow_phase > 0.0 and is_alive:
		var glow_alpha := 0.15 + 0.1 * sin(_active_glow_phase)
		draw_arc(Vector2(0, bob.y), 20.0, 0, TAU, 24, Color(0.94, 0.78, 0.31, glow_alpha), 2.0)

	# --- Enemy attack telegraph (red-orange glow + "!" warning) ---
	if _attack_telegraph_active:
		var t_alpha := clampf(_attack_telegraph_timer / ATTACK_TELEGRAPH_DURATION, 0.0, 1.0)
		var flash := 0.5 + 0.5 * sin(_attack_telegraph_timer * 20.0)
		draw_circle(Vector2(0, bob.y), 22.0, Color(1.0, 0.4, 0.1, t_alpha * 0.4 * flash))
		var font := ThemeDB.fallback_font
		if font:
			var warn_color := Color(1.0, 0.3, 0.0, t_alpha)
			draw_string(font, Vector2(-5, -BODY_SIZE.y / 2 - 14 + bob.y), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, warn_color)

	# --- Shadow (ellipse on ground) ---
	var shadow_color := Color(0.0, 0.0, 0.0, 0.3)
	draw_ellipse_custom(Vector2(0, BODY_SIZE.y / 2 + 2), Vector2(10, 4), shadow_color)

	# --- Legs (two small rects) ---
	var leg_color := effective_color.darkened(0.3)
	var leg_w := 5.0
	var leg_h := 10.0
	var leg_y := BODY_SIZE.y / 2 - leg_h + bob.y
	draw_rect(Rect2(Vector2(-7, leg_y), Vector2(leg_w, leg_h)), leg_color)
	draw_rect(Rect2(Vector2(2, leg_y), Vector2(leg_w, leg_h)), leg_color)

	# --- Body (torso — tapered rectangle) ---
	var body_top := -BODY_SIZE.y / 2 + 8 + bob.y
	var body_h := BODY_SIZE.y - 18
	var body_points := PackedVector2Array([
		Vector2(-10, body_top + body_h),
		Vector2(-8, body_top),
		Vector2(8, body_top),
		Vector2(10, body_top + body_h),
	])
	draw_colored_polygon(body_points, effective_color)

	# --- Shoulder pauldrons ---
	var pauldron_color := effective_color.lightened(0.15)
	draw_rect(Rect2(Vector2(-12, body_top - 1), Vector2(6, 6)), pauldron_color)
	draw_rect(Rect2(Vector2(6, body_top - 1), Vector2(6, 6)), pauldron_color)

	# --- Head (circle) ---
	var head_center := Vector2(0, -BODY_SIZE.y / 2 + 4 + bob.y)
	var head_radius := 7.0
	draw_circle(head_center, head_radius, effective_color.lightened(0.2))
	# Helmet visor
	var visor_y := head_center.y + 1
	draw_rect(Rect2(Vector2(-5, visor_y), Vector2(10, 3)), effective_color.darkened(0.4))

	# --- Weapon (varies by weapon_style) ---
	var weapon_color := Color(0.7, 0.7, 0.8)
	var weapon_base := Vector2(8 * facing, body_top + 4 + bob.y)
	match weapon_style:
		"bow":
			# Bow arc + arrow
			var bow_center := weapon_base + Vector2(6 * facing, -4)
			draw_arc(bow_center, 10.0, -PI * 0.4, PI * 0.4, 12, Color(0.6, 0.4, 0.2), 2.0)
			var arrow_start := bow_center + Vector2(-4 * facing, 0)
			var arrow_end := arrow_start + Vector2(14 * facing, 0)
			draw_line(arrow_start, arrow_end, weapon_color, 1.5)
		"staff":
			# Tall staff with orb
			var staff_bottom := weapon_base + Vector2(2 * facing, 6)
			var staff_top := staff_bottom + Vector2(0, -22)
			draw_line(staff_bottom, staff_top, Color(0.5, 0.35, 0.2), 2.0)
			draw_circle(staff_top, 3.5, Color(0.6, 0.3, 0.9, 0.8))
		"hammer":
			# Heavy hammer head
			var handle_end := weapon_base + Vector2(12 * facing, -6)
			draw_line(weapon_base, handle_end, Color(0.5, 0.35, 0.2), 2.5)
			draw_rect(Rect2(handle_end - Vector2(3, 3), Vector2(6, 8)), weapon_color)
		"lance":
			# Long lance
			var lance_tip := weapon_base + Vector2(20 * facing, -10)
			draw_line(weapon_base, lance_tip, weapon_color, 2.0)
			# Pennant
			draw_line(lance_tip, lance_tip + Vector2(-4 * facing, 4), Color(0.9, 0.2, 0.2, 0.7), 1.5)
		_:  # "sword" default
			var weapon_tip := weapon_base + Vector2(14 * facing, -8)
			draw_line(weapon_base, weapon_tip, weapon_color, 2.0)
			# Hilt
			draw_line(weapon_base + Vector2(-2 * facing, 0), weapon_base + Vector2(2 * facing, 0), Color(0.5, 0.35, 0.2), 2.0)

	# --- Shield buff overlay ---
	if _shield_alpha > 0.01:
		var shield_color := Color(0.3, 0.5, 1.0, _shield_alpha)
		draw_arc(Vector2(0, bob.y), 16.0, 0, TAU, 24, shield_color, 2.0)

	# --- Damage boost overlay ---
	if _boost_alpha > 0.01:
		var boost_color := Color(1.0, 0.5, 0.1, _boost_alpha)
		draw_arc(Vector2(0, bob.y), 14.0, 0, TAU, 24, boost_color, 1.5)

func draw_ellipse_custom(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	var segments := 16
	for i in segments + 1:
		var angle := float(i) / float(segments) * TAU
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)

func change_state(new_state: State) -> void:
	_state = new_state
	state_changed.emit(new_state)
	match new_state:
		State.ATTACKING:
			_play_attack_anim()
		State.HIT:
			_play_hit_anim()
		State.DEAD:
			_play_death_anim()
		State.DEFENDING:
			_play_defend_anim()
		State.IDLE:
			pass

func take_damage(amount: int) -> int:
	if not is_alive:
		return 0
	var actual_dmg: int = maxi(1, amount - defense)
	if _shield_turns > 0:
		actual_dmg = maxi(1, actual_dmg / 2)
	hp = maxi(0, hp - actual_dmg)
	_update_hp_bar()
	change_state(State.HIT)

	Events.unit_damaged.emit(army_side, unit_index, actual_dmg, hp)

	if hp <= 0:
		is_alive = false
		SfxManager.play("unit_death")
		change_state(State.DEAD)
		unit_died.emit()
		Events.unit_died.emit(army_side, unit_index)

	return actual_dmg

func heal(amount: int) -> void:
	if not is_alive:
		return
	hp = mini(max_hp, hp + amount)
	_update_hp_bar()
	# Green flash
	_draw_color = Color(0.3, 1.0, 0.5)
	_flash_timer = 0.3

func get_damage() -> int:
	var dmg: int = base_damage
	if _damage_boost_turns > 0:
		dmg *= 2
	return dmg

func apply_damage_boost(turns: int) -> void:
	_damage_boost_turns = turns

func apply_shield(turns: int) -> void:
	_shield_turns = turns

func set_turn_active(is_active: bool) -> void:
	_target_dim = 0.0 if is_active else 0.4

func set_turn_neutral() -> void:
	_target_dim = 0.0

func show_attack_telegraph() -> void:
	_attack_telegraph_active = true
	_attack_telegraph_timer = ATTACK_TELEGRAPH_DURATION

func tick_buffs() -> void:
	if _damage_boost_turns > 0:
		_damage_boost_turns -= 1
	if _shield_turns > 0:
		_shield_turns -= 1

func _update_hp_bar() -> void:
	var ratio: float = float(hp) / float(max_hp)
	_hp_bar_fill.size.x = HP_BAR_WIDTH * ratio
	if ratio > 0.5:
		_hp_bar_fill.color = Color(0.2, 0.9, 0.3)
	elif ratio > 0.25:
		_hp_bar_fill.color = Color(1.0, 0.8, 0.0)
	else:
		_hp_bar_fill.color = Color(1.0, 0.2, 0.2)

func _play_attack_anim() -> void:
	var dir: float = 1.0 if army_side == "player" else -1.0
	var tween := create_tween()
	tween.tween_property(self, "position:x", position.x + 30.0 * dir, 0.1)
	tween.tween_property(self, "position:x", position.x, 0.15)
	tween.tween_callback(func(): change_state(State.IDLE))

func _play_hit_anim() -> void:
	_flash_timer = 0.25
	var dir: float = -1.0 if army_side == "player" else 1.0
	var tween := create_tween()
	tween.tween_property(self, "position:x", position.x + 8.0 * dir, 0.05)
	tween.tween_property(self, "position:x", position.x, 0.1)

func _play_death_anim() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.3, 0.5)
	tween.parallel().tween_property(self, "position:y", position.y + 10, 0.5)

func _play_defend_anim() -> void:
	# Brief blue tint
	_draw_color = Color(0.3, 0.5, 1.0)
	var tween := create_tween()
	tween.tween_interval(0.3)
	tween.tween_callback(func():
		_draw_color = _original_color
		change_state(State.IDLE)
	)

# --- Telegraph methods ---

func attach_telegraph(telegraph_node: Node2D) -> void:
	## Adds telegraph as child, positioned above HP bar.
	_telegraph = telegraph_node
	add_child(_telegraph)
	_telegraph.position = Vector2(0, -BODY_SIZE.y / 2 - 30)

func show_telegraph_button(button_name: String, time_until: float) -> void:
	if _telegraph:
		_telegraph.show_button(button_name, time_until)

func hide_telegraph() -> void:
	if _telegraph:
		_telegraph.hide_button()

func show_telegraph_feedback(grade: String) -> void:
	if _telegraph:
		_telegraph.show_feedback(grade)
