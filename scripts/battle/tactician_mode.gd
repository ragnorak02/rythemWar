extends CanvasLayer
## TacticianMode — pre-battle preparation screen.
## Allows configuring formation, aggression, viewing/editing army, commander actions, and fleeing.
## Navigation: Up/Down rows, Left/Right within radio rows, Confirm (face_a/Enter).
## Uses p1_/p2_ input actions — no conflict with rhythm lane (only active when Conductor.is_playing()).

signal confirmed(player_id: int, config: Dictionary)
signal fled(player_id: int)

var player_id: int = 1
var _panel: ColorRect = null
var _rows: Array = []  # Array of row Dictionaries
var _selected_row: int = 0
var _formation: String = "solo"
var _aggression: String = "normal"
var _commander_actions_used: Array = []
var _is_active: bool = false

# Sub-panels
var _view_army_modal: CanvasLayer = null
var _edit_army_panel: CanvasLayer = null
var _commander_panel: CanvasLayer = null
var _sub_panel_open: bool = false

# Radio option indices per row
var _formation_index: int = 0
var _aggression_index: int = 0

const FORMATIONS := ["solo", "pair", "squad", "legion"]
const AGGRESSIONS := ["normal", "high"]

const PANEL_X := 100.0
const PANEL_Y := 160.0
const PANEL_W := 790.0
const PANEL_H := 340.0
const ROW_HEIGHT := 48.0
const ROW_START_Y := 20.0
const LABEL_X := 30.0

# Colors
const BORDER_COLOR := Color(0.94, 0.65, 0.15)  # Orange/gold
const BG_COLOR := Color(0.06, 0.08, 0.18, 0.92)
const SELECTED_ROW_COLOR := Color(0.15, 0.18, 0.35, 0.6)
const LABEL_COLOR := Color(0.95, 0.92, 0.82)
const OPTION_BG := Color(0.15, 0.15, 0.25, 0.8)
const OPTION_SELECTED := Color(0.94, 0.65, 0.15, 0.3)
const OPTION_BORDER := Color(0.94, 0.65, 0.15)
const OPTION_TEXT := Color(0.95, 0.92, 0.82)

func _ready() -> void:
	layer = 20

func setup(p_player_id: int, p_offset_x: float = -1.0) -> void:
	player_id = p_player_id
	var offset_x: float = p_offset_x if p_offset_x >= 0 else PANEL_X
	_build_panel(offset_x)
	_is_active = true

func _build_panel(offset_x: float) -> void:
	# Background panel with border
	var border := ColorRect.new()
	border.size = Vector2(PANEL_W + 6, PANEL_H + 6)
	border.position = Vector2(offset_x - 3, PANEL_Y - 3)
	border.color = BORDER_COLOR
	add_child(border)

	_panel = ColorRect.new()
	_panel.size = Vector2(PANEL_W, PANEL_H)
	_panel.position = Vector2(offset_x, PANEL_Y)
	_panel.color = BG_COLOR
	add_child(_panel)

	# Build rows
	_rows.clear()
	var y := ROW_START_Y

	# Row 0: Unit Formation
	_rows.append(_build_radio_row(offset_x, y, "Unit Formation:", FORMATIONS, _formation_index))
	y += ROW_HEIGHT

	# Row 1: Aggression
	_rows.append(_build_radio_row(offset_x, y, "Aggression:", AGGRESSIONS, _aggression_index))
	y += ROW_HEIGHT

	# Row 2: View Army
	_rows.append(_build_button_row(offset_x, y, "View Army", "(modal pops up of deployed units)"))
	y += ROW_HEIGHT

	# Row 3: Edit Army
	_rows.append(_build_button_row(offset_x, y, "Edit Army", "(swap unit positions)"))
	y += ROW_HEIGHT

	# Row 4: Commander Actions
	_rows.append(_build_button_row(offset_x, y, "Commander Actions", "(special pre-battle abilities)"))
	y += ROW_HEIGHT

	# Row 5: Flee
	_rows.append(_build_button_row(offset_x, y, "Flee", "(40%% chance, lose score multiplier)"))
	y += ROW_HEIGHT

	# Row 6: Confirm
	_rows.append(_build_button_row(offset_x, y, ">> CONFIRM <<", ""))

	_update_selection_highlight()

func _build_radio_row(offset_x: float, y: float, label_text: String, options: Array, selected: int) -> Dictionary:
	var row_y := PANEL_Y + y
	var row := {"type": "radio", "options": options, "selected": selected, "nodes": [], "highlight": null, "label": null}

	# Row highlight bg
	var highlight := ColorRect.new()
	highlight.size = Vector2(PANEL_W - 10, ROW_HEIGHT - 4)
	highlight.position = Vector2(offset_x + 5, row_y)
	highlight.color = SELECTED_ROW_COLOR
	highlight.visible = false
	add_child(highlight)
	row["highlight"] = highlight

	# Label
	var label := Label.new()
	label.text = label_text
	label.position = Vector2(offset_x + LABEL_X, row_y + 8)
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", LABEL_COLOR)
	add_child(label)
	row["label"] = label

	# Option buttons
	var opt_x := offset_x + LABEL_X + 240.0
	for i in options.size():
		var opt_dict := _build_option_button(opt_x, row_y + 6, options[i], i == selected)
		row["nodes"].append(opt_dict)
		opt_x += opt_dict["width"] + 12.0

	return row

func _build_option_button(x: float, y: float, text: String, is_selected: bool) -> Dictionary:
	var padding := 16.0
	var font_size := 18

	# Measure text width approximately
	var text_width: float = text.length() * 10.0 + padding * 2
	var btn_height := 32.0

	# Border
	var border := ColorRect.new()
	border.size = Vector2(text_width + 4, btn_height + 4)
	border.position = Vector2(x - 2, y - 2)
	border.color = OPTION_BORDER if is_selected else Color(0.4, 0.4, 0.5, 0.5)
	add_child(border)

	# Background
	var bg := ColorRect.new()
	bg.size = Vector2(text_width, btn_height)
	bg.position = Vector2(x, y)
	bg.color = OPTION_SELECTED if is_selected else OPTION_BG
	add_child(bg)

	# Label
	var label := Label.new()
	label.text = text
	label.position = Vector2(x + padding / 2, y + 4)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", OPTION_TEXT)
	add_child(label)

	return {"border": border, "bg": bg, "label": label, "width": text_width}

func _build_button_row(offset_x: float, y: float, label_text: String, hint_text: String) -> Dictionary:
	var row_y := PANEL_Y + y
	var row := {"type": "button", "action": label_text, "nodes": [], "highlight": null, "label": null}

	# Row highlight bg
	var highlight := ColorRect.new()
	highlight.size = Vector2(PANEL_W - 10, ROW_HEIGHT - 4)
	highlight.position = Vector2(offset_x + 5, row_y)
	highlight.color = SELECTED_ROW_COLOR
	highlight.visible = false
	add_child(highlight)
	row["highlight"] = highlight

	# Label
	var label := Label.new()
	label.text = label_text
	label.position = Vector2(offset_x + LABEL_X, row_y + 8)
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", LABEL_COLOR)
	add_child(label)
	row["label"] = label

	# Hint
	if hint_text != "":
		var hint := Label.new()
		hint.text = hint_text
		hint.position = Vector2(offset_x + LABEL_X + 280, row_y + 12)
		hint.add_theme_font_size_override("font_size", 14)
		hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7, 0.7))
		add_child(hint)

	return row

func _update_selection_highlight() -> void:
	for i in _rows.size():
		var row: Dictionary = _rows[i]
		if row["highlight"]:
			row["highlight"].visible = (i == _selected_row)

func _update_radio_visuals(row_index: int) -> void:
	var row: Dictionary = _rows[row_index]
	if row["type"] != "radio":
		return
	var selected: int = row["selected"]
	for i in row["nodes"].size():
		var node_dict: Dictionary = row["nodes"][i]
		var is_sel: bool = (i == selected)
		node_dict["border"].color = OPTION_BORDER if is_sel else Color(0.4, 0.4, 0.5, 0.5)
		node_dict["bg"].color = OPTION_SELECTED if is_sel else OPTION_BG

func _input(event: InputEvent) -> void:
	if not _is_active or _sub_panel_open:
		return

	var prefix: String = "p%d_" % player_id

	# Navigation: Up/Down
	if event.is_action_pressed(prefix + "up") or (event is InputEventKey and event.pressed and event.keycode == KEY_UP and player_id == 1):
		_selected_row = maxi(0, _selected_row - 1)
		_update_selection_highlight()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed(prefix + "down") or (event is InputEventKey and event.pressed and event.keycode == KEY_DOWN and player_id == 1):
		_selected_row = mini(_rows.size() - 1, _selected_row + 1)
		_update_selection_highlight()
		get_viewport().set_input_as_handled()
		return

	# Radio row: Left/Right
	var row: Dictionary = _rows[_selected_row]
	if row["type"] == "radio":
		if event.is_action_pressed(prefix + "left") or (event is InputEventKey and event.pressed and event.keycode == KEY_LEFT and player_id == 1):
			row["selected"] = maxi(0, row["selected"] - 1)
			_update_radio_visuals(_selected_row)
			_apply_radio_selection(_selected_row)
			get_viewport().set_input_as_handled()
			return

		if event.is_action_pressed(prefix + "right") or (event is InputEventKey and event.pressed and event.keycode == KEY_RIGHT and player_id == 1):
			row["selected"] = mini(row["options"].size() - 1, row["selected"] + 1)
			_update_radio_visuals(_selected_row)
			_apply_radio_selection(_selected_row)
			get_viewport().set_input_as_handled()
			return

	# Confirm: face_a or Enter
	if event.is_action_pressed(prefix + "face_a") or (event is InputEventKey and event.pressed and event.keycode == KEY_ENTER and player_id == 1):
		_activate_row(_selected_row)
		get_viewport().set_input_as_handled()
		return

func _apply_radio_selection(row_index: int) -> void:
	var row: Dictionary = _rows[row_index]
	var selected_option: String = row["options"][row["selected"]]
	match row_index:
		0: _formation = selected_option
		1: _aggression = selected_option

func _activate_row(row_index: int) -> void:
	var row: Dictionary = _rows[row_index]
	if row["type"] == "radio":
		return  # Radio rows navigate with left/right

	match row["action"]:
		"View Army":
			_open_view_army()
		"Edit Army":
			_open_edit_army()
		"Commander Actions":
			_open_commander_actions()
		"Flee":
			_attempt_flee()
		">> CONFIRM <<":
			_confirm()

func _open_view_army() -> void:
	_sub_panel_open = true
	_view_army_modal = CanvasLayer.new()
	_view_army_modal.set_script(preload("res://scripts/battle/view_army_modal.gd"))
	_view_army_modal.layer = 25
	add_child(_view_army_modal)
	_view_army_modal.setup(player_id)
	_view_army_modal.closed.connect(_on_sub_panel_closed.bind(_view_army_modal))

func _open_edit_army() -> void:
	_sub_panel_open = true
	_edit_army_panel = CanvasLayer.new()
	_edit_army_panel.set_script(preload("res://scripts/battle/edit_army_panel.gd"))
	_edit_army_panel.layer = 25
	add_child(_edit_army_panel)
	_edit_army_panel.setup(player_id)
	_edit_army_panel.closed.connect(_on_sub_panel_closed.bind(_edit_army_panel))

func _open_commander_actions() -> void:
	_sub_panel_open = true
	_commander_panel = CanvasLayer.new()
	_commander_panel.set_script(preload("res://scripts/battle/commander_actions_panel.gd"))
	_commander_panel.layer = 25
	add_child(_commander_panel)
	_commander_panel.setup(player_id, _commander_actions_used)
	_commander_panel.closed.connect(_on_commander_closed)

func _on_sub_panel_closed(panel: CanvasLayer) -> void:
	_sub_panel_open = false
	panel.queue_free()

func _on_commander_closed(actions_used: Array) -> void:
	_sub_panel_open = false
	_commander_actions_used = actions_used
	if _commander_panel:
		_commander_panel.queue_free()
		_commander_panel = null

func _attempt_flee() -> void:
	var flee_chance := 0.4
	var roll := randf()
	if roll < flee_chance:
		# Success — flee
		_is_active = false
		Events.tactician_fled.emit(player_id)
		fled.emit(player_id)
	else:
		# Failed — show feedback, battle starts with penalty
		var row: Dictionary = _rows[_selected_row]
		if row["label"]:
			row["label"].add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
			row["label"].text = "Flee FAILED! Battle begins..."
		# Auto-confirm after short delay with flee penalty
		_formation = _formation
		_aggression = _aggression
		await get_tree().create_timer(1.0).timeout
		_confirm(true)

func _confirm(flee_penalty: bool = false) -> void:
	_is_active = false
	var config := {
		"formation": _formation,
		"aggression": _aggression,
		"commander_actions_used": _commander_actions_used,
		"flee_penalty": flee_penalty,
	}
	Events.tactician_confirmed.emit(player_id, config)
	confirmed.emit(player_id, config)

func close() -> void:
	_is_active = false
	queue_free()
