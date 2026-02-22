extends Node2D
## Battle — scene root. Wires together armies, rhythm lane, state machine, and HUD.
## Graphics V1: shader battle background, glow separator for 2P mode.
## Two-phase startup: Phase A (immediate) → Tactician Mode → Phase B (after confirm).

var _player_army: Node2D = null
var _enemy_army: Node2D = null
var _rhythm_lane: Node2D = null
var _rhythm_lane_p2: Node2D = null
var _state_machine: Node = null
var _ability_system: Node = null
var _hud: CanvasLayer = null
var _chart_data: Dictionary = {}
var _battle_active: bool = false
var _pause_menu: CanvasLayer = null
var _is_paused: bool = false
var _current_round: int = 0
var _round_results: Array = []
var _between_round_panel: CanvasLayer = null

# New systems
var _tactician_mode: CanvasLayer = null
var _tactician_mode_p2: CanvasLayer = null
var _engagement_manager: Node2D = null
var _telegraph_coordinator_active: bool = false
var _tactician_config: Dictionary = {}
var _p1_confirmed: bool = false
var _p2_confirmed: bool = false

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.06, 0.05, 0.1))
	# Phase A — immediate setup
	_build_background()
	_load_chart()
	_setup_armies()
	_setup_hud_basic()
	_setup_achievement_popup()
	# Enter tactician mode
	_setup_tactician_mode()

func _build_background() -> void:
	var bg := ColorRect.new()
	bg.size = Vector2(1280, 720)
	bg.position = Vector2.ZERO
	bg.z_index = -10
	var bg_shader := load("res://assets/shaders/battle_bg.gdshader")
	if bg_shader:
		var mat := ShaderMaterial.new()
		mat.shader = bg_shader
		bg.material = mat
	else:
		bg.color = Color(0.06, 0.05, 0.1)
	add_child(bg)

func _load_chart() -> void:
	var stage_id: String = GameManager.selected_stage
	if stage_id.is_empty():
		stage_id = "easy_01"
	var path := "res://data/charts/stage_%s.json" % stage_id
	var file := FileAccess.open(path, FileAccess.READ)
	if file:
		_chart_data = JSON.parse_string(file.get_as_text())
		file.close()
	else:
		# Fallback to easy
		file = FileAccess.open("res://data/charts/stage_easy_01.json", FileAccess.READ)
		if file:
			_chart_data = JSON.parse_string(file.get_as_text())
			file.close()

func _setup_armies() -> void:
	# Player army — left side
	_player_army = Node2D.new()
	_player_army.set_script(preload("res://scripts/battle/army.gd"))
	_player_army.position = Vector2(200, 280)
	add_child(_player_army)
	_player_army.setup("player")

	# Enemy army — right side
	_enemy_army = Node2D.new()
	_enemy_army.set_script(preload("res://scripts/battle/army.gd"))
	_enemy_army.position = Vector2(1080, 280)
	add_child(_enemy_army)
	_enemy_army.setup("enemy")

func _setup_hud_basic() -> void:
	## Phase A HUD — HP bars visible behind tactician panel.
	_hud = CanvasLayer.new()
	_hud.layer = 10
	add_child(_hud)

func _setup_hud_full() -> void:
	## Phase B HUD — full HUD with score, combo, ability bar.
	var hud_script = preload("res://scripts/ui/hud.gd")
	var hud_node := Node.new()
	hud_node.set_script(hud_script)
	_hud.add_child(hud_node)
	hud_node.setup(_player_army, _enemy_army, _rhythm_lane, _ability_system)

func _setup_achievement_popup() -> void:
	var popup := CanvasLayer.new()
	popup.set_script(preload("res://scripts/ui/achievement_popup.gd"))
	add_child(popup)

func _setup_tactician_mode() -> void:
	## Open tactician mode panel(s). Battle waits for confirmation.
	if GameManager.is_2p:
		# P1 panel on left half
		_tactician_mode = CanvasLayer.new()
		_tactician_mode.set_script(preload("res://scripts/battle/tactician_mode.gd"))
		add_child(_tactician_mode)
		_tactician_mode.setup(1, 40.0)
		_tactician_mode.confirmed.connect(_on_tactician_confirmed)
		_tactician_mode.fled.connect(_on_tactician_fled)

		# P2 panel on right half
		_tactician_mode_p2 = CanvasLayer.new()
		_tactician_mode_p2.set_script(preload("res://scripts/battle/tactician_mode.gd"))
		add_child(_tactician_mode_p2)
		_tactician_mode_p2.setup(2, 680.0)
		_tactician_mode_p2.confirmed.connect(_on_tactician_confirmed)
		_tactician_mode_p2.fled.connect(_on_tactician_fled)
	else:
		# 1P — single panel
		_tactician_mode = CanvasLayer.new()
		_tactician_mode.set_script(preload("res://scripts/battle/tactician_mode.gd"))
		add_child(_tactician_mode)
		_tactician_mode.setup(1)
		_tactician_mode.confirmed.connect(_on_tactician_confirmed)
		_tactician_mode.fled.connect(_on_tactician_fled)

func _on_tactician_confirmed(player_id: int, config: Dictionary) -> void:
	if player_id == 1:
		_p1_confirmed = true
		_tactician_config = config
	elif player_id == 2:
		_p2_confirmed = true

	# In 1P mode, start immediately. In 2P, wait for both.
	if GameManager.is_2p:
		if _p1_confirmed and _p2_confirmed:
			_start_phase_b()
	else:
		if _p1_confirmed:
			_start_phase_b()

func _on_tactician_fled(player_id: int) -> void:
	# Return to stage select
	Conductor.stop_song()
	Events.scene_change_requested.emit("res://scenes/StageSelect.tscn")

func _start_phase_b() -> void:
	## Phase B — after tactician confirms, set up the real battle.
	# Store config
	GameManager.tactician_config = _tactician_config

	# Close tactician panels
	if _tactician_mode:
		_tactician_mode.close()
		_tactician_mode = null
	if _tactician_mode_p2:
		_tactician_mode_p2.close()
		_tactician_mode_p2 = null

	# Apply aggression effects
	_apply_aggression(_tactician_config.get("aggression", "normal"))

	# Apply flee penalty
	if _tactician_config.get("flee_penalty", false):
		# Enemy gets a free hit at battle start
		var enemy_front: Node2D = _enemy_army.get_front_unit()
		var player_front: Node2D = _player_army.get_front_unit()
		if enemy_front and player_front:
			player_front.take_damage(enemy_front.get_damage())

	# Setup engagement manager
	var formation: String = _tactician_config.get("formation", "solo")
	_setup_engagement_manager(formation)

	# Redistribute units to engagement positions
	_engagement_manager.redistribute_units()

	# Wait for redistribution animation
	await get_tree().create_timer(1.0).timeout

	# Setup rhythm lane (delayed until after tactician)
	_setup_rhythm_lane()

	# Setup telegraph system
	_setup_telegraph()

	# Setup state machine with engagement manager
	_setup_state_machine()

	# Apply commander action effects
	var actions_used: Array = _tactician_config.get("commander_actions_used", [])
	if actions_used.size() > 0:
		_state_machine.apply_commander_effects(actions_used)

	# Setup ability system
	_setup_ability_system()

	# Full HUD
	_setup_hud_full()

	# Connect signals and start
	_connect_signals()
	_start_round()

func _apply_aggression(aggression: String) -> void:
	if aggression == "high":
		# +20% damage, -15% defense for all player units
		for unit in _player_army.get_alive_units():
			unit.base_damage = int(float(unit.base_damage) * 1.2)
			unit.defense = int(float(unit.defense) * 0.85)

func _setup_engagement_manager(formation: String) -> void:
	_engagement_manager = Node2D.new()
	_engagement_manager.set_script(preload("res://scripts/battle/engagement_manager.gd"))
	add_child(_engagement_manager)
	_engagement_manager.setup(_player_army, _enemy_army, formation)

func _setup_telegraph() -> void:
	## Attach telegraph nodes to all player units.
	_telegraph_coordinator_active = true
	var telegraph_script = preload("res://scripts/rhythm/unit_telegraph.gd")
	for unit in _player_army.get_alive_units():
		var telegraph := Node2D.new()
		telegraph.set_script(telegraph_script)
		unit.attach_telegraph(telegraph)

func _setup_rhythm_lane() -> void:
	if GameManager.is_2p:
		_setup_2p_layout()
	else:
		_rhythm_lane = Node2D.new()
		_rhythm_lane.set_script(preload("res://scripts/rhythm/rhythm_lane.gd"))
		_rhythm_lane.position = Vector2(200, 550)
		add_child(_rhythm_lane)
		_rhythm_lane.setup_lane(1)
		_rhythm_lane.load_chart(_chart_data)

func _setup_2p_layout() -> void:
	# P1 lane — top half
	_rhythm_lane = Node2D.new()
	_rhythm_lane.set_script(preload("res://scripts/rhythm/rhythm_lane.gd"))
	_rhythm_lane.position = Vector2(200, 480)
	add_child(_rhythm_lane)
	_rhythm_lane.setup_lane(1)
	_rhythm_lane.load_chart(_chart_data)

	# Separator line with glow shader
	var separator := ColorRect.new()
	separator.size = Vector2(880, 10)
	separator.position = Vector2(200, 516)
	var sep_shader := load("res://assets/shaders/separator_glow.gdshader")
	if sep_shader:
		var mat := ShaderMaterial.new()
		mat.shader = sep_shader
		separator.material = mat
	else:
		separator.color = Color(0.4, 0.4, 0.5, 0.5)
	add_child(separator)

	# P2 lane — bottom half
	_rhythm_lane_p2 = Node2D.new()
	_rhythm_lane_p2.set_script(preload("res://scripts/rhythm/rhythm_lane.gd"))
	_rhythm_lane_p2.position = Vector2(200, 600)
	add_child(_rhythm_lane_p2)
	_rhythm_lane_p2.setup_lane(2)
	_rhythm_lane_p2.load_chart(_chart_data)

func _setup_state_machine() -> void:
	_state_machine = Node.new()
	_state_machine.set_script(preload("res://scripts/battle/battle_state_machine.gd"))
	add_child(_state_machine)
	_state_machine.setup(_player_army, _enemy_army, _engagement_manager)

func _setup_ability_system() -> void:
	_ability_system = Node.new()
	_ability_system.set_script(preload("res://scripts/battle/ability_system.gd"))
	add_child(_ability_system)
	_ability_system.setup(_player_army, _enemy_army)

func _connect_signals() -> void:
	Events.judgment_made.connect(_on_judgment_made)
	Events.note_missed.connect(_on_note_missed)
	Events.song_finished.connect(_on_song_finished)
	Events.battle_ended.connect(_on_battle_ended)
	Events.round_completed.connect(_on_round_completed)
	_state_machine.attack_resolved.connect(_on_attack_resolved)

func _start_round() -> void:
	_current_round += 1
	_battle_active = true
	Events.round_started.emit(_current_round)

	if _current_round == 1:
		Events.battle_started.emit(_chart_data.get("stage_id", "unknown"))

	# Create placeholder audio and start
	var stream := _create_placeholder_audio()
	var bpm: float = _chart_data.get("bpm", 100.0)
	var offset: float = _chart_data.get("offset_sec", 0.0)
	Conductor.play_song(stream, bpm, offset)

	if _current_round == 1:
		_state_machine.start_battle()
	else:
		_state_machine.start_new_round()

func _create_placeholder_audio() -> AudioStream:
	var sample_rate := 44100
	var duration := 15.0
	var num_samples := int(sample_rate * duration)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	var data := PackedByteArray()
	data.resize(num_samples)
	data.fill(128)
	stream.data = data
	return stream

func _process(_delta: float) -> void:
	if _is_paused:
		return
	# Telegraph coordinator — shows button prompts above active engagement unit
	if _telegraph_coordinator_active and _battle_active and _rhythm_lane and _engagement_manager:
		_update_telegraph()

func _update_telegraph() -> void:
	## Reads upcoming notes from spawner, shows button icon above active engagement unit.
	var spawner: Node = _rhythm_lane.get("_spawner")
	if not spawner:
		return

	# Get the next unhit note within lookahead (1.5s)
	var lookahead := 1.5
	var upcoming: Array = spawner.get_notes_near_time(Conductor.song_position + lookahead * 0.5, lookahead)

	# Find the earliest unhit note
	var next_note: Node2D = null
	var earliest_time: float = INF
	for note in upcoming:
		if is_instance_valid(note) and not note.was_hit and not note.was_missed:
			if note.note_time < earliest_time:
				earliest_time = note.note_time
				next_note = note

	# Get active player unit from engagement
	var active_unit: Node2D = _engagement_manager.get_active_player_unit()
	if not active_unit:
		return

	if next_note:
		var time_until: float = next_note.note_time - Conductor.song_position
		active_unit.show_telegraph_button(next_note.button, time_until)

		# Hide telegraph on all other player units
		for unit in _player_army.get_alive_units():
			if unit != active_unit:
				unit.hide_telegraph()
	else:
		active_unit.hide_telegraph()

func _on_judgment_made(player_id: int, grade: String, combo: int, note_type: String) -> void:
	if player_id == 1:
		_state_machine.on_judgment_made(player_id, grade, combo, note_type)

		# Telegraph feedback on active unit
		if _engagement_manager:
			var active_unit: Node2D = _engagement_manager.get_active_player_unit()
			if active_unit:
				active_unit.show_telegraph_feedback(grade)

func _on_note_missed(player_id: int, note_type: String) -> void:
	if player_id == 1:
		_state_machine.on_note_missed(player_id, note_type)

		# Telegraph feedback
		if _engagement_manager:
			var active_unit: Node2D = _engagement_manager.get_active_player_unit()
			if active_unit:
				active_unit.show_telegraph_feedback(Judgment.GRADE_MISS)

func _on_song_finished() -> void:
	if _battle_active:
		_state_machine.on_song_finished()

func _on_round_completed(_round_number: int, _player_hp: int, _enemy_hp: int) -> void:
	_battle_active = false
	_telegraph_coordinator_active = false
	Conductor.stop_song()

	# Store this round's rhythm results
	_round_results.append(_rhythm_lane.get_results())

	# Tick buffs and cooldowns between rounds
	_player_army.tick_all_buffs()
	_enemy_army.tick_all_buffs()
	if _ability_system:
		_ability_system.tick_cooldowns()

	# Show between-round panel
	_between_round_panel = CanvasLayer.new()
	_between_round_panel.set_script(preload("res://scripts/battle/between_round_panel.gd"))
	add_child(_between_round_panel)
	_between_round_panel.setup(
		_current_round,
		_player_army.get_total_hp(),
		_player_army.get_max_total_hp(),
		_enemy_army.get_total_hp(),
		_enemy_army.get_max_total_hp()
	)
	_between_round_panel.stance_confirmed.connect(_on_stance_confirmed)

func _on_stance_confirmed(stance: String) -> void:
	if _between_round_panel:
		_between_round_panel.close()
		_between_round_panel = null

	_apply_stance(stance)

	# Reload chart on rhythm lane for next round
	_rhythm_lane.load_chart(_chart_data)

	# Re-setup engagement manager for surviving units
	_engagement_manager.setup(_player_army, _enemy_army, _tactician_config.get("formation", "solo"))
	_engagement_manager.redistribute_units()

	# Brief delay before next round
	await get_tree().create_timer(0.8).timeout
	_telegraph_coordinator_active = true
	_start_round()

func _apply_stance(stance: String) -> void:
	match stance:
		"all_offense":
			_player_army.apply_damage_boost_all(1)
		"all_defense":
			_player_army.apply_shield_all(1)
		"balanced":
			pass
		"regroup":
			_player_army.heal_all(15)

func _build_cumulative_results() -> Dictionary:
	## Combine rhythm results across all rounds into cumulative totals.
	var cumulative := {
		"score": 0,
		"combo": 0,
		"perfects": 0,
		"greats": 0,
		"goods": 0,
		"bads": 0,
		"misses": 0,
		"total_notes": 0,
	}
	for rd in _round_results:
		cumulative["score"] += rd.get("score", 0)
		cumulative["combo"] = maxi(cumulative["combo"], rd.get("combo", 0))
		cumulative["perfects"] += rd.get("perfects", 0)
		cumulative["greats"] += rd.get("greats", 0)
		cumulative["goods"] += rd.get("goods", 0)
		cumulative["bads"] += rd.get("bads", 0)
		cumulative["misses"] += rd.get("misses", 0)
		cumulative["total_notes"] += rd.get("total_notes", 0)

	var total: int = cumulative["total_notes"]
	var hits: int = total - cumulative["misses"]
	cumulative["accuracy"] = (float(hits) / float(maxi(total, 1))) * 100.0
	return cumulative

func _on_battle_ended(winner: String) -> void:
	_battle_active = false
	_telegraph_coordinator_active = false
	Conductor.stop_song()
	if winner == "player":
		SfxManager.play("battle_victory")
	else:
		SfxManager.play("battle_defeat")

	# Store final round results
	_round_results.append(_rhythm_lane.get_results())

	# Build cumulative results across all rounds
	var results: Dictionary = _build_cumulative_results()
	results["winner"] = winner
	results["stage_id"] = _chart_data.get("stage_id", "unknown")
	results["total_rounds"] = _current_round
	results["round_details"] = _round_results
	results["player_id"] = 1
	if _rhythm_lane_p2:
		results["p2"] = _rhythm_lane_p2.get_results()
		if results["p2"]["score"] > results["score"]:
			results["winner"] = "player2"
	GameManager.last_results = results
	GameManager.record_battle_result(
		results["stage_id"],
		results["score"],
		results["combo"],
		winner == "player"
	)

	# Transition to results screen after delay
	await get_tree().create_timer(1.5).timeout
	Events.scene_change_requested.emit("res://scenes/Results.tscn")

func _on_attack_resolved(attacker_side: String, damage: int, grade: String) -> void:
	# Could spawn damage number popup here
	pass

func _input(event: InputEvent) -> void:
	# Block input while paused (pause_menu handles resume via signals)
	if _is_paused:
		return

	# Pause
	if event.is_action_pressed("ui_pause") and _battle_active:
		get_viewport().set_input_as_handled()
		_pause_battle()
		return

	# Ability hotkeys: 1-4
	if event is InputEventKey and event.pressed and _battle_active:
		var abilities: Array = _ability_system.get_abilities()
		var key_index := -1
		match event.keycode:
			KEY_1: key_index = 0
			KEY_2: key_index = 1
			KEY_3: key_index = 2
			KEY_4: key_index = 3
		if key_index >= 0 and key_index < abilities.size():
			_ability_system.activate(1, abilities[key_index]["id"])

func _pause_battle() -> void:
	_is_paused = true
	Conductor.pause_song()
	get_tree().paused = true
	Events.game_paused.emit()

	_pause_menu = CanvasLayer.new()
	_pause_menu.set_script(preload("res://scripts/ui/pause_menu.gd"))
	add_child(_pause_menu)
	_pause_menu.resumed.connect(_resume_battle)
	_pause_menu.restarted.connect(_restart_battle)
	_pause_menu.quit_to_menu.connect(_quit_to_menu)

func _resume_battle() -> void:
	if _pause_menu:
		_pause_menu.queue_free()
		_pause_menu = null
	get_tree().paused = false
	Conductor.resume_song()
	_is_paused = false
	Events.game_resumed.emit()

func _restart_battle() -> void:
	if _pause_menu:
		_pause_menu.queue_free()
		_pause_menu = null
	get_tree().paused = false
	_is_paused = false
	Conductor.stop_song()
	Events.scene_change_requested.emit("res://scenes/Battle.tscn")

func _quit_to_menu() -> void:
	if _pause_menu:
		_pause_menu.queue_free()
		_pause_menu = null
	get_tree().paused = false
	_is_paused = false
	Conductor.stop_song()
	Events.scene_change_requested.emit("res://scenes/MainMenu.tscn")
