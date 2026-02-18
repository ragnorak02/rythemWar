extends Node2D
## StageSelect — Easy(yellow) / Medium(orange) / Hard(red) large cards with L/R navigation.
## Graphics V1: styled cards with gradient fill, border glow, difficulty icons.

var _stages: Array[Dictionary] = []
var _selected_index: int = 0
var _cards: Array[Node2D] = []
var _title_label: Label = null

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.05, 0.04, 0.09))
	_setup_stages()
	_build_ui()
	_update_selection()

func _setup_stages() -> void:
	_stages = [
		{
			"id": "easy_01",
			"title": "Dawn March",
			"difficulty": "EASY",
			"bpm": 100,
			"notes": 20,
			"color": Color(0.95, 0.85, 0.2),  # Yellow
			"desc": "A gentle warm-up. Simple patterns at a comfortable tempo.",
			"icon": "I",  # Sunrise
		},
		{
			"id": "medium_01",
			"title": "Iron March",
			"difficulty": "MEDIUM",
			"bpm": 130,
			"notes": 30,
			"color": Color(1.0, 0.55, 0.1),  # Orange
			"desc": "Faster tempo with mixed buttons and tighter spacing.",
			"icon": "II",  # Swords
		},
		{
			"id": "hard_01",
			"title": "Storm Siege",
			"difficulty": "HARD",
			"bpm": 165,
			"notes": 40,
			"color": Color(1.0, 0.2, 0.2),  # Red
			"desc": "Relentless patterns at blazing speed. For veterans only.",
			"icon": "III",  # Skull
		},
	]

func _build_ui() -> void:
	# Background with shader
	var bg := ColorRect.new()
	bg.size = Vector2(1280, 720)
	bg.z_index = -10
	var bg_shader := load("res://assets/shaders/menu_bg.gdshader")
	if bg_shader:
		var mat := ShaderMaterial.new()
		mat.shader = bg_shader
		bg.material = mat
	else:
		bg.color = Color(0.05, 0.04, 0.09)
	add_child(bg)

	# Title
	_title_label = Label.new()
	_title_label.text = "SELECT STAGE"
	_title_label.position = Vector2(440, 30)
	_title_label.size = Vector2(400, 50)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 36)
	_title_label.add_theme_color_override("font_color", Color(0.94, 0.78, 0.31))
	add_child(_title_label)

	# Stage cards
	var card_width := 300.0
	var card_height := 400.0
	var spacing := 40.0
	var total_width: float = _stages.size() * card_width + (_stages.size() - 1) * spacing
	var start_x: float = (1280.0 - total_width) / 2.0

	for i in _stages.size():
		var card := _build_card(_stages[i], i)
		card.position = Vector2(start_x + i * (card_width + spacing), 120)
		add_child(card)
		_cards.append(card)

	# Controls hint
	var hint := Label.new()
	hint.text = "Left/Right to select  |  Enter / A to confirm  |  Escape / B to go back"
	hint.position = Vector2(300, 660)
	hint.size = Vector2(680, 30)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	add_child(hint)

func _build_card(stage: Dictionary, _index: int) -> Node2D:
	var card := Node2D.new()
	var color: Color = stage["color"]

	# Card border (slightly larger, glowing)
	var border := ColorRect.new()
	border.size = Vector2(304, 404)
	border.position = Vector2(-2, -2)
	border.color = color.darkened(0.5)
	border.z_index = -1
	card.add_child(border)

	# Card background
	var bg := ColorRect.new()
	bg.size = Vector2(300, 400)
	bg.color = Color(0.1, 0.08, 0.15)
	card.add_child(bg)

	# Color accent bar at top
	var accent := ColorRect.new()
	accent.size = Vector2(300, 8)
	accent.color = color
	card.add_child(accent)

	# Inner top gradient area (difficulty color region)
	var top_area := ColorRect.new()
	top_area.size = Vector2(300, 80)
	top_area.position = Vector2(0, 8)
	top_area.color = Color(color.r, color.g, color.b, 0.08)
	card.add_child(top_area)

	# Difficulty numeral (large centered)
	var icon_label := Label.new()
	icon_label.text = stage.get("icon", "")
	icon_label.position = Vector2(0, 20)
	icon_label.size = Vector2(300, 50)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.add_theme_font_size_override("font_size", 28)
	icon_label.add_theme_color_override("font_color", Color(color.r, color.g, color.b, 0.4))
	card.add_child(icon_label)

	# Difficulty label
	var diff_label := Label.new()
	diff_label.text = stage["difficulty"]
	diff_label.position = Vector2(0, 95)
	diff_label.size = Vector2(300, 50)
	diff_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	diff_label.add_theme_font_size_override("font_size", 36)
	diff_label.add_theme_color_override("font_color", color)
	card.add_child(diff_label)

	# Separator line
	var sep := ColorRect.new()
	sep.size = Vector2(240, 1)
	sep.position = Vector2(30, 145)
	sep.color = Color(color.r, color.g, color.b, 0.3)
	card.add_child(sep)

	# Title
	var title_label := Label.new()
	title_label.text = stage["title"]
	title_label.position = Vector2(0, 155)
	title_label.size = Vector2(300, 30)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	card.add_child(title_label)

	# BPM
	var bpm_label := Label.new()
	bpm_label.text = "%d BPM" % stage["bpm"]
	bpm_label.position = Vector2(0, 190)
	bpm_label.size = Vector2(300, 25)
	bpm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bpm_label.add_theme_font_size_override("font_size", 16)
	bpm_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	card.add_child(bpm_label)

	# Notes count
	var notes_label := Label.new()
	notes_label.text = "%d Notes" % stage["notes"]
	notes_label.position = Vector2(0, 215)
	notes_label.size = Vector2(300, 25)
	notes_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notes_label.add_theme_font_size_override("font_size", 14)
	notes_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	card.add_child(notes_label)

	# Description
	var desc_label := Label.new()
	desc_label.text = stage["desc"]
	desc_label.position = Vector2(20, 250)
	desc_label.size = Vector2(260, 80)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.7))
	card.add_child(desc_label)

	# High score (if any)
	var stage_id: String = stage["id"]
	if GameManager.high_scores.has(stage_id):
		var hs_label := Label.new()
		hs_label.text = "Best: %d" % GameManager.high_scores[stage_id]
		hs_label.position = Vector2(0, 340)
		hs_label.size = Vector2(300, 25)
		hs_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hs_label.add_theme_font_size_override("font_size", 14)
		hs_label.add_theme_color_override("font_color", Color(0.94, 0.78, 0.31))
		card.add_child(hs_label)

	# Cleared indicator
	if stage_id in GameManager.stages_cleared:
		var cleared := Label.new()
		cleared.text = "CLEARED"
		cleared.position = Vector2(0, 365)
		cleared.size = Vector2(300, 25)
		cleared.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cleared.add_theme_font_size_override("font_size", 14)
		cleared.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
		card.add_child(cleared)

	return card

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_menu_right") or event.is_action_pressed("p1_right"):
		_selected_index = mini(_selected_index + 1, _stages.size() - 1)
		_update_selection()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_menu_left") or event.is_action_pressed("p1_left"):
		_selected_index = maxi(_selected_index - 1, 0)
		_update_selection()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_menu_confirm") or event.is_action_pressed("p1_face_a"):
		_confirm_selection()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_menu_back") or event.is_action_pressed("p1_face_b"):
		Events.scene_change_requested.emit("res://scenes/MainMenu.tscn")
		get_viewport().set_input_as_handled()

func _update_selection() -> void:
	for i in _cards.size():
		var card := _cards[i]
		var color: Color = _stages[i]["color"]
		if i == _selected_index:
			card.scale = Vector2(1.05, 1.05)
			card.modulate = Color.WHITE
			# Update border to glow
			var border: ColorRect = card.get_child(0)
			border.color = Color(color.r, color.g, color.b, 0.6)
		else:
			card.scale = Vector2(0.95, 0.95)
			card.modulate = Color(0.5, 0.5, 0.5)
			var border: ColorRect = card.get_child(0)
			border.color = color.darkened(0.7)

func _confirm_selection() -> void:
	GameManager.selected_stage = _stages[_selected_index]["id"]
	Events.scene_change_requested.emit("res://scenes/CharacterSelect.tscn")
