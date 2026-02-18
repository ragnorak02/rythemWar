extends CanvasLayer
## EditArmyPanel — swap unit positions and configure loadout.
## Select two units to swap positions. Confirm returns to Tactician panel.

signal closed()

var player_id: int = 1
var _is_active: bool = false
var _selected_index: int = 0
var _swap_first: int = -1  # First unit selected for swap (-1 = none)
var _unit_labels: Array = []
var _highlight_rects: Array = []
var _swap_indicator: Label = null

const PANEL_X := 200.0
const PANEL_Y := 80.0
const PANEL_W := 880.0
const PANEL_H := 520.0
const ROW_H := 56.0

func setup(p_player_id: int) -> void:
	player_id = p_player_id
	layer = 25
	_build_panel()
	_is_active = true

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
	title.text = "EDIT ARMY — Swap Unit Positions"
	title.position = Vector2(PANEL_X + 20, PANEL_Y + 12)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.94, 0.78, 0.31))
	add_child(title)

	# Instructions
	var instr := Label.new()
	instr.text = "[Up/Down] Navigate  |  [A/Enter] Select unit to swap  |  [ESC/B] Close"
	instr.position = Vector2(PANEL_X + 20, PANEL_Y + 45)
	instr.add_theme_font_size_override("font_size", 13)
	instr.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	add_child(instr)

	# Swap indicator
	_swap_indicator = Label.new()
	_swap_indicator.text = ""
	_swap_indicator.position = Vector2(PANEL_X + 20, PANEL_Y + PANEL_H - 40)
	_swap_indicator.add_theme_font_size_override("font_size", 16)
	_swap_indicator.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	add_child(_swap_indicator)

	# Unit rows
	_unit_labels.clear()
	_highlight_rects.clear()
	var start_y := PANEL_Y + 75
	for i in 6:
		var row_y := start_y + i * ROW_H

		# Highlight rect
		var hl := ColorRect.new()
		hl.size = Vector2(PANEL_W - 40, ROW_H - 4)
		hl.position = Vector2(PANEL_X + 20, row_y)
		hl.color = Color(0.15, 0.18, 0.35, 0.6)
		hl.visible = (i == 0)
		add_child(hl)
		_highlight_rects.append(hl)

		# Position label
		var pos_name: String = "Front Row" if i < 3 else "Back Row"
		var pos_slot: String = ["Top", "Mid", "Bot"][i % 3]

		var label := Label.new()
		label.text = "  [%d]  Soldier %d  —  %s %s  |  HP: 100  DMG: 15  DEF: 5" % [i + 1, i + 1, pos_name, pos_slot]
		label.position = Vector2(PANEL_X + 30, row_y + 14)
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.85))
		add_child(label)
		_unit_labels.append(label)

func _update_highlights() -> void:
	for i in _highlight_rects.size():
		var hl: ColorRect = _highlight_rects[i]
		if i == _selected_index:
			hl.visible = true
			hl.color = Color(0.15, 0.18, 0.35, 0.6)
		elif i == _swap_first:
			hl.visible = true
			hl.color = Color(0.94, 0.65, 0.15, 0.3)  # Orange for first selected
		else:
			hl.visible = false

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
		_selected_index = mini(5, _selected_index + 1)
		_update_highlights()
		get_viewport().set_input_as_handled()
		return

	# Select for swap
	if event.is_action_pressed(prefix + "face_a") or (event is InputEventKey and event.pressed and event.keycode == KEY_ENTER and player_id == 1):
		if _swap_first < 0:
			_swap_first = _selected_index
			_swap_indicator.text = "Selected unit %d — choose another to swap" % (_swap_first + 1)
		else:
			if _swap_first != _selected_index:
				# Perform swap
				var temp_text: String = _unit_labels[_swap_first].text
				_unit_labels[_swap_first].text = _unit_labels[_selected_index].text
				_unit_labels[_selected_index].text = temp_text
				_swap_indicator.text = "Swapped unit %d and %d!" % [_swap_first + 1, _selected_index + 1]
			else:
				_swap_indicator.text = "Deselected unit %d" % (_swap_first + 1)
			_swap_first = -1
		_update_highlights()
		get_viewport().set_input_as_handled()
		return

	# Close
	if (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE) or event.is_action_pressed(prefix + "face_b"):
		_is_active = false
		closed.emit()
		get_viewport().set_input_as_handled()
