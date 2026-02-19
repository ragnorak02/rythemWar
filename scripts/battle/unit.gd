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

	# --- Shadow (ellipse on ground) ---
	var shadow_color := Color(0.0, 0.0, 0.0, 0.3)
	draw_ellipse_custom(Vector2(0, BODY_SIZE.y / 2 + 2), Vector2(10, 4), shadow_color)

	# --- Legs (two small rects) ---
	var leg_color := _draw_color.darkened(0.3)
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
	draw_colored_polygon(body_points, _draw_color)

	# --- Shoulder pauldrons ---
	var pauldron_color := _draw_color.lightened(0.15)
	draw_rect(Rect2(Vector2(-12, body_top - 1), Vector2(6, 6)), pauldron_color)
	draw_rect(Rect2(Vector2(6, body_top - 1), Vector2(6, 6)), pauldron_color)

	# --- Head (circle) ---
	var head_center := Vector2(0, -BODY_SIZE.y / 2 + 4 + bob.y)
	var head_radius := 7.0
	draw_circle(head_center, head_radius, _draw_color.lightened(0.2))
	# Helmet visor
	var visor_y := head_center.y + 1
	draw_rect(Rect2(Vector2(-5, visor_y), Vector2(10, 3)), _draw_color.darkened(0.4))

	# --- Weapon (sword or spear — facing direction) ---
	var weapon_color := Color(0.7, 0.7, 0.8)
	var weapon_base := Vector2(8 * facing, body_top + 4 + bob.y)
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
