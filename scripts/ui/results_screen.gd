extends Node2D
## ResultsScreen — post-battle stats comparison, winner display.
## Graphics V1: styled panels with borders, improved grade breakdown bar.

var _results: Dictionary = {}

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.05, 0.04, 0.09))
	_results = GameManager.last_results
	_build_ui()

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

	var winner: String = _results.get("winner", "draw")

	# Winner announcement
	var winner_label := Label.new()
	winner_label.position = Vector2(340, 30)
	winner_label.size = Vector2(600, 60)
	winner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	winner_label.add_theme_font_size_override("font_size", 48)
	match winner:
		"player":
			winner_label.text = "VICTORY!"
			winner_label.add_theme_color_override("font_color", Color(0.94, 0.78, 0.31))
		_:
			winner_label.text = "DEFEAT"
			winner_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	add_child(winner_label)

	# Stage name
	var stage_label := Label.new()
	stage_label.text = "Stage: %s" % _results.get("stage_id", "unknown")
	stage_label.position = Vector2(340, 95)
	stage_label.size = Vector2(600, 30)
	stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_label.add_theme_font_size_override("font_size", 18)
	stage_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	add_child(stage_label)

	# Round count (only show if multi-round battle)
	var total_rounds: int = _results.get("total_rounds", 1)
	if total_rounds > 1:
		var round_label := Label.new()
		round_label.text = "Rounds: %d" % total_rounds
		round_label.position = Vector2(340, 118)
		round_label.size = Vector2(600, 24)
		round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		round_label.add_theme_font_size_override("font_size", 15)
		round_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		add_child(round_label)

	# P1 stats
	_build_player_stats(_results, Vector2(140, 150), "PLAYER 1")

	# P2 stats (if 2P mode)
	if _results.has("p2"):
		_build_player_stats(_results["p2"], Vector2(700, 150), "PLAYER 2")

	# Grade breakdown bar
	_build_grade_bar(_results, Vector2(140, 520))

	# Controls
	var hint := Label.new()
	hint.text = "Enter / A — Return to Menu  |  R — Replay"
	hint.position = Vector2(380, 660)
	hint.size = Vector2(520, 30)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	add_child(hint)

func _build_player_stats(data: Dictionary, pos: Vector2, title: String) -> void:
	var container := Node2D.new()
	container.position = pos
	add_child(container)

	# Panel border (outer frame)
	var border := ColorRect.new()
	border.size = Vector2(424, 354)
	border.position = Vector2(-2, -2)
	border.color = Color(0.3, 0.3, 0.4, 0.5)
	container.add_child(border)

	# Background panel
	var bg := ColorRect.new()
	bg.size = Vector2(420, 350)
	bg.color = Color(0.08, 0.06, 0.12)
	container.add_child(bg)

	# Top accent bar
	var accent := ColorRect.new()
	accent.size = Vector2(420, 3)
	accent.color = Color(0.94, 0.78, 0.31, 0.5)
	container.add_child(accent)

	# Title
	var title_label := Label.new()
	title_label.text = title
	title_label.position = Vector2(0, 10)
	title_label.size = Vector2(420, 30)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", Color(0.94, 0.78, 0.31))
	container.add_child(title_label)

	# Separator under title
	var sep := ColorRect.new()
	sep.size = Vector2(380, 1)
	sep.position = Vector2(20, 42)
	sep.color = Color(0.3, 0.3, 0.4, 0.4)
	container.add_child(sep)

	# Stats list
	var stats := [
		["Score", str(data.get("score", 0)), Color(1.0, 0.9, 0.4)],
		["Max Combo", str(data.get("combo", 0)), Color(0.4, 1.0, 0.6)],
		["Accuracy", "%.1f%%" % data.get("accuracy", 0.0), Color(0.4, 0.8, 1.0)],
		["Perfect", str(data.get("perfects", 0)), Judgment.get_grade_color(Judgment.GRADE_PERFECT)],
		["Great", str(data.get("greats", 0)), Judgment.get_grade_color(Judgment.GRADE_GREAT)],
		["Good", str(data.get("goods", 0)), Judgment.get_grade_color(Judgment.GRADE_GOOD)],
		["Bad", str(data.get("bads", 0)), Judgment.get_grade_color(Judgment.GRADE_BAD)],
		["Miss", str(data.get("misses", 0)), Judgment.get_grade_color(Judgment.GRADE_MISS)],
	]

	var y := 55.0
	for stat in stats:
		var name_lbl := Label.new()
		name_lbl.text = stat[0]
		name_lbl.position = Vector2(30, y)
		name_lbl.add_theme_font_size_override("font_size", 18)
		name_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
		container.add_child(name_lbl)

		var val_lbl := Label.new()
		val_lbl.text = stat[1]
		val_lbl.position = Vector2(250, y)
		val_lbl.size = Vector2(140, 25)
		val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		val_lbl.add_theme_font_size_override("font_size", 18)
		val_lbl.add_theme_color_override("font_color", stat[2])
		container.add_child(val_lbl)

		y += 35.0

	# Rank
	var rank := _calculate_rank(data)
	var rank_label := Label.new()
	rank_label.text = rank
	rank_label.position = Vector2(150, y + 10)
	rank_label.size = Vector2(120, 50)
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_label.add_theme_font_size_override("font_size", 40)
	rank_label.add_theme_color_override("font_color", _rank_color(rank))
	container.add_child(rank_label)

func _build_grade_bar(data: Dictionary, pos: Vector2) -> void:
	var total: int = data.get("total_notes", 1)
	if total == 0:
		total = 1
	var bar_width := 1000.0
	var bar_height := 20.0

	var container := Node2D.new()
	container.position = pos
	add_child(container)

	# Label
	var bar_label := Label.new()
	bar_label.text = "Grade Distribution"
	bar_label.position = Vector2(0, -22)
	bar_label.add_theme_font_size_override("font_size", 13)
	bar_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	container.add_child(bar_label)

	# Border frame
	var frame := ColorRect.new()
	frame.size = Vector2(bar_width + 4, bar_height + 4)
	frame.position = Vector2(-2, -2)
	frame.color = Color(0.3, 0.3, 0.4, 0.4)
	container.add_child(frame)

	# Background
	var bg := ColorRect.new()
	bg.size = Vector2(bar_width, bar_height)
	bg.color = Color(0.1, 0.1, 0.15)
	container.add_child(bg)

	var grades := [
		[data.get("perfects", 0), Judgment.get_grade_color(Judgment.GRADE_PERFECT), "Perfect"],
		[data.get("greats", 0), Judgment.get_grade_color(Judgment.GRADE_GREAT), "Great"],
		[data.get("goods", 0), Judgment.get_grade_color(Judgment.GRADE_GOOD), "Good"],
		[data.get("bads", 0), Judgment.get_grade_color(Judgment.GRADE_BAD), "Bad"],
		[data.get("misses", 0), Judgment.get_grade_color(Judgment.GRADE_MISS), "Miss"],
	]

	var x_offset := 0.0
	for g in grades:
		var w: float = (float(g[0]) / float(total)) * bar_width
		if w > 0:
			var rect := ColorRect.new()
			rect.size = Vector2(w, bar_height)
			rect.position = Vector2(x_offset, 0)
			rect.color = g[1]
			container.add_child(rect)
			x_offset += w

	# Grade legend below bar
	var legend_x := 0.0
	for g in grades:
		if g[0] > 0:
			var legend := Label.new()
			legend.text = "%s: %d" % [g[2], g[0]]
			legend.position = Vector2(legend_x, bar_height + 6)
			legend.add_theme_font_size_override("font_size", 11)
			legend.add_theme_color_override("font_color", g[1])
			container.add_child(legend)
			legend_x += 120.0

func _calculate_rank(data: Dictionary) -> String:
	var accuracy: float = data.get("accuracy", 0.0)
	var perfects: int = data.get("perfects", 0)
	var total: int = data.get("total_notes", 1)

	if perfects == total and total > 0:
		return "S+"
	elif accuracy >= 95.0:
		return "S"
	elif accuracy >= 90.0:
		return "A"
	elif accuracy >= 80.0:
		return "B"
	elif accuracy >= 70.0:
		return "C"
	elif accuracy >= 60.0:
		return "D"
	else:
		return "F"

func _rank_color(rank: String) -> Color:
	match rank:
		"S+": return Color(1.0, 0.85, 0.0)
		"S": return Color(1.0, 0.9, 0.3)
		"A": return Color(0.3, 1.0, 0.5)
		"B": return Color(0.3, 0.7, 1.0)
		"C": return Color(0.7, 0.7, 0.7)
		"D": return Color(0.8, 0.5, 0.2)
		_: return Color(1.0, 0.2, 0.2)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_menu_confirm") or event.is_action_pressed("p1_face_a"):
		SfxManager.play("ui_confirm")
		Events.scene_change_requested.emit("res://scenes/MainMenu.tscn")
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_R:
		SfxManager.play("ui_confirm")
		# Replay same stage
		Events.scene_change_requested.emit("res://scenes/Battle.tscn")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_menu_back") or event.is_action_pressed("p1_face_b"):
		SfxManager.play("ui_back")
		Events.scene_change_requested.emit("res://scenes/MainMenu.tscn")
		get_viewport().set_input_as_handled()
