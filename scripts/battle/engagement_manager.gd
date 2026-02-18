extends Node2D
## EngagementManager — micro-engagement clustering + round-robin cycling.
## Takes both armies + formation string → creates engagement clusters.
## Each engagement: {index, player_units[], enemy_units[], position, active, resolved, highlight_node}
## Round-robin: each note targets a different engagement, cycling through unresolved ones.

signal all_engagements_resolved()

var _engagements: Array = []
var _current_engagement: int = 0
var _player_army: Node2D = null
var _enemy_army: Node2D = null
var _formation: String = "solo"
var _highlight_nodes: Array = []

# Predefined layouts for engagement positions
const SOLO_POSITIONS := [
	# 2 rows of 3 — spread across battlefield
	Vector2(200, 200), Vector2(640, 180), Vector2(1060, 200),
	Vector2(280, 380), Vector2(640, 400), Vector2(980, 380),
]

const PAIR_POSITIONS := [
	# Triangle layout
	Vector2(300, 220), Vector2(900, 220), Vector2(600, 380),
]

const SQUAD_POSITIONS := [
	# Triangle layout (same as pair)
	Vector2(300, 220), Vector2(900, 220), Vector2(600, 380),
]

const HIGHLIGHT_ACTIVE_COLOR := Color(1.0, 0.0, 0.8, 0.35)  # Magenta for active
const HIGHLIGHT_GROUP_COLOR := Color(0.0, 0.9, 0.3, 0.2)    # Green for multi-unit groups

func setup(player_army: Node2D, enemy_army: Node2D, formation: String) -> void:
	_player_army = player_army
	_enemy_army = enemy_army
	_formation = formation
	_create_engagements()

func _create_engagements() -> void:
	_engagements.clear()
	_current_engagement = 0

	var player_groups: Array = _get_unit_groups(_player_army)
	var enemy_groups: Array = _get_unit_groups(_enemy_army)
	var positions: Array = _get_positions()

	var count: int = mini(player_groups.size(), mini(enemy_groups.size(), positions.size()))

	for i in count:
		var engagement := {
			"index": i,
			"player_units": player_groups[i],
			"enemy_units": enemy_groups[i],
			"position": positions[i],
			"active": false,
			"resolved": false,
			"highlight_node": null,
		}

		# Set engagement_index on units
		for unit in engagement["player_units"]:
			if unit and unit.is_alive:
				unit.engagement_index = i
		for unit in engagement["enemy_units"]:
			if unit and unit.is_alive:
				unit.engagement_index = i

		_engagements.append(engagement)

	# Activate first engagement
	if _engagements.size() > 0:
		_engagements[0]["active"] = true

	_create_highlight_nodes()

func _get_unit_groups(army: Node2D) -> Array:
	var alive_units: Array = army.get_alive_units()
	var groups: Array = []

	match _formation:
		"solo":
			# 6 groups of 1
			for unit in alive_units:
				groups.append([unit])
		"pair", "squad":
			# 3 groups of 2
			var i := 0
			while i < alive_units.size() - 1:
				groups.append([alive_units[i], alive_units[i + 1]])
				i += 2
			# Leftover unit joins last group
			if i < alive_units.size() and groups.size() > 0:
				groups[groups.size() - 1].append(alive_units[i])
		"legion":
			# Falls back to squad for now
			var j := 0
			while j < alive_units.size() - 1:
				groups.append([alive_units[j], alive_units[j + 1]])
				j += 2
			if j < alive_units.size() and groups.size() > 0:
				groups[groups.size() - 1].append(alive_units[j])
		_:
			for unit in alive_units:
				groups.append([unit])

	return groups

func _get_positions() -> Array:
	match _formation:
		"solo": return SOLO_POSITIONS.duplicate()
		"pair": return PAIR_POSITIONS.duplicate()
		"squad": return SQUAD_POSITIONS.duplicate()
		"legion": return SQUAD_POSITIONS.duplicate()
		_: return SOLO_POSITIONS.duplicate()

func _create_highlight_nodes() -> void:
	# Clean up old highlights
	for node in _highlight_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_highlight_nodes.clear()

	for eng in _engagements:
		var hl := _EngagementHighlight.new()
		hl.position = eng["position"]
		hl.is_multi_unit = eng["player_units"].size() > 1 or eng["enemy_units"].size() > 1
		hl.is_active = eng["active"]
		add_child(hl)
		eng["highlight_node"] = hl
		_highlight_nodes.append(hl)

func redistribute_units() -> void:
	## Animate units from army formation to engagement cluster positions.
	for eng in _engagements:
		var pos: Vector2 = eng["position"]
		var all_units: Array = eng["player_units"] + eng["enemy_units"]
		var unit_count: int = all_units.size()

		for i in unit_count:
			var unit: Node2D = all_units[i]
			if not is_instance_valid(unit) or not unit.is_alive:
				continue

			# Calculate target position around the engagement center
			var offset := _get_unit_offset_in_engagement(i, unit_count, unit.army_side)
			var target_global := pos + offset

			# Convert to local position relative to army parent
			var army_parent: Node2D = unit.get_parent()
			var target_local: Vector2 = target_global - army_parent.global_position

			# Tween to position
			var tween := unit.create_tween()
			tween.tween_property(unit, "position", target_local, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func _get_unit_offset_in_engagement(index: int, total: int, side: String) -> Vector2:
	## Returns offset from engagement center for a unit within the cluster.
	var spacing := 35.0
	if total == 1:
		return Vector2(-20 if side == "player" else 20, 0)
	elif total == 2:
		var x_off: float = -25 if side == "player" else 25
		var y_off: float = -18.0 + index * 36.0
		return Vector2(x_off, y_off)
	else:
		# For 3+ units, arrange in a small cluster
		var angle := (float(index) / float(total)) * TAU
		var radius := spacing * 0.8
		var x_off: float = cos(angle) * radius + (-15 if side == "player" else 15)
		return Vector2(x_off, sin(angle) * radius)

func get_active_engagement() -> Dictionary:
	if _current_engagement >= 0 and _current_engagement < _engagements.size():
		return _engagements[_current_engagement]
	return {}

func get_active_player_unit() -> Node2D:
	## Returns the first alive player unit in the current engagement.
	var eng := get_active_engagement()
	if eng.is_empty():
		return null
	for unit in eng["player_units"]:
		if is_instance_valid(unit) and unit.is_alive:
			return unit
	return null

func get_active_enemy_unit() -> Node2D:
	## Returns the first alive enemy unit in the current engagement.
	var eng := get_active_engagement()
	if eng.is_empty():
		return null
	for unit in eng["enemy_units"]:
		if is_instance_valid(unit) and unit.is_alive:
			return unit
	return null

func advance_engagement() -> void:
	## Called after each note resolves. Rotates to next unresolved engagement.
	_check_resolved()

	# Deactivate current
	if _current_engagement < _engagements.size():
		_engagements[_current_engagement]["active"] = false

	# Find next unresolved
	var start := _current_engagement
	var found := false
	for _i in _engagements.size():
		_current_engagement = (_current_engagement + 1) % _engagements.size()
		if not _engagements[_current_engagement]["resolved"]:
			found = true
			break

	if not found:
		# All resolved
		all_engagements_resolved.emit()
		return

	# Activate new engagement
	_engagements[_current_engagement]["active"] = true
	var eng: Dictionary = _engagements[_current_engagement]
	Events.engagement_activated.emit(eng["index"], eng["player_units"], eng["enemy_units"])

	_update_highlights()

func _check_resolved() -> void:
	## Mark engagements as resolved if all units on either side are dead.
	for eng in _engagements:
		if eng["resolved"]:
			continue
		var player_alive := false
		for unit in eng["player_units"]:
			if is_instance_valid(unit) and unit.is_alive:
				player_alive = true
				break
		var enemy_alive := false
		for unit in eng["enemy_units"]:
			if is_instance_valid(unit) and unit.is_alive:
				enemy_alive = true
				break
		if not player_alive or not enemy_alive:
			eng["resolved"] = true
			Events.engagement_resolved.emit(eng["index"])

func _update_highlights() -> void:
	for eng in _engagements:
		var hl = eng["highlight_node"]
		if is_instance_valid(hl):
			hl.is_active = eng["active"]
			hl.is_resolved = eng["resolved"]
			hl.queue_redraw()

func get_engagement_count() -> int:
	return _engagements.size()

func get_unresolved_count() -> int:
	var count := 0
	for eng in _engagements:
		if not eng["resolved"]:
			count += 1
	return count

## Inner class for engagement highlight rendering
class _EngagementHighlight extends Node2D:
	var is_multi_unit: bool = false
	var is_active: bool = false
	var is_resolved: bool = false
	var _pulse: float = 0.0

	func _process(delta: float) -> void:
		_pulse += delta * 3.0
		queue_redraw()

	func _draw() -> void:
		if is_resolved:
			return

		var size := Vector2(100, 80)
		if is_multi_unit:
			size = Vector2(130, 100)

		var half := size / 2
		var rect := Rect2(-half, size)

		if is_active:
			# Magenta highlight with pulse
			var alpha := 0.25 + 0.1 * sin(_pulse)
			draw_rect(rect, Color(1.0, 0.0, 0.8, alpha), false, 2.5)
			# Inner glow
			draw_rect(rect.grow(-3), Color(1.0, 0.0, 0.8, alpha * 0.3), true)
		elif is_multi_unit:
			# Green border for multi-unit groups
			draw_rect(rect, Color(0.0, 0.9, 0.3, 0.2), false, 1.5)
