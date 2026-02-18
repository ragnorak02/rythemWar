extends Node2D
## Battle — scene root. Wires together armies, rhythm lane, state machine, and HUD.
## Graphics V1: shader battle background, glow separator for 2P mode.

var _player_army: Node2D = null
var _enemy_army: Node2D = null
var _rhythm_lane: Node2D = null
var _rhythm_lane_p2: Node2D = null
var _state_machine: Node = null
var _ability_system: Node = null
var _hud: CanvasLayer = null
var _chart_data: Dictionary = {}
var _battle_active: bool = false

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.06, 0.05, 0.1))
	_build_background()
	_load_chart()
	_setup_armies()
	_setup_rhythm_lane()
	_setup_state_machine()
	_setup_ability_system()
	_setup_hud()
	_setup_achievement_popup()
	_connect_signals()
	_start_battle()

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
	_state_machine.setup(_player_army, _enemy_army)

func _setup_ability_system() -> void:
	_ability_system = Node.new()
	_ability_system.set_script(preload("res://scripts/battle/ability_system.gd"))
	add_child(_ability_system)
	_ability_system.setup(_player_army, _enemy_army)

func _setup_hud() -> void:
	_hud = CanvasLayer.new()
	_hud.layer = 10
	add_child(_hud)

	var hud_script = preload("res://scripts/ui/hud.gd")
	var hud_node := Node.new()
	hud_node.set_script(hud_script)
	_hud.add_child(hud_node)
	hud_node.setup(_player_army, _enemy_army, _rhythm_lane, _ability_system)

func _setup_achievement_popup() -> void:
	var popup := CanvasLayer.new()
	popup.set_script(preload("res://scripts/ui/achievement_popup.gd"))
	add_child(popup)

func _connect_signals() -> void:
	Events.judgment_made.connect(_on_judgment_made)
	Events.note_missed.connect(_on_note_missed)
	Events.song_finished.connect(_on_song_finished)
	Events.battle_ended.connect(_on_battle_ended)
	_state_machine.attack_resolved.connect(_on_attack_resolved)

func _start_battle() -> void:
	_battle_active = true
	Events.battle_started.emit(_chart_data.get("stage_id", "unknown"))

	# Create placeholder audio and start
	var stream := _create_placeholder_audio()
	var bpm: float = _chart_data.get("bpm", 100.0)
	var offset: float = _chart_data.get("offset_sec", 0.0)
	Conductor.play_song(stream, bpm, offset)

	_state_machine.start_battle()

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

func _on_judgment_made(player_id: int, grade: String, combo: int, note_type: String) -> void:
	if player_id == 1:
		_state_machine.on_judgment_made(player_id, grade, combo, note_type)

func _on_note_missed(player_id: int, note_type: String) -> void:
	if player_id == 1:
		_state_machine.on_note_missed(player_id, note_type)

func _on_song_finished() -> void:
	if _battle_active:
		_state_machine.on_song_finished()

func _on_battle_ended(winner: String) -> void:
	_battle_active = false
	Conductor.stop_song()

	# Store results
	var results: Dictionary = _rhythm_lane.get_results()
	results["winner"] = winner
	results["stage_id"] = _chart_data.get("stage_id", "unknown")
	if _rhythm_lane_p2:
		results["p2"] = _rhythm_lane_p2.get_results()
		# In 2P mode, winner is whoever scored higher
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
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Conductor.stop_song()
		Events.scene_change_requested.emit("res://scenes/MainMenu.tscn")

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
