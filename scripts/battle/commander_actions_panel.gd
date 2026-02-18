extends CanvasLayer
## CommanderActionsPanel — sub-panel for selecting pre-battle commander actions.
## Each action is limited-use per battle. Selecting one applies the effect and returns.

signal closed(actions_used: Array)

var player_id: int = 1
var _is_active: bool = false
var _actions: Array = []
var _actions_used: Array = []
var _selected_index: int = 0
var _row_labels: Array = []
var _row_highlights: Array = []
var _status_labels: Array = []
var _feedback_label: Label = null

const PANEL_X := 250.0
const PANEL_Y := 120.0
const PANEL_W := 780.0
const PANEL_H := 420.0
const ROW_H := 58.0

func setup(p_player_id: int, already_used: Array) -> void:
	player_id = p_player_id
	_actions_used = already_used.duplicate()
	layer = 25
	_load_actions()
	_build_panel()
	_is_active = true

func _load_actions() -> void:
	var file := FileAccess.open("res://data/commander_actions.json", FileAccess.READ)
	if file:
		var data: Dictionary = JSON.parse_string(file.get_as_text())
		file.close()
		if data.has("actions"):
			_actions = data["actions"]

func _build_panel() -> void:
	# Dim bg
	var dim := ColorRect.new()
	dim.size = Vector2(1280, 720)
	dim.color = Color(0, 0, 0, 0.5)
	add_child(dim)

	# Border
	var border := ColorRect.new()
	border.size = Vector2(PANEL_W + 4, PANEL_H + 4)
	border.position = Vector2(PANEL_X - 2, PANEL_Y - 2)
	border.color = Color(0.94, 0.65, 0.15)
	add_child(border)

	# Background
	var bg := ColorRect.new()
	bg.size = Vector2(PANEL_W, PANEL_H)
	bg.position = Vector2(PANEL_X, PANEL_Y)
	bg.color = Color(0.05, 0.06, 0.14, 0.95)
	add_child(bg)

	# Title
	var title := Label.new()
	title.text = "COMMANDER ACTIONS"
	title.position = Vector2(PANEL_X + 20, PANEL_Y + 12)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.94, 0.78, 0.31))
	add_child(title)

	# Instructions
	var instr := Label.new()
	instr.text = "[Up/Down] Navigate  |  [A/Enter] Use action  |  [ESC/B] Close"
	instr.position = Vector2(PANEL_X + 20, PANEL_Y + 42)
	instr.add_theme_font_size_override("font_size", 13)
	instr.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	add_child(instr)

	# Feedback label
	_feedback_label = Label.new()
	_feedback_label.text = ""
	_feedback_label.position = Vector2(PANEL_X + 20, PANEL_Y + PANEL_H - 40)
	_feedback_label.add_theme_font_size_override("font_size", 16)
	_feedback_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	add_child(_feedback_label)

	# Action rows
	_row_labels.clear()
	_row_highlights.clear()
	_status_labels.clear()
	var start_y := PANEL_Y + 70
	for i in _actions.size():
		var action: Dictionary = _actions[i]
		var row_y := start_y + i * ROW_H
		var is_used: bool = action["id"] in _actions_used

		# Highlight
		var hl := ColorRect.new()
		hl.size = Vector2(PANEL_W - 40, ROW_H - 4)
		hl.position = Vector2(PANEL_X + 20, row_y)
		hl.color = Color(0.15, 0.18, 0.35, 0.6)
		hl.visible = (i == 0)
		add_child(hl)
		_row_highlights.append(hl)

		# Action name
		var name_label := Label.new()
		name_label.text = action["name"]
		name_label.position = Vector2(PANEL_X + 30, row_y + 6)
		name_label.add_theme_font_size_override("font_size", 20)
		var action_color := Color(action.get("color", "#ffffff"))
		name_label.add_theme_color_override("font_color", action_color if not is_used else Color(0.4, 0.4, 0.45))
		add_child(name_label)
		_row_labels.append(name_label)

		# Description
		var desc_label := Label.new()
		desc_label.text = action["description"]
		desc_label.position = Vector2(PANEL_X + 30, row_y + 30)
		desc_label.add_theme_font_size_override("font_size", 13)
		desc_label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.7) if not is_used else Color(0.35, 0.35, 0.4))
		add_child(desc_label)

		# Status (READY / USED / chance %)
		var status := Label.new()
		if is_used:
			status.text = "USED"
			status.add_theme_color_override("font_color", Color(0.5, 0.3, 0.3))
		else:
			var chance: float = action.get("success_chance", 1.0)
			if chance < 1.0:
				status.text = "READY (%d%%)" % int(chance * 100)
			else:
				status.text = "READY"
			status.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
		status.position = Vector2(PANEL_X + PANEL_W - 160, row_y + 14)
		status.add_theme_font_size_override("font_size", 15)
		add_child(status)
		_status_labels.append(status)

func _update_highlights() -> void:
	for i in _row_highlights.size():
		_row_highlights[i].visible = (i == _selected_index)

func _input(event: InputEvent) -> void:
	if not _is_active:
		return

	var prefix: String = "p%d_" % player_id

	# Navigate
	if event.is_action_pressed(prefix + "up") or (event is InputEventKey and event.pressed and event.keycode == KEY_UP and player_id == 1):
		_selected_index = maxi(0, _selected_index - 1)
		_update_highlights()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed(prefix + "down") or (event is InputEventKey and event.pressed and event.keycode == KEY_DOWN and player_id == 1):
		_selected_index = mini(_actions.size() - 1, _selected_index + 1)
		_update_highlights()
		get_viewport().set_input_as_handled()
		return

	# Use action
	if event.is_action_pressed(prefix + "face_a") or (event is InputEventKey and event.pressed and event.keycode == KEY_ENTER and player_id == 1):
		_use_action(_selected_index)
		get_viewport().set_input_as_handled()
		return

	# Close
	if (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE) or event.is_action_pressed(prefix + "face_b"):
		_is_active = false
		closed.emit(_actions_used)
		get_viewport().set_input_as_handled()

func _use_action(index: int) -> void:
	if index >= _actions.size():
		return

	var action: Dictionary = _actions[index]
	if action["id"] in _actions_used:
		_feedback_label.text = "%s already used!" % action["name"]
		return

	# Check success chance for RNG-based actions
	var chance: float = action.get("success_chance", 1.0)
	if chance < 1.0:
		var roll := randf()
		if roll >= chance:
			_feedback_label.text = "%s FAILED! (needed < %d%%)" % [action["name"], int(chance * 100)]
			_actions_used.append(action["id"])
			_update_status(index, false)
			Events.commander_action_used.emit(player_id, action["id"])
			return

	# Success
	_actions_used.append(action["id"])
	_feedback_label.text = "%s activated!" % action["name"]
	_feedback_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	_update_status(index, true)
	Events.commander_action_used.emit(player_id, action["id"])

func _update_status(index: int, succeeded: bool) -> void:
	if index >= _status_labels.size():
		return
	var status: Label = _status_labels[index]
	if succeeded:
		status.text = "ACTIVATED"
		status.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	else:
		status.text = "FAILED"
		status.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))

	# Dim the row label
	if index < _row_labels.size():
		_row_labels[index].add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
