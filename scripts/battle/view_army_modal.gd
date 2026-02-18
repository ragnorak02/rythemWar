extends CanvasLayer
## ViewArmyModal — modal showing all 6 deployed units with full stats.
## Close with Escape/B button, returns to Tactician panel.

signal closed()

var player_id: int = 1
var _is_active: bool = false

const MODAL_X := 200.0
const MODAL_Y := 80.0
const MODAL_W := 880.0
const MODAL_H := 520.0
const ROW_H := 60.0

const BG_COLOR := Color(0.05, 0.06, 0.14, 0.95)
const BORDER_COLOR := Color(0.94, 0.65, 0.15)
const HEADER_COLOR := Color(0.94, 0.78, 0.31)
const TEXT_COLOR := Color(0.9, 0.9, 0.85)
const PLAYER_COLOR := Color(0.25, 0.45, 0.85)
const ENEMY_COLOR := Color(0.85, 0.25, 0.25)

func setup(p_player_id: int) -> void:
	player_id = p_player_id
	layer = 25
	_build_modal()
	_is_active = true

func _build_modal() -> void:
	# Dim background
	var dim := ColorRect.new()
	dim.size = Vector2(1280, 720)
	dim.color = Color(0, 0, 0, 0.5)
	add_child(dim)

	# Border
	var border := ColorRect.new()
	border.size = Vector2(MODAL_W + 4, MODAL_H + 4)
	border.position = Vector2(MODAL_X - 2, MODAL_Y - 2)
	border.color = BORDER_COLOR
	add_child(border)

	# Background
	var bg := ColorRect.new()
	bg.size = Vector2(MODAL_W, MODAL_H)
	bg.position = Vector2(MODAL_X, MODAL_Y)
	bg.color = BG_COLOR
	add_child(bg)

	# Title
	var title := Label.new()
	title.text = "DEPLOYED ARMY — Player %d" % player_id
	title.position = Vector2(MODAL_X + 20, MODAL_Y + 12)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", HEADER_COLOR)
	add_child(title)

	# Close hint
	var close_hint := Label.new()
	close_hint.text = "[ESC / B] Close"
	close_hint.position = Vector2(MODAL_X + MODAL_W - 180, MODAL_Y + 16)
	close_hint.add_theme_font_size_override("font_size", 14)
	close_hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	add_child(close_hint)

	# Column headers
	var header_y := MODAL_Y + 55
	var headers := ["#", "Unit", "HP", "Damage", "Defense", "Buffs"]
	var col_x := [MODAL_X + 20, MODAL_X + 60, MODAL_X + 250, MODAL_X + 420, MODAL_X + 570, MODAL_X + 700]
	for i in headers.size():
		var h := Label.new()
		h.text = headers[i]
		h.position = Vector2(col_x[i], header_y)
		h.add_theme_font_size_override("font_size", 16)
		h.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
		add_child(h)

	# Separator line
	var sep := ColorRect.new()
	sep.size = Vector2(MODAL_W - 40, 1)
	sep.position = Vector2(MODAL_X + 20, header_y + 24)
	sep.color = Color(0.3, 0.3, 0.4, 0.5)
	add_child(sep)

	# Unit rows — use placeholder data (battle.gd will provide real army ref)
	var army_color: Color = PLAYER_COLOR if player_id == 1 else ENEMY_COLOR
	for i in 6:
		var row_y := header_y + 32 + i * ROW_H

		# Alternating row bg
		if i % 2 == 0:
			var row_bg := ColorRect.new()
			row_bg.size = Vector2(MODAL_W - 40, ROW_H - 4)
			row_bg.position = Vector2(MODAL_X + 20, row_y)
			row_bg.color = Color(0.1, 0.1, 0.18, 0.4)
			add_child(row_bg)

		# Color pip
		var pip := ColorRect.new()
		pip.size = Vector2(12, 12)
		pip.position = Vector2(col_x[0] + 4, row_y + 16)
		pip.color = army_color.lightened(randf_range(-0.05, 0.1))
		add_child(pip)

		# Index
		var idx_label := Label.new()
		idx_label.text = str(i + 1)
		idx_label.position = Vector2(col_x[0] + 22, row_y + 12)
		idx_label.add_theme_font_size_override("font_size", 16)
		idx_label.add_theme_color_override("font_color", TEXT_COLOR)
		add_child(idx_label)

		# Unit name
		var pos_name: String = "Front" if i < 3 else "Back"
		var row_pos: String = ["Top", "Mid", "Bot"][i % 3]
		var name_label := Label.new()
		name_label.text = "Soldier %d (%s %s)" % [i + 1, pos_name, row_pos]
		name_label.position = Vector2(col_x[1], row_y + 12)
		name_label.add_theme_font_size_override("font_size", 16)
		name_label.add_theme_color_override("font_color", TEXT_COLOR)
		add_child(name_label)

		# HP
		var hp_label := Label.new()
		hp_label.text = "100 / 100"
		hp_label.position = Vector2(col_x[2], row_y + 12)
		hp_label.add_theme_font_size_override("font_size", 16)
		hp_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.3))
		add_child(hp_label)

		# Damage
		var dmg_label := Label.new()
		dmg_label.text = "15"
		dmg_label.position = Vector2(col_x[3], row_y + 12)
		dmg_label.add_theme_font_size_override("font_size", 16)
		dmg_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.3))
		add_child(dmg_label)

		# Defense
		var def_label := Label.new()
		def_label.text = "5"
		def_label.position = Vector2(col_x[4], row_y + 12)
		def_label.add_theme_font_size_override("font_size", 16)
		def_label.add_theme_color_override("font_color", Color(0.3, 0.6, 1.0))
		add_child(def_label)

		# Buffs
		var buff_label := Label.new()
		buff_label.text = "None"
		buff_label.position = Vector2(col_x[5], row_y + 12)
		buff_label.add_theme_font_size_override("font_size", 16)
		buff_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
		add_child(buff_label)

func _input(event: InputEvent) -> void:
	if not _is_active:
		return

	var prefix: String = "p%d_" % player_id

	# Close on Escape or face_b
	if (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE) or event.is_action_pressed(prefix + "face_b"):
		_is_active = false
		closed.emit()
		get_viewport().set_input_as_handled()
