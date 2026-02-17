extends Node2D
## CharacterSelect — pick army color variant per player before battle.

var _variants: Array[Dictionary] = []
var _selected_index: int = 0
var _p2_selected_index: int = 1
var _preview_rects: Array[ColorRect] = []
var _selecting_p2: bool = false

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.05, 0.04, 0.09))
	_setup_variants()
	_build_ui()
	_update_selection()

func _setup_variants() -> void:
	_variants = [
		{"name": "Azure Guard", "color": Color(0.25, 0.45, 0.85), "accent": Color(0.4, 0.7, 1.0)},
		{"name": "Crimson Legion", "color": Color(0.85, 0.2, 0.2), "accent": Color(1.0, 0.4, 0.3)},
		{"name": "Emerald Phalanx", "color": Color(0.15, 0.7, 0.3), "accent": Color(0.3, 1.0, 0.5)},
		{"name": "Golden Horde", "color": Color(0.85, 0.7, 0.15), "accent": Color(1.0, 0.9, 0.3)},
		{"name": "Shadow Vanguard", "color": Color(0.35, 0.25, 0.5), "accent": Color(0.6, 0.4, 0.9)},
	]

func _build_ui() -> void:
	# Title
	var title := Label.new()
	title.text = "SELECT YOUR ARMY" if not GameManager.is_2p else "P1 — SELECT YOUR ARMY"
	title.position = Vector2(390, 30)
	title.size = Vector2(500, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.94, 0.78, 0.31))
	title.name = "Title"
	add_child(title)

	# Army preview squares
	var start_x := 190.0
	var sq_size := 120.0
	var spacing := 50.0

	for i in _variants.size():
		var variant := _variants[i]

		var container := Node2D.new()
		container.position = Vector2(start_x + i * (sq_size + spacing), 200)
		add_child(container)

		# Background
		var bg := ColorRect.new()
		bg.size = Vector2(sq_size, sq_size)
		bg.color = Color(0.12, 0.1, 0.18)
		container.add_child(bg)

		# Army color preview
		var preview := ColorRect.new()
		preview.size = Vector2(sq_size - 20, sq_size - 20)
		preview.position = Vector2(10, 10)
		preview.color = variant["color"]
		container.add_child(preview)
		_preview_rects.append(preview)

		# Name
		var name_label := Label.new()
		name_label.text = variant["name"]
		name_label.position = Vector2(0, sq_size + 10)
		name_label.size = Vector2(sq_size, 25)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 12)
		name_label.add_theme_color_override("font_color", variant["accent"])
		container.add_child(name_label)

	# Preview formation
	var formation_label := Label.new()
	formation_label.text = "6 Units — 2-column stagger formation"
	formation_label.position = Vector2(390, 420)
	formation_label.size = Vector2(500, 30)
	formation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	formation_label.add_theme_font_size_override("font_size", 16)
	formation_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	add_child(formation_label)

	# Stage info
	var stage_label := Label.new()
	stage_label.text = "Stage: %s" % GameManager.selected_stage
	stage_label.position = Vector2(390, 460)
	stage_label.size = Vector2(500, 30)
	stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_label.add_theme_font_size_override("font_size", 14)
	stage_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	add_child(stage_label)

	# Hint
	var hint := Label.new()
	hint.text = "Left/Right to choose  |  Enter / A to confirm  |  Escape / B to go back"
	hint.position = Vector2(300, 660)
	hint.size = Vector2(680, 30)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	add_child(hint)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_menu_right") or event.is_action_pressed("p1_right"):
		if not _selecting_p2:
			_selected_index = mini(_selected_index + 1, _variants.size() - 1)
		else:
			_p2_selected_index = mini(_p2_selected_index + 1, _variants.size() - 1)
		_update_selection()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_menu_left") or event.is_action_pressed("p1_left"):
		if not _selecting_p2:
			_selected_index = maxi(_selected_index - 1, 0)
		else:
			_p2_selected_index = maxi(_p2_selected_index - 1, 0)
		_update_selection()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_menu_confirm") or event.is_action_pressed("p1_face_a"):
		_confirm()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_menu_back") or event.is_action_pressed("p1_face_b"):
		if _selecting_p2:
			_selecting_p2 = false
			_update_selection()
		else:
			Events.scene_change_requested.emit("res://scenes/StageSelect.tscn")
		get_viewport().set_input_as_handled()

func _update_selection() -> void:
	for i in _preview_rects.size():
		if i == _selected_index:
			_preview_rects[i].get_parent().scale = Vector2(1.1, 1.1)
			_preview_rects[i].get_parent().modulate = Color.WHITE
		elif GameManager.is_2p and _selecting_p2 and i == _p2_selected_index:
			_preview_rects[i].get_parent().scale = Vector2(1.1, 1.1)
			_preview_rects[i].get_parent().modulate = Color(0.8, 1.0, 0.8)
		else:
			_preview_rects[i].get_parent().scale = Vector2(0.9, 0.9)
			_preview_rects[i].get_parent().modulate = Color(0.5, 0.5, 0.5)

	# Update title for P2 selection
	var title_node := get_node_or_null("Title")
	if title_node:
		if _selecting_p2:
			title_node.text = "P2 — SELECT YOUR ARMY"
		elif GameManager.is_2p:
			title_node.text = "P1 — SELECT YOUR ARMY"
		else:
			title_node.text = "SELECT YOUR ARMY"

func _confirm() -> void:
	if GameManager.is_2p and not _selecting_p2:
		# P1 confirmed, now P2 selects
		_selecting_p2 = true
		_update_selection()
		return

	# Store selections and go to battle
	GameManager.selected_chart["p1_army_color"] = _variants[_selected_index]["color"]
	GameManager.selected_chart["p1_army_name"] = _variants[_selected_index]["name"]
	if GameManager.is_2p:
		GameManager.selected_chart["p2_army_color"] = _variants[_p2_selected_index]["color"]
		GameManager.selected_chart["p2_army_name"] = _variants[_p2_selected_index]["name"]

	Events.scene_change_requested.emit("res://scenes/Battle.tscn")
