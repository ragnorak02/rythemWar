extends Node2D
## Unit — individual soldier in an army.
## State machine: IDLE, ATTACK_CUE, ATTACKING, DEFEND_CUE, DEFENDING, HIT, DEAD

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

var _state: State = State.IDLE
var _body_rect: ColorRect = null
var _hp_bar_bg: ColorRect = null
var _hp_bar_fill: ColorRect = null
var _flash_timer: float = 0.0
var _original_color: Color = Color.WHITE
var _damage_boost_turns: int = 0
var _shield_turns: int = 0

const BODY_SIZE := Vector2(24, 36)
const HP_BAR_WIDTH := 28.0
const HP_BAR_HEIGHT := 4.0

func _ready() -> void:
	_build_visuals()

func setup(p_index: int, p_side: String, p_color: Color) -> void:
	unit_index = p_index
	army_side = p_side
	_original_color = p_color
	if _body_rect:
		_body_rect.color = p_color

func _build_visuals() -> void:
	# Body
	_body_rect = ColorRect.new()
	_body_rect.size = BODY_SIZE
	_body_rect.position = -BODY_SIZE / 2
	_body_rect.color = _original_color
	add_child(_body_rect)

	# HP bar background
	_hp_bar_bg = ColorRect.new()
	_hp_bar_bg.size = Vector2(HP_BAR_WIDTH, HP_BAR_HEIGHT)
	_hp_bar_bg.position = Vector2(-HP_BAR_WIDTH / 2, -BODY_SIZE.y / 2 - 8)
	_hp_bar_bg.color = Color(0.2, 0.2, 0.2, 0.8)
	add_child(_hp_bar_bg)

	# HP bar fill
	_hp_bar_fill = ColorRect.new()
	_hp_bar_fill.size = Vector2(HP_BAR_WIDTH, HP_BAR_HEIGHT)
	_hp_bar_fill.position = _hp_bar_bg.position
	_hp_bar_fill.color = Color(0.2, 0.9, 0.3)
	add_child(_hp_bar_fill)

func _process(delta: float) -> void:
	if _flash_timer > 0:
		_flash_timer -= delta
		_body_rect.color = Color.WHITE if fmod(_flash_timer, 0.1) > 0.05 else _original_color
		if _flash_timer <= 0:
			_body_rect.color = _original_color

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
	_body_rect.color = Color(0.3, 1.0, 0.5)
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
	_body_rect.color = Color(0.3, 0.5, 1.0)
	var tween := create_tween()
	tween.tween_interval(0.3)
	tween.tween_callback(func():
		_body_rect.color = _original_color
		change_state(State.IDLE)
	)
