extends Node
## BattleStateMachine — manages turn sequencing for the rhythm battle.
## Flow: TACTICIAN -> INTRO -> PLAYER_TURN -> RESOLVE_ATTACK -> ENEMY_TURN -> CHECK_WIN -> loop

enum BattlePhase { TACTICIAN, INTRO, PLAYER_TURN, RESOLVE_ATTACK, ENEMY_TURN, CHECK_WIN, VICTORY, DEFEAT, DRAW }

signal phase_changed(phase: BattlePhase)
signal attack_resolved(attacker_side: String, damage: int, grade: String)

var current_phase: BattlePhase = BattlePhase.TACTICIAN
var turn_number: int = 0
var player_army: Node2D = null
var enemy_army: Node2D = null
var _engagement_manager: Node2D = null

# Commander action effects
var _reduce_enemy_attacks: int = 0  # Number of enemy attacks to skip
var _skip_enemy_first: bool = false  # Skip first enemy attack in first enemy turn

# Accumulated from rhythm input during player turn
var _pending_grade: String = ""
var _pending_note_type: String = ""
var _pending_combo: int = 0
var _attack_result_type: String = "normal"  # normal, block, super_strike, super_counter

func setup(p_player: Node2D, p_enemy: Node2D, p_engagement_manager: Node2D = null) -> void:
	player_army = p_player
	enemy_army = p_enemy
	_engagement_manager = p_engagement_manager

func start_battle() -> void:
	turn_number = 0
	_change_phase(BattlePhase.INTRO)
	# Short delay then start first player turn
	await get_tree().create_timer(0.5).timeout
	_start_player_turn()

func start_tactician() -> void:
	_change_phase(BattlePhase.TACTICIAN)

func on_tactician_confirmed() -> void:
	## Transition from TACTICIAN to INTRO — called by battle.gd after tactician confirms.
	if current_phase == BattlePhase.TACTICIAN:
		_change_phase(BattlePhase.INTRO)

func _change_phase(new_phase: BattlePhase) -> void:
	current_phase = new_phase
	phase_changed.emit(new_phase)

func _start_player_turn() -> void:
	turn_number += 1
	_change_phase(BattlePhase.PLAYER_TURN)
	Events.turn_started.emit(turn_number, true)

func on_judgment_made(player_id: int, grade: String, combo: int, note_type: String) -> void:
	if current_phase != BattlePhase.PLAYER_TURN:
		return
	_pending_grade = grade
	_pending_note_type = note_type
	_pending_combo = combo
	_resolve_player_hit(grade, combo, note_type)

func on_note_missed(player_id: int, note_type: String) -> void:
	if current_phase != BattlePhase.PLAYER_TURN:
		return
	_enemy_attack()
	# Advance engagement on miss too
	if _engagement_manager:
		_engagement_manager.advance_engagement()

func _resolve_player_hit(grade: String, combo: int, note_type: String) -> void:
	if grade == Judgment.GRADE_MISS:
		return

	var damage_mult: float = Judgment.get_damage_multiplier(grade)
	var combo_bonus: float = 1.0 + (mini(combo, 50) * 0.02)

	# Apply result type bonuses
	var result_mult: float = 1.0
	match _attack_result_type:
		"super_strike": result_mult = 1.8
		"super_counter": result_mult = 1.5
		"directed_attack": result_mult = 1.2
		"block": result_mult = 0.5

	if note_type == "attack":
		var attacker: Node2D = null
		var target: Node2D = null

		# Use engagement manager if available, fall back to front-unit targeting
		if _engagement_manager:
			attacker = _engagement_manager.get_active_player_unit()
			if _attack_result_type == "directed_attack":
				target = enemy_army.call("get_random_alive_unit")
			else:
				target = _engagement_manager.get_active_enemy_unit()
		else:
			attacker = player_army.call("get_front_unit")
			if _attack_result_type == "directed_attack":
				target = enemy_army.call("get_random_alive_unit")
			else:
				target = enemy_army.call("get_front_unit")

		if attacker and target:
			var base_dmg: int = attacker.call("get_damage")
			var dmg: int = int(float(base_dmg) * damage_mult * combo_bonus * result_mult)
			attacker.call("change_state", 2)  # State.ATTACKING = 2
			target.call("take_damage", dmg)
			SfxManager.play("attack_hit")
			attack_resolved.emit("player", dmg, grade)
			Events.unit_attacked.emit("player", attacker.get("unit_index"), target.get("unit_index"))

		if _attack_result_type == "super_counter":
			var defender: Node2D = null
			if _engagement_manager:
				defender = _engagement_manager.get_active_player_unit()
			else:
				defender = player_army.call("get_front_unit")
			if defender:
				defender.call("apply_shield", 1)

	elif note_type == "defend":
		var defender: Node2D = null
		if _engagement_manager:
			defender = _engagement_manager.get_active_player_unit()
		else:
			defender = player_army.call("get_front_unit")
		if defender:
			defender.call("change_state", 4)  # State.DEFENDING = 4
			if _attack_result_type == "block":
				defender.call("apply_shield", 2)

	_attack_result_type = "normal"

	# Advance engagement after resolving the note
	if _engagement_manager:
		_engagement_manager.advance_engagement()

func _enemy_attack() -> void:
	var attacker: Node2D = null
	var target: Node2D = null

	if _engagement_manager:
		attacker = _engagement_manager.get_active_enemy_unit()
		target = _engagement_manager.get_active_player_unit()
	else:
		attacker = enemy_army.call("get_front_unit")
		target = player_army.call("get_front_unit")

	if attacker and target:
		var dmg: int = attacker.call("get_damage")
		attacker.call("change_state", 2)  # State.ATTACKING
		target.call("take_damage", dmg)
		SfxManager.play("attack_hit")
		attack_resolved.emit("enemy", dmg, "")
		Events.unit_attacked.emit("enemy", attacker.get("unit_index"), target.get("unit_index"))

func on_song_finished() -> void:
	_change_phase(BattlePhase.ENEMY_TURN)
	Events.turn_started.emit(turn_number, false)
	_do_enemy_turn()

func _do_enemy_turn() -> void:
	var attacks: int = 3
	# Commander action: +Speed reduces enemy attacks
	if _reduce_enemy_attacks > 0:
		attacks = maxi(1, attacks - _reduce_enemy_attacks)

	# Commander action: Sleep Frontline — skip first attack
	var skip_first := _skip_enemy_first
	_skip_enemy_first = false

	for i in attacks:
		if skip_first and i == 0:
			continue
		await get_tree().create_timer(0.4).timeout
		_enemy_attack()
		if enemy_army.call("is_defeated"):
			break
		if player_army.call("is_defeated"):
			break

	Events.turn_ended.emit(turn_number)
	_check_win()

func _check_win() -> void:
	_change_phase(BattlePhase.CHECK_WIN)

	if enemy_army.call("is_defeated"):
		_change_phase(BattlePhase.VICTORY)
		Events.battle_ended.emit("player")
	elif player_army.call("is_defeated"):
		_change_phase(BattlePhase.DEFEAT)
		Events.battle_ended.emit("enemy")
	else:
		_change_phase(BattlePhase.DRAW)
		Events.battle_ended.emit("draw")

func set_attack_result_type(result_type: String) -> void:
	_attack_result_type = result_type

func apply_commander_effects(actions_used: Array) -> void:
	## Apply commander action effects to state machine state.
	## Called by battle.gd after tactician confirms.
	var file := FileAccess.open("res://data/commander_actions.json", FileAccess.READ)
	if not file:
		return
	var data: Dictionary = JSON.parse_string(file.get_as_text())
	file.close()
	if not data.has("actions"):
		return

	for action_data in data["actions"]:
		if action_data["id"] in actions_used:
			match action_data["effect_type"]:
				"reduce_enemy_attacks":
					_reduce_enemy_attacks += action_data["value"]
				"damage_boost":
					player_army.call("apply_damage_boost_all", action_data["value"])
				"shield":
					player_army.call("apply_shield_all", action_data["value"])
				"skip_enemy_first":
					_skip_enemy_first = true
				"add_temp_unit":
					pass  # Handled at army level in battle.gd
