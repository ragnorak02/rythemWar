extends CanvasLayer
## AchievementPopup — toast notification for achievement unlocks.
## Graphics V1: styled panel with border, icon slot, gold accent.

var _panel: ColorRect = null
var _title_label: Label = null
var _desc_label: Label = null
var _queue: Array[Dictionary] = []
var _showing: bool = false

func _ready() -> void:
	layer = 100
	_build_popup()
	Events.achievement_unlocked.connect(_on_achievement_unlocked)

func _build_popup() -> void:
	# Panel outer border
	var border := ColorRect.new()
	border.size = Vector2(354, 74)
	border.position = Vector2(928, -82)
	border.color = Color(0.94, 0.78, 0.31, 0.4)
	border.name = "Border"
	add_child(border)

	# Panel background
	_panel = ColorRect.new()
	_panel.size = Vector2(350, 70)
	_panel.position = Vector2(930, -80)  # Start off-screen (above)
	_panel.color = Color(0.1, 0.08, 0.16, 0.95)
	add_child(_panel)

	# Gold accent bar (left edge)
	var accent := ColorRect.new()
	accent.size = Vector2(4, 70)
	accent.color = Color(0.94, 0.78, 0.31)
	_panel.add_child(accent)

	# Achievement icon placeholder (trophy shape area)
	var icon_bg := ColorRect.new()
	icon_bg.size = Vector2(36, 36)
	icon_bg.position = Vector2(14, 17)
	icon_bg.color = Color(0.94, 0.78, 0.31, 0.15)
	_panel.add_child(icon_bg)

	# Trophy symbol
	var trophy := Label.new()
	trophy.text = "T"
	trophy.position = Vector2(14, 17)
	trophy.size = Vector2(36, 36)
	trophy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	trophy.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	trophy.add_theme_font_size_override("font_size", 20)
	trophy.add_theme_color_override("font_color", Color(0.94, 0.78, 0.31))
	_panel.add_child(trophy)

	# "ACHIEVEMENT" header
	var header := Label.new()
	header.text = "ACHIEVEMENT UNLOCKED"
	header.position = Vector2(58, 5)
	header.add_theme_font_size_override("font_size", 10)
	header.add_theme_color_override("font_color", Color(0.94, 0.78, 0.31, 0.7))
	_panel.add_child(header)

	# Title
	_title_label = Label.new()
	_title_label.text = ""
	_title_label.position = Vector2(58, 22)
	_title_label.size = Vector2(280, 22)
	_title_label.add_theme_font_size_override("font_size", 16)
	_title_label.add_theme_color_override("font_color", Color.WHITE)
	_panel.add_child(_title_label)

	# Description
	_desc_label = Label.new()
	_desc_label.text = ""
	_desc_label.position = Vector2(58, 46)
	_desc_label.size = Vector2(280, 20)
	_desc_label.add_theme_font_size_override("font_size", 11)
	_desc_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	_panel.add_child(_desc_label)

func _on_achievement_unlocked(achievement_id: String, title: String) -> void:
	var desc := ""
	for ach in AchievementManager.get_achievements():
		if ach["id"] == achievement_id:
			desc = ach.get("description", "")
			break
	_queue.append({"title": title, "desc": desc})
	if not _showing:
		_show_next()

func _show_next() -> void:
	if _queue.is_empty():
		_showing = false
		return

	_showing = true
	var data: Dictionary = _queue.pop_front()
	_title_label.text = data["title"]
	_desc_label.text = data["desc"]

	# Slide in from top (both border and panel)
	var border_node := get_node_or_null("Border")
	var tween := create_tween()
	tween.tween_property(_panel, "position:y", 20.0, 0.3).set_ease(Tween.EASE_OUT)
	if border_node:
		tween.parallel().tween_property(border_node, "position:y", 18.0, 0.3).set_ease(Tween.EASE_OUT)
	tween.tween_interval(3.0)
	tween.tween_property(_panel, "position:y", -80.0, 0.3).set_ease(Tween.EASE_IN)
	if border_node:
		tween.parallel().tween_property(border_node, "position:y", -82.0, 0.3).set_ease(Tween.EASE_IN)
	tween.tween_callback(_show_next)
