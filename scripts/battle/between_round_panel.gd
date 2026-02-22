extends CanvasLayer
## BetweenRoundPanel — shown between rounds when both armies survive.
## Player selects a stance that applies a buff for the next round.
## Follows tactician_mode.gd UI pattern (dark panel + gold border, row navigation).

signal stance_confirmed(stance: String)

var _round_number: int = 0
var _player_hp: int = 0
var _player_max_hp: int = 0
var _enemy_hp: int = 0
var _enemy_max_hp: int = 0

var _rows: Array = []
var _selected_row: int = 0
var _is_active: bool = false

const STANCES := [
	{"id": "all_offense", "name": "All Offense", "desc": "+50% damage next round"},
	{"id": "all_defense", "name": "All Defense", "desc": "Shield all units next round (half damage)"},
	{"id": "balanced", "name": "Balanced", "desc": "No modifier"},
	{"id": "regroup", "name": "Regroup", "desc": "Heal all units by 15 HP"},
]

# Layout
const PANEL_W := 600.0
const PANEL_H := 420.0
const PANEL_X := 340.0
const PANEL_Y := 150.0
const ROW_HEIGHT := 48.0
const LABEL_X := 30.0

# Colors (match tactician_mode.gd)
const BORDER_COLOR := Color(0.94, 0.65, 0.15)
const BG_COLOR := Color(0.06, 0.08, 0.18, 0.92)
const SELECTED_ROW_COLOR := Color(0.15, 0.18, 0.35, 0.6)
const LABEL_COLOR := Color(0.95, 0.92, 0.82)
const HINT_COLOR := Color(0.6, 0.6, 0.7, 0.7)
const GOLD := Color(0.94, 0.78, 0.31)
const PLAYER_BAR_COLOR := Color(0.2, 0.7, 1.0)
const ENEMY_BAR_COLOR := Color(1.0, 0.3, 0.3)

func _ready() -> void:
	layer = 20

func setup(round_num: int, player_hp: int, player_max_hp: int, enemy_hp: int, enemy_max_hp: int) -> void:
	_round_number = round_num
	_player_hp = player_hp
	_player_max_hp = player_max_hp
	_enemy_hp = enemy_hp
	_enemy_max_hp = enemy_max_hp
	_build_panel()
	_is_active = true

func _build_panel() -> void:
	# Border
	var border := ColorRect.new()
	border.size = Vector2(PANEL_W + 6, PANEL_H + 6)
	border.position = Vector2(PANEL_X - 3, PANEL_Y - 3)
	border.color = BORDER_COLOR
	add_child(border)

	# Background
	var bg := ColorRect.new()
	bg.size = Vector2(PANEL_W, PANEL_H)
	bg.position = Vector2(PANEL_X, PANEL_Y)
	bg.color = BG_COLOR
	add_child(bg)

	var y := 0.0

	# Title
	var title := Label.new()
	title.text = "ROUND %d COMPLETE" % _round_number
	title.position = Vector2(PANEL_X, PANEL_Y + 12)
	title.size = Vector2(PANEL_W, 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", GOLD)
	add_child(title)
	y += 50.0

	# Army HP bars
	_build_hp_display(PANEL_X + 40, PANEL_Y + y, "YOUR ARMY", _player_hp, _player_max_hp, PLAYER_BAR_COLOR)
	_build_hp_display(PANEL_X + PANEL_W / 2 + 10, PANEL_Y + y, "ENEMY ARMY", _enemy_hp, _enemy_max_hp, ENEMY_BAR_COLOR)
	y += 55.0

	# Separator
	var sep := ColorRect.new()
	sep.size = Vector2(PANEL_W - 40, 1)
	sep.position = Vector2(PANEL_X + 20, PANEL_Y + y)
	sep.color = Color(0.3, 0.3, 0.4, 0.4)
	add_child(sep)
	y += 12.0

	# "SELECT STANCE" header
	var header := Label.new()
	header.text = "SELECT STANCE"
	header.position = Vector2(PANEL_X, PANEL_Y + y)
	header.size = Vector2(PANEL_W, 28)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 18)
	header.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	add_child(header)
	y += 32.0

	# Stance rows
	_rows.clear()
	for i in STANCES.size():
		var stance: Dictionary = STANCES[i]
		var row_y := PANEL_Y + y

		# Highlight bg
		var highlight := ColorRect.new()
		highlight.size = Vector2(PANEL_W - 20, ROW_HEIGHT - 4)
		highlight.position = Vector2(PANEL_X + 10, row_y)
		highlight.color = SELECTED_ROW_COLOR
		highlight.visible = false
		add_child(highlight)

		# Name
		var name_label := Label.new()
		name_label.text = stance["name"]
		name_label.position = Vector2(PANEL_X + LABEL_X, row_y + 10)
		name_label.add_theme_font_size_override("font_size", 20)
		name_label.add_theme_color_override("font_color", LABEL_COLOR)
		add_child(name_label)

		# Description
		var desc_label := Label.new()
		desc_label.text = stance["desc"]
		desc_label.position = Vector2(PANEL_X + LABEL_X + 200, row_y + 14)
		desc_label.add_theme_font_size_override("font_size", 14)
		desc_label.add_theme_color_override("font_color", HINT_COLOR)
		add_child(desc_label)

		_rows.append({"highlight": highlight, "stance_id": stance["id"]})
		y += ROW_HEIGHT

	# Confirm row
	y += 8.0
	var confirm_y := PANEL_Y + y
	var confirm_highlight := ColorRect.new()
	confirm_highlight.size = Vector2(PANEL_W - 20, ROW_HEIGHT - 4)
	confirm_highlight.position = Vector2(PANEL_X + 10, confirm_y)
	confirm_highlight.color = SELECTED_ROW_COLOR
	confirm_highlight.visible = false
	add_child(confirm_highlight)

	var confirm_label := Label.new()
	confirm_label.text = ">> BEGIN ROUND %d <<" % (_round_number + 1)
	confirm_label.position = Vector2(PANEL_X, confirm_y + 10)
	confirm_label.size = Vector2(PANEL_W, 28)
	confirm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirm_label.add_theme_font_size_override("font_size", 20)
	confirm_label.add_theme_color_override("font_color", GOLD)
	add_child(confirm_label)

	_rows.append({"highlight": confirm_highlight, "stance_id": "_confirm"})
	y += ROW_HEIGHT + 8.0

	# Control hints
	var hints := Label.new()
	hints.text = "D-pad / Arrows — Navigate  |  A / Enter — Select"
	hints.position = Vector2(PANEL_X, PANEL_Y + PANEL_H - 28)
	hints.size = Vector2(PANEL_W, 20)
	hints.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hints.add_theme_font_size_override("font_size", 12)
	hints.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	add_child(hints)

	_selected_row = 0
	_update_selection()

func _build_hp_display(x: float, y: float, title: String, hp: int, max_hp: int, color: Color) -> void:
	var bar_w := 240.0
	var bar_h := 14.0

	var lbl := Label.new()
	lbl.text = title
	lbl.position = Vector2(x, y)
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", color)
	add_child(lbl)

	# Bar background
	var bg := ColorRect.new()
	bg.size = Vector2(bar_w, bar_h)
	bg.position = Vector2(x, y + 22)
	bg.color = Color(0.12, 0.12, 0.18)
	add_child(bg)

	# Bar fill
	var ratio := float(hp) / float(maxi(max_hp, 1))
	var fill := ColorRect.new()
	fill.size = Vector2(bar_w * ratio, bar_h)
	fill.position = Vector2(x, y + 22)
	fill.color = color
	add_child(fill)

	# HP text
	var hp_label := Label.new()
	hp_label.text = "%d / %d" % [hp, max_hp]
	hp_label.position = Vector2(x, y + 22)
	hp_label.size = Vector2(bar_w, bar_h)
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp_label.add_theme_font_size_override("font_size", 10)
	add_child(hp_label)

func _update_selection() -> void:
	for i in _rows.size():
		_rows[i]["highlight"].visible = (i == _selected_row)

func _input(event: InputEvent) -> void:
	if not _is_active:
		return

	# Up
	if event.is_action_pressed("p1_up") or (event is InputEventKey and event.pressed and event.keycode == KEY_UP):
		_selected_row = maxi(0, _selected_row - 1)
		_update_selection()
		SfxManager.play("ui_navigate")
		get_viewport().set_input_as_handled()
		return

	# Down
	if event.is_action_pressed("p1_down") or (event is InputEventKey and event.pressed and event.keycode == KEY_DOWN):
		_selected_row = mini(_rows.size() - 1, _selected_row + 1)
		_update_selection()
		SfxManager.play("ui_navigate")
		get_viewport().set_input_as_handled()
		return

	# Confirm
	if event.is_action_pressed("p1_face_a") or (event is InputEventKey and event.pressed and event.keycode == KEY_ENTER):
		_activate_row()
		get_viewport().set_input_as_handled()
		return

func _activate_row() -> void:
	var row: Dictionary = _rows[_selected_row]
	if row["stance_id"] == "_confirm":
		# Use the currently highlighted stance (default to balanced if on confirm row)
		# Find the first stance row that was most recently selected — use balanced as default
		_confirm_stance("balanced")
	else:
		# Selecting a stance row auto-confirms
		_confirm_stance(row["stance_id"])

func _confirm_stance(stance_id: String) -> void:
	_is_active = false
	SfxManager.play("ui_confirm")
	stance_confirmed.emit(stance_id)

func close() -> void:
	_is_active = false
	queue_free()
