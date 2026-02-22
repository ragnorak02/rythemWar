extends Node
## HUD — in-battle heads-up display.
## Graphics V1: styled HP bars with beveled frames, team icons.

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
var _ability_containers: Array = []
var _round_label: Label = null

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
	Events.round_started.connect(_on_round_started)

func _build_ui() -> void:
	# --- Player side (top-left) ---
	_player_name_label = Label.new()
	_player_name_label.text = "YOUR ARMY"
	_player_name_label.position = Vector2(20, 10)
	_player_name_label.add_theme_font_size_override("font_size", 18)
	_player_name_label.add_theme_color_override("font_color", Color(0.3, 0.6, 1.0))
	add_child(_player_name_label)

	# Player HP bar — styled with border frame
	_build_hp_bar(Vector2(20, 38), Color(0.2, 0.7, 1.0), true)

	# Player HP text
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

	# Enemy HP bar — styled with border frame
	_build_hp_bar(Vector2(enemy_x, 38), Color(1.0, 0.3, 0.3), false)

	# Enemy HP text
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

	# --- Round label (top-center, above phase) ---
	_round_label = Label.new()
	_round_label.text = "ROUND 1"
	_round_label.position = Vector2(560, 35)
	_round_label.size = Vector2(160, 24)
	_round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_round_label.add_theme_font_size_override("font_size", 14)
	_round_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	add_child(_round_label)

	# --- Ability bar (bottom-left) ---
	_build_ability_bar()

func _build_hp_bar(pos: Vector2, fill_color: Color, is_player: bool) -> void:
	# Outer border frame
	var frame := ColorRect.new()
	frame.size = Vector2(HP_BAR_WIDTH + 4, HP_BAR_HEIGHT + 4)
	frame.position = pos - Vector2(2, 2)
	frame.color = Color(0.35, 0.35, 0.45, 0.7)
	add_child(frame)

	# Inner border (dark inset)
	var inset := ColorRect.new()
	inset.size = Vector2(HP_BAR_WIDTH + 2, HP_BAR_HEIGHT + 2)
	inset.position = pos - Vector2(1, 1)
	inset.color = Color(0.08, 0.08, 0.12)
	add_child(inset)

	# Background
	var bg := ColorRect.new()
	bg.size = Vector2(HP_BAR_WIDTH, HP_BAR_HEIGHT)
	bg.position = pos
	bg.color = Color(0.12, 0.12, 0.18)
	add_child(bg)

	# Fill
	var fill := ColorRect.new()
	fill.size = Vector2(HP_BAR_WIDTH, HP_BAR_HEIGHT)
	fill.position = pos
	fill.color = fill_color
	add_child(fill)

	# Highlight stripe (top of bar for bevel effect)
	var highlight := ColorRect.new()
	highlight.size = Vector2(HP_BAR_WIDTH, 3)
	highlight.position = pos
	highlight.color = Color(1.0, 1.0, 1.0, 0.1)
	add_child(highlight)

	if is_player:
		_player_hp_bar_bg = bg
		_player_hp_bar_fill = fill
	else:
		_enemy_hp_bar_bg = bg
		_enemy_hp_bar_fill = fill

func _build_ability_bar() -> void:
	if not _ability_system:
		return

	# Ability bar background
	var bar_bg := ColorRect.new()
	bar_bg.size = Vector2(1060, 36)
	bar_bg.position = Vector2(10, 670)
	bar_bg.color = Color(0.06, 0.05, 0.1, 0.7)
	add_child(bar_bg)

	# Xbox button colors (jewel style)
	var ctrl_labels: Array[String] = ["LB", "RB", "LT", "RT"]
	var ctrl_colors: Array[Color] = [
		Color(0.35, 0.35, 0.4),   # LB — charcoal
		Color(0.35, 0.35, 0.4),   # RB — charcoal
		Color(0.35, 0.35, 0.4),   # LT — charcoal
		Color(0.35, 0.35, 0.4),   # RT — charcoal
	]
	var key_colors: Array[Color] = [
		Color(0.2, 0.22, 0.3),    # 1
		Color(0.2, 0.22, 0.3),    # 2
		Color(0.2, 0.22, 0.3),    # 3
		Color(0.2, 0.22, 0.3),    # 4
	]

	var abilities: Array = _ability_system.get_abilities()
	for i in abilities.size():
		var ability: Dictionary = abilities[i]
		var x_base: float = 20.0 + i * 260.0
		var y_base: float = 674.0

		# Container for whole ability entry (for opacity control)
		var container := Control.new()
		container.position = Vector2(x_base, y_base)
		container.size = Vector2(250, 28)
		add_child(container)
		_ability_containers.append(container)

		# Keyboard key badge — small rounded square
		var kb_color: Color = key_colors[i] if i < key_colors.size() else Color(0.2, 0.22, 0.3)
		var kb_badge := _create_jewel_badge(str(i + 1), kb_color, 24.0, 24.0)
		kb_badge.position = Vector2(0, 2)
		container.add_child(kb_badge)

		# Xbox controller badge — pill shape
		var ctrl_text: String = ctrl_labels[i] if i < ctrl_labels.size() else ""
		var ctrl_color: Color = ctrl_colors[i] if i < ctrl_colors.size() else Color(0.35, 0.35, 0.4)
		var ctrl_badge := _create_jewel_badge(ctrl_text, ctrl_color, 36.0, 24.0)
		ctrl_badge.position = Vector2(28, 2)
		container.add_child(ctrl_badge)

		# Ability name label
		var label := Label.new()
		label.text = ability["name"] + " READY"
		label.position = Vector2(68, 2)
		label.size = Vector2(180, 24)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 13)
		label.add_theme_color_override("font_color", Color(ability.get("color", "#ffffff")))
		container.add_child(label)
		_ability_labels.append(label)

func _create_jewel_badge(text: String, bg_color: Color, w: float, h: float) -> Panel:
	var panel := Panel.new()
	panel.size = Vector2(w, h)

	var style := StyleBoxFlat.new()
	style.bg_color = bg_color

	# Rounded corners — fully round for square badges, pill for wide ones
	var radius := int(h / 2.0)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius

	# Subtle border for jewel edge
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_color = bg_color.lightened(0.35)

	# Inner shadow at bottom for 3D jewel look
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 1
	style.shadow_offset = Vector2(0, 1)

	panel.add_theme_stylebox_override("panel", style)

	# Letter label centered inside
	var lbl := Label.new()
	lbl.text = text
	lbl.size = Vector2(w, h)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	panel.add_child(lbl)

	return panel

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
		var container: Control = _ability_containers[i]
		if cd > 0:
			label.text = "%s (CD:%d)" % [abilities[i]["name"], cd]
			container.modulate.a = 0.4
		else:
			label.text = "%s READY" % abilities[i]["name"]
			container.modulate.a = 1.0

func _on_judgment_made(_player_id: int, grade: String, _combo: int, _note_type: String) -> void:
	_phase_label.text = grade
	_phase_label.add_theme_color_override("font_color", Judgment.get_grade_color(grade))

func _on_battle_ended(winner: String) -> void:
	match winner:
		"player":
			_phase_label.text = "VICTORY!"
			_phase_label.add_theme_color_override("font_color", Color(0.94, 0.78, 0.31))
		_:
			_phase_label.text = "DEFEAT"
			_phase_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))

func _on_round_started(round_number: int) -> void:
	_round_label.text = "ROUND %d" % round_number

func _on_ability_activated(_player_id: int, ability_id: String) -> void:
	# Flash ability name on screen
	_phase_label.text = ability_id.replace("_", " ").to_upper()
	_phase_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.8))
