extends Node
## HUD — in-battle heads-up display.
## Shows player name/score/combo, army HP bars, turn info, ability cooldowns.

var _player_army: Node2D = null
var _enemy_army: Node2D = null
var _rhythm_lane: Node2D = null
var _ability_system: Node = null

# UI nodes
var _player_name_label: Label = null
var _score_label: Label = null
var _combo_label: Label = null
var _player_hp_bar_bg: ColorRect = null
var _player_hp_bar_fill: ColorRect = null
var _enemy_hp_bar_bg: ColorRect = null
var _enemy_hp_bar_fill: ColorRect = null
var _phase_label: Label = null
var _player_hp_label: Label = null
var _enemy_hp_label: Label = null
var _ability_labels: Array = []

const HP_BAR_WIDTH := 300.0
const HP_BAR_HEIGHT := 16.0

func setup(player_army: Node2D, enemy_army: Node2D, rhythm_lane: Node2D, ability_system: Node = null) -> void:
	_player_army = player_army
	_enemy_army = enemy_army
	_rhythm_lane = rhythm_lane
	_ability_system = ability_system
	_build_ui()
	Events.judgment_made.connect(_on_judgment_made)
	Events.battle_ended.connect(_on_battle_ended)
	Events.ability_activated.connect(_on_ability_activated)

func _build_ui() -> void:
	# --- Player side (top-left) ---
	_player_name_label = Label.new()
	_player_name_label.text = "YOUR ARMY"
	_player_name_label.position = Vector2(20, 10)
	_player_name_label.add_theme_font_size_override("font_size", 18)
	_player_name_label.add_theme_color_override("font_color", Color(0.3, 0.6, 1.0))
	add_child(_player_name_label)

	# Player army HP bar
	_player_hp_bar_bg = ColorRect.new()
	_player_hp_bar_bg.size = Vector2(HP_BAR_WIDTH, HP_BAR_HEIGHT)
	_player_hp_bar_bg.position = Vector2(20, 38)
	_player_hp_bar_bg.color = Color(0.15, 0.15, 0.2)
	add_child(_player_hp_bar_bg)

	_player_hp_bar_fill = ColorRect.new()
	_player_hp_bar_fill.size = Vector2(HP_BAR_WIDTH, HP_BAR_HEIGHT)
	_player_hp_bar_fill.position = Vector2(20, 38)
	_player_hp_bar_fill.color = Color(0.2, 0.7, 1.0)
	add_child(_player_hp_bar_fill)

	_player_hp_label = Label.new()
	_player_hp_label.text = "600 / 600"
	_player_hp_label.position = Vector2(25, 38)
	_player_hp_label.size = Vector2(HP_BAR_WIDTH - 10, HP_BAR_HEIGHT)
	_player_hp_label.add_theme_font_size_override("font_size", 11)
	_player_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_player_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_player_hp_label)

	# --- Enemy side (top-right) ---
	var enemy_x := 1280.0 - HP_BAR_WIDTH - 20

	var enemy_name := Label.new()
	enemy_name.text = "ENEMY ARMY"
	enemy_name.position = Vector2(enemy_x, 10)
	enemy_name.add_theme_font_size_override("font_size", 18)
	enemy_name.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	add_child(enemy_name)

	_enemy_hp_bar_bg = ColorRect.new()
	_enemy_hp_bar_bg.size = Vector2(HP_BAR_WIDTH, HP_BAR_HEIGHT)
	_enemy_hp_bar_bg.position = Vector2(enemy_x, 38)
	_enemy_hp_bar_bg.color = Color(0.15, 0.15, 0.2)
	add_child(_enemy_hp_bar_bg)

	_enemy_hp_bar_fill = ColorRect.new()
	_enemy_hp_bar_fill.size = Vector2(HP_BAR_WIDTH, HP_BAR_HEIGHT)
	_enemy_hp_bar_fill.position = Vector2(enemy_x, 38)
	_enemy_hp_bar_fill.color = Color(1.0, 0.3, 0.3)
	add_child(_enemy_hp_bar_fill)

	_enemy_hp_label = Label.new()
	_enemy_hp_label.text = "600 / 600"
	_enemy_hp_label.position = Vector2(enemy_x + 5, 38)
	_enemy_hp_label.size = Vector2(HP_BAR_WIDTH - 10, HP_BAR_HEIGHT)
	_enemy_hp_label.add_theme_font_size_override("font_size", 11)
	_enemy_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_enemy_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_enemy_hp_label)

	# --- Score & Combo (top-right area, below enemy) ---
	_score_label = Label.new()
	_score_label.text = "Score: 0"
	_score_label.position = Vector2(1080, 65)
	_score_label.add_theme_font_size_override("font_size", 20)
	_score_label.add_theme_color_override("font_color", Color(0.94, 0.78, 0.31))
	add_child(_score_label)

	_combo_label = Label.new()
	_combo_label.text = ""
	_combo_label.position = Vector2(1080, 92)
	_combo_label.add_theme_font_size_override("font_size", 16)
	_combo_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	add_child(_combo_label)

	# --- Phase indicator (top-center) ---
	_phase_label = Label.new()
	_phase_label.text = "BATTLE START"
	_phase_label.position = Vector2(490, 10)
	_phase_label.size = Vector2(300, 30)
	_phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_phase_label.add_theme_font_size_override("font_size", 22)
	_phase_label.add_theme_color_override("font_color", Color(0.94, 0.78, 0.31))
	add_child(_phase_label)

	# --- Ability bar (bottom-left) ---
	_build_ability_bar()

func _build_ability_bar() -> void:
	if not _ability_system:
		return
	var abilities: Array = _ability_system.get_abilities()
	for i in abilities.size():
		var ability: Dictionary = abilities[i]
		var label := Label.new()
		label.text = "[%d] %s" % [i + 1, ability["name"]]
		label.position = Vector2(20 + i * 160, 680)
		label.add_theme_font_size_override("font_size", 13)
		label.add_theme_color_override("font_color", Color(ability.get("color", "#ffffff")))
		add_child(label)
		_ability_labels.append(label)

func _process(_delta: float) -> void:
	_update_hp_bars()
	_update_score()
	_update_ability_labels()

func _update_hp_bars() -> void:
	if _player_army:
		var ratio: float = float(_player_army.get_total_hp()) / float(_player_army.get_max_total_hp())
		_player_hp_bar_fill.size.x = HP_BAR_WIDTH * ratio
		_player_hp_label.text = "%d / %d" % [_player_army.get_total_hp(), _player_army.get_max_total_hp()]

	if _enemy_army:
		var ratio: float = float(_enemy_army.get_total_hp()) / float(_enemy_army.get_max_total_hp())
		_enemy_hp_bar_fill.size.x = HP_BAR_WIDTH * ratio
		_enemy_hp_label.text = "%d / %d" % [_enemy_army.get_total_hp(), _enemy_army.get_max_total_hp()]

func _update_score() -> void:
	if _rhythm_lane:
		_score_label.text = "Score: %d" % _rhythm_lane.score
		if _rhythm_lane.combo >= 2:
			_combo_label.text = "%d COMBO" % _rhythm_lane.combo
		else:
			_combo_label.text = ""

func _update_ability_labels() -> void:
	if not _ability_system:
		return
	var abilities: Array = _ability_system.get_abilities()
	for i in _ability_labels.size():
		if i >= abilities.size():
			break
		var cd: int = _ability_system.get_cooldown(abilities[i]["id"])
		var label: Label = _ability_labels[i]
		if cd > 0:
			label.text = "[%d] %s (CD:%d)" % [i + 1, abilities[i]["name"], cd]
			label.modulate.a = 0.4
		else:
			label.text = "[%d] %s READY" % [i + 1, abilities[i]["name"]]
			label.modulate.a = 1.0

func _on_judgment_made(_player_id: int, grade: String, _combo: int, _note_type: String) -> void:
	_phase_label.text = grade
	_phase_label.add_theme_color_override("font_color", Judgment.get_grade_color(grade))

func _on_battle_ended(winner: String) -> void:
	match winner:
		"player":
			_phase_label.text = "VICTORY!"
			_phase_label.add_theme_color_override("font_color", Color(0.94, 0.78, 0.31))
		"enemy":
			_phase_label.text = "DEFEAT"
			_phase_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
		_:
			_phase_label.text = "DRAW"
			_phase_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))

func _on_ability_activated(_player_id: int, ability_id: String) -> void:
	# Flash ability name on screen
	_phase_label.text = ability_id.replace("_", " ").to_upper()
	_phase_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.8))
