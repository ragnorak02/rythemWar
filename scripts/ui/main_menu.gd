extends Node2D
## MainMenu — Continue / 1P Begin / 2P Begin / Settings / Exit
## Graphics V1: shader background with stars, particle atmosphere, glowing selector.

var _menu_items: Array[Dictionary] = []
var _selected_index: int = 0
var _labels: Array[Label] = []
var _selector: ColorRect = null
var _title_label: Label = null

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.05, 0.04, 0.09))
	_setup_menu_items()
	_build_ui()
	_update_selection()

func _setup_menu_items() -> void:
	_menu_items = [
		{"label": "Continue", "action": "continue", "enabled": SaveManager.has_save()},
		{"label": "1P Begin", "action": "1p_begin", "enabled": true},
		{"label": "2P Begin", "action": "2p_begin", "enabled": true},
		{"label": "Settings", "action": "settings", "enabled": false},
		{"label": "Exit", "action": "exit", "enabled": true},
	]
	# Skip to first enabled item if Continue is disabled
	if not _menu_items[0]["enabled"]:
		_selected_index = 1

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

	# Floating dust particles for atmosphere
	var particles := CPUParticles2D.new()
	particles.position = Vector2(640, 360)
	particles.amount = 30
	particles.lifetime = 6.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(640, 360)
	particles.direction = Vector2(0, -1)
	particles.spread = 30.0
	particles.initial_velocity_min = 5.0
	particles.initial_velocity_max = 15.0
	particles.gravity = Vector2(0, 0)
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 2.5
	particles.color = Color(0.94, 0.78, 0.31, 0.15)
	particles.z_index = -5
	add_child(particles)

	# Title
	_title_label = Label.new()
	_title_label.text = "RHYTHM WAR"
	_title_label.position = Vector2(440, 80)
	_title_label.size = Vector2(400, 80)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 56)
	_title_label.add_theme_color_override("font_color", Color(0.94, 0.78, 0.31))
	add_child(_title_label)

	# Title glow (shadow label behind for glow effect)
	var title_glow := Label.new()
	title_glow.text = "RHYTHM WAR"
	title_glow.position = Vector2(440, 80)
	title_glow.size = Vector2(400, 80)
	title_glow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_glow.add_theme_font_size_override("font_size", 56)
	title_glow.add_theme_color_override("font_color", Color(0.94, 0.78, 0.31, 0.15))
	title_glow.scale = Vector2(1.03, 1.03)
	title_glow.z_index = -1
	add_child(title_glow)

	# Subtitle
	var subtitle := Label.new()
	subtitle.text = "Command Your Army Through Rhythm"
	subtitle.position = Vector2(440, 150)
	subtitle.size = Vector2(400, 30)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.6, 0.55, 0.45))
	add_child(subtitle)

	# Selector highlight with glow shader
	_selector = ColorRect.new()
	_selector.size = Vector2(300, 40)
	var sel_shader := load("res://assets/shaders/selector_glow.gdshader")
	if sel_shader:
		var mat := ShaderMaterial.new()
		mat.shader = sel_shader
		_selector.material = mat
	else:
		_selector.color = Color(0.94, 0.78, 0.31, 0.15)
	add_child(_selector)

	# Menu items
	var start_y := 260.0
	for i in _menu_items.size():
		var label := Label.new()
		label.text = _menu_items[i]["label"]
		label.position = Vector2(490, start_y + i * 60)
		label.size = Vector2(300, 40)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 28)
		if _menu_items[i]["enabled"]:
			label.add_theme_color_override("font_color", Color.WHITE)
		else:
			label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.35))
		add_child(label)
		_labels.append(label)

	# Decorative divider lines
	var divider_top := ColorRect.new()
	divider_top.size = Vector2(200, 1)
	divider_top.position = Vector2(540, 240)
	divider_top.color = Color(0.94, 0.78, 0.31, 0.3)
	add_child(divider_top)

	var divider_bot := ColorRect.new()
	divider_bot.size = Vector2(200, 1)
	divider_bot.position = Vector2(540, start_y + _menu_items.size() * 60 + 10)
	divider_bot.color = Color(0.94, 0.78, 0.31, 0.3)
	add_child(divider_bot)

	# Controls hint
	var hint := Label.new()
	hint.text = "Arrow Keys / D-Pad to navigate  |  Enter / A to select"
	hint.position = Vector2(340, 660)
	hint.size = Vector2(600, 30)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	add_child(hint)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_menu_down") or event.is_action_pressed("p1_down"):
		_move_selection(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_menu_up") or event.is_action_pressed("p1_up"):
		_move_selection(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_menu_confirm") or event.is_action_pressed("p1_face_a"):
		_confirm_selection()
		get_viewport().set_input_as_handled()

func _move_selection(direction: int) -> void:
	var new_index := _selected_index
	for i in _menu_items.size():
		new_index = wrapi(new_index + direction, 0, _menu_items.size())
		if _menu_items[new_index]["enabled"]:
			break
	_selected_index = new_index
	_update_selection()
	SfxManager.play("ui_navigate")
	Events.menu_selection_changed.emit(_selected_index)

func _update_selection() -> void:
	var start_y := 260.0
	_selector.position = Vector2(490, start_y + _selected_index * 60)
	for i in _labels.size():
		if i == _selected_index and _menu_items[i]["enabled"]:
			_labels[i].add_theme_color_override("font_color", Color(0.94, 0.78, 0.31))
		elif _menu_items[i]["enabled"]:
			_labels[i].add_theme_color_override("font_color", Color.WHITE)

func _confirm_selection() -> void:
	if not _menu_items[_selected_index]["enabled"]:
		return
	SfxManager.play("ui_confirm")

	var action: String = _menu_items[_selected_index]["action"]
	match action:
		"continue":
			SaveManager.load_game()
			Events.scene_change_requested.emit("res://scenes/StageSelect.tscn")
		"1p_begin":
			GameManager.is_2p = false
			Events.scene_change_requested.emit("res://scenes/StageSelect.tscn")
		"2p_begin":
			GameManager.is_2p = true
			Events.scene_change_requested.emit("res://scenes/StageSelect.tscn")
		"settings":
			pass  # TODO: Settings screen
		"exit":
			get_tree().quit()

	Events.menu_confirmed.emit(_selected_index)
