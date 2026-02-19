extends Node2D
## CharacterSelect — pick army color variant per player before battle.
## Graphics V1: shield-shaped army crests with faction emblems, shader BG.

var _variants: Array[Dictionary] = []
var _selected_index: int = 0
var _p2_selected_index: int = 1
var _preview_containers: Array[Node2D] = []
var _selecting_p2: bool = false

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.05, 0.04, 0.09))
	_setup_variants()
	_build_ui()
	_update_selection()

func _setup_variants() -> void:
	_variants = [
		{"name": "Azure Guard", "color": Color(0.25, 0.45, 0.85), "accent": Color(0.4, 0.7, 1.0), "emblem": "shield"},
		{"name": "Crimson Legion", "color": Color(0.85, 0.2, 0.2), "accent": Color(1.0, 0.4, 0.3), "emblem": "sword"},
		{"name": "Emerald Phalanx", "color": Color(0.15, 0.7, 0.3), "accent": Color(0.3, 1.0, 0.5), "emblem": "leaf"},
		{"name": "Golden Horde", "color": Color(0.85, 0.7, 0.15), "accent": Color(1.0, 0.9, 0.3), "emblem": "crown"},
		{"name": "Shadow Vanguard", "color": Color(0.35, 0.25, 0.5), "accent": Color(0.6, 0.4, 0.9), "emblem": "dagger"},
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
	var title := Label.new()
	title.text = "SELECT YOUR ARMY" if not GameManager.is_2p else "P1 — SELECT YOUR ARMY"
	title.position = Vector2(390, 30)
	title.size = Vector2(500, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.94, 0.78, 0.31))
	title.name = "Title"
	add_child(title)

	# Army crest previews
	var start_x := 190.0
	var sq_size := 120.0
	var spacing := 50.0

	for i in _variants.size():
		var variant := _variants[i]

		var container := Node2D.new()
		container.position = Vector2(start_x + i * (sq_size + spacing), 200)
		add_child(container)
		_preview_containers.append(container)

		# Background panel with border
		var border := ColorRect.new()
		border.size = Vector2(sq_size + 4, sq_size + 4)
		border.position = Vector2(-2, -2)
		border.color = variant["accent"].darkened(0.5)
		border.z_index = -1
		container.add_child(border)

		var panel_bg := ColorRect.new()
		panel_bg.size = Vector2(sq_size, sq_size)
		panel_bg.color = Color(0.1, 0.08, 0.14)
		container.add_child(panel_bg)

		# Army color fill (inner area)
		var fill := ColorRect.new()
		fill.size = Vector2(sq_size - 16, sq_size - 16)
		fill.position = Vector2(8, 8)
		fill.color = variant["color"].darkened(0.2)
		container.add_child(fill)

		# Crest drawing node
		var crest := _ArmyCrest.new()
		crest.position = Vector2(sq_size / 2, sq_size / 2)
		crest.crest_color = variant["accent"]
		crest.emblem_type = variant["emblem"]
		container.add_child(crest)

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
		SfxManager.play("ui_navigate")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_menu_left") or event.is_action_pressed("p1_left"):
		if not _selecting_p2:
			_selected_index = maxi(_selected_index - 1, 0)
		else:
			_p2_selected_index = maxi(_p2_selected_index - 1, 0)
		_update_selection()
		SfxManager.play("ui_navigate")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_menu_confirm") or event.is_action_pressed("p1_face_a"):
		SfxManager.play("ui_confirm")
		_confirm()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_menu_back") or event.is_action_pressed("p1_face_b"):
		SfxManager.play("ui_back")
		if _selecting_p2:
			_selecting_p2 = false
			_update_selection()
		else:
			Events.scene_change_requested.emit("res://scenes/StageSelect.tscn")
		get_viewport().set_input_as_handled()

func _update_selection() -> void:
	for i in _preview_containers.size():
		var container := _preview_containers[i]
		var border: ColorRect = container.get_child(0)
		if i == _selected_index:
			container.scale = Vector2(1.1, 1.1)
			container.modulate = Color.WHITE
			border.color = _variants[i]["accent"]
		elif GameManager.is_2p and _selecting_p2 and i == _p2_selected_index:
			container.scale = Vector2(1.1, 1.1)
			container.modulate = Color(0.8, 1.0, 0.8)
			border.color = _variants[i]["accent"].lightened(0.2)
		else:
			container.scale = Vector2(0.9, 0.9)
			container.modulate = Color(0.5, 0.5, 0.5)
			border.color = _variants[i]["accent"].darkened(0.6)

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


## Inner class for drawing army crest emblems
class _ArmyCrest extends Node2D:
	var crest_color: Color = Color.WHITE
	var emblem_type: String = "shield"

	func _draw() -> void:
		match emblem_type:
			"shield":
				# Shield shape
				var pts := PackedVector2Array([
					Vector2(0, -20), Vector2(18, -12), Vector2(18, 8),
					Vector2(0, 22), Vector2(-18, 8), Vector2(-18, -12)
				])
				draw_colored_polygon(pts, Color(crest_color.r, crest_color.g, crest_color.b, 0.5))
				draw_polyline(pts + PackedVector2Array([pts[0]]), crest_color, 1.5)
			"sword":
				# Sword cross
				draw_line(Vector2(0, -20), Vector2(0, 18), crest_color, 2.0)
				draw_line(Vector2(-10, -6), Vector2(10, -6), crest_color, 2.0)
				draw_line(Vector2(-3, 18), Vector2(3, 18), crest_color, 1.5)
			"leaf":
				# Leaf / nature
				var pts := PackedVector2Array([
					Vector2(0, -18), Vector2(12, -4), Vector2(8, 10),
					Vector2(0, 18), Vector2(-8, 10), Vector2(-12, -4)
				])
				draw_colored_polygon(pts, Color(crest_color.r, crest_color.g, crest_color.b, 0.4))
				draw_line(Vector2(0, -18), Vector2(0, 18), crest_color, 1.5)
			"crown":
				# Crown shape
				var pts := PackedVector2Array([
					Vector2(-14, 6), Vector2(-14, -4), Vector2(-8, -10),
					Vector2(0, -4), Vector2(8, -10), Vector2(14, -4),
					Vector2(14, 6)
				])
				draw_polyline(pts, crest_color, 2.0)
				draw_line(Vector2(-14, 6), Vector2(14, 6), crest_color, 2.0)
			"dagger":
				# Dagger
				draw_line(Vector2(0, -18), Vector2(0, 12), crest_color, 2.0)
				draw_line(Vector2(-6, -4), Vector2(6, -4), crest_color, 2.0)
				# Blade tip
				var tip := PackedVector2Array([
					Vector2(-3, 12), Vector2(0, 20), Vector2(3, 12)
				])
				draw_colored_polygon(tip, crest_color)
