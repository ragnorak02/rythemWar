extends CanvasLayer
## PauseMenu — overlay shown when battle is paused.
## Follows programmatic UI pattern from tactician_mode.gd.

signal resumed
signal restarted
signal quit_to_menu

const BORDER_COLOR := Color(0.94, 0.65, 0.15)
const BG_COLOR := Color(0.06, 0.08, 0.18, 0.92)
const LABEL_COLOR := Color(0.95, 0.92, 0.82)
const SELECTED_COLOR := Color(0.94, 0.65, 0.15, 0.3)
const DISABLED_COLOR := Color(0.4, 0.4, 0.45, 0.6)
const HINT_COLOR := Color(0.6, 0.6, 0.7, 0.7)

const PANEL_W := 420.0
const PANEL_H := 340.0
const PANEL_X := (1280.0 - PANEL_W) / 2.0
const PANEL_Y := (720.0 - PANEL_H) / 2.0
const ROW_HEIGHT := 48.0

var _selected: int = 0
var _items: Array[Dictionary] = [
	{"name": "Resume", "keys": "Start / Esc"},
	{"name": "Restart", "keys": "A / Enter"},
	{"name": "Options", "keys": "—"},
	{"name": "Quit", "keys": "A / Enter"},
]
var _disabled: Array[int] = [2] # Options disabled
var _highlight: ColorRect = null

func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()

func _build_ui() -> void:
	# Dim overlay
	var dim := ColorRect.new()
	dim.size = Vector2(1280, 720)
	dim.color = Color(0, 0, 0, 0.5)
	add_child(dim)

	# Border panel
	var border := ColorRect.new()
	border.position = Vector2(PANEL_X, PANEL_Y)
	border.size = Vector2(PANEL_W, PANEL_H)
	border.color = BORDER_COLOR
	add_child(border)

	# Background panel
	var bg := ColorRect.new()
	bg.position = Vector2(PANEL_X + 3, PANEL_Y + 3)
	bg.size = Vector2(PANEL_W - 6, PANEL_H - 6)
	bg.color = BG_COLOR
	add_child(bg)

	# Title
	var title := Label.new()
	title.text = "PAUSED"
	title.position = Vector2(PANEL_X, PANEL_Y + 16)
	title.size = Vector2(PANEL_W, 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", BORDER_COLOR)
	add_child(title)

	# Separator
	var sep := ColorRect.new()
	sep.position = Vector2(PANEL_X + 20, PANEL_Y + 54)
	sep.size = Vector2(PANEL_W - 40, 2)
	sep.color = Color(BORDER_COLOR, 0.4)
	add_child(sep)

	# Menu items with control hints
	var items_y := PANEL_Y + 70.0
	for i in _items.size():
		var is_disabled: bool = i in _disabled

		# Item name (left side)
		var label := Label.new()
		label.text = _items[i]["name"]
		label.position = Vector2(PANEL_X + 40, items_y + i * ROW_HEIGHT)
		label.size = Vector2(180, ROW_HEIGHT)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 20)
		if is_disabled:
			label.add_theme_color_override("font_color", DISABLED_COLOR)
		else:
			label.add_theme_color_override("font_color", LABEL_COLOR)
		add_child(label)

		# Control hint (right side)
		var hint := Label.new()
		hint.text = _items[i]["keys"]
		hint.position = Vector2(PANEL_X + 220, items_y + i * ROW_HEIGHT)
		hint.size = Vector2(160, ROW_HEIGHT)
		hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hint.add_theme_font_size_override("font_size", 14)
		if is_disabled:
			hint.add_theme_color_override("font_color", Color(DISABLED_COLOR, 0.5))
		else:
			hint.add_theme_color_override("font_color", HINT_COLOR)
		add_child(hint)

	# Selection highlight
	_highlight = ColorRect.new()
	_highlight.size = Vector2(PANEL_W - 20, ROW_HEIGHT)
	_highlight.color = SELECTED_COLOR
	add_child(_highlight)
	_update_highlight()

	# Navigation hints at bottom
	var nav := Label.new()
	nav.text = "D-pad / Arrows  Navigate    |    B / Esc  Back"
	nav.position = Vector2(PANEL_X, PANEL_Y + PANEL_H - 36)
	nav.size = Vector2(PANEL_W, 24)
	nav.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nav.add_theme_font_size_override("font_size", 12)
	nav.add_theme_color_override("font_color", HINT_COLOR)
	add_child(nav)

func _update_highlight() -> void:
	var items_y := PANEL_Y + 70.0
	_highlight.position = Vector2(PANEL_X + 10, items_y + _selected * ROW_HEIGHT)

func _move_selection(dir: int) -> void:
	var new_sel: int = _selected + dir
	# Skip disabled items
	while new_sel >= 0 and new_sel < _items.size() and new_sel in _disabled:
		new_sel += dir
	if new_sel >= 0 and new_sel < _items.size():
		_selected = new_sel
		_update_highlight()
		SfxManager.play("ui_navigate")

func _confirm() -> void:
	if _selected in _disabled:
		return
	SfxManager.play("ui_confirm")
	match _items[_selected]["name"]:
		"Resume":
			resumed.emit()
		"Restart":
			restarted.emit()
		"Quit":
			quit_to_menu.emit()

func _input(event: InputEvent) -> void:
	if not visible:
		return

	# Accept input from both players
	for prefix in ["p1_", "p2_"]:
		if event.is_action_pressed(prefix + "up") or event.is_action_pressed("ui_menu_up"):
			_move_selection(-1)
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed(prefix + "down") or event.is_action_pressed("ui_menu_down"):
			_move_selection(1)
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed(prefix + "face_a") or event.is_action_pressed("ui_menu_confirm"):
			_confirm()
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed(prefix + "face_b"):
			SfxManager.play("ui_back")
			resumed.emit()
			get_viewport().set_input_as_handled()
			return

	# Start button also resumes
	if event.is_action_pressed("ui_pause"):
		SfxManager.play("ui_back")
		resumed.emit()
		get_viewport().set_input_as_handled()
		return
