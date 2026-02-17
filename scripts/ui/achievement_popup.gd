extends CanvasLayer
## AchievementPopup — toast notification for achievement unlocks.
## Auto-creates itself and fades in/out.

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
	# Panel background
	_panel = ColorRect.new()
	_panel.size = Vector2(350, 70)
	_panel.position = Vector2(930, -80)  # Start off-screen (above)
	_panel.color = Color(0.12, 0.1, 0.2, 0.95)
	add_child(_panel)

	# Gold accent bar
	var accent := ColorRect.new()
	accent.size = Vector2(4, 70)
	accent.color = Color(0.94, 0.78, 0.31)
	_panel.add_child(accent)

	# "ACHIEVEMENT" header
	var header := Label.new()
	header.text = "ACHIEVEMENT UNLOCKED"
	header.position = Vector2(15, 5)
	header.add_theme_font_size_override("font_size", 11)
	header.add_theme_color_override("font_color", Color(0.94, 0.78, 0.31))
	_panel.add_child(header)

	# Title
	_title_label = Label.new()
	_title_label.text = ""
	_title_label.position = Vector2(15, 25)
	_title_label.add_theme_font_size_override("font_size", 18)
	_title_label.add_theme_color_override("font_color", Color.WHITE)
	_panel.add_child(_title_label)

	# Description
	_desc_label = Label.new()
	_desc_label.text = ""
	_desc_label.position = Vector2(15, 48)
	_desc_label.size = Vector2(320, 20)
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

	# Slide in from top
	var tween := create_tween()
	tween.tween_property(_panel, "position:y", 20.0, 0.3).set_ease(Tween.EASE_OUT)
	tween.tween_interval(3.0)
	tween.tween_property(_panel, "position:y", -80.0, 0.3).set_ease(Tween.EASE_IN)
	tween.tween_callback(_show_next)
