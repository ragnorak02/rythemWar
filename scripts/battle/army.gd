extends Node2D
## Army — spawns and manages 6 units in a stagger formation.

var army_side: String = "player"  # "player" or "enemy"
var units: Array = []
var alive_count: int = 6

# Unit type data
var _unit_types_data: Array = []
var _composition: Array = []

const UNIT_COUNT := 6
const UNIT_SCENE := preload("res://scenes/units/Unit.tscn")

# Stagger layout: 2 columns, 3 rows — organic formation
const FORMATION := [
	Vector2(0, -50),   # front top
	Vector2(0, 0),     # front mid
	Vector2(0, 50),    # front bottom
	Vector2(-40, -30), # back top
	Vector2(-40, 20),  # back mid
	Vector2(-40, 60),  # back bottom
]

const PLAYER_COLOR := Color(0.25, 0.45, 0.85)  # Blue
const ENEMY_COLOR := Color(0.85, 0.25, 0.25)   # Red

func setup(side: String) -> void:
	army_side = side
	var base_color: Color = PLAYER_COLOR if side == "player" else ENEMY_COLOR

	for i in UNIT_COUNT:
		var unit_node: Node2D = UNIT_SCENE.instantiate()
		add_child(unit_node)

		var offset: Vector2 = FORMATION[i]
		if side == "enemy":
			offset.x *= -1  # Mirror for enemy side

		unit_node.position = offset
		# Slight color variation per unit
		var color_variation := base_color.lightened(randf_range(-0.05, 0.1))
		unit_node.setup(i, side, color_variation)
		unit_node.unit_died.connect(_on_unit_died)
		units.append(unit_node)

	alive_count = UNIT_COUNT

func setup_with_types(side: String, composition: Array) -> void:
	## Setup army with specific unit types per slot.
	army_side = side
	_composition = composition
	_load_unit_types()
	var base_color: Color = PLAYER_COLOR if side == "player" else ENEMY_COLOR

	for i in UNIT_COUNT:
		var unit_node: Node2D = UNIT_SCENE.instantiate()
		add_child(unit_node)

		var offset: Vector2 = FORMATION[i]
		if side == "enemy":
			offset.x *= -1

		unit_node.position = offset
		var color_variation := base_color.lightened(randf_range(-0.05, 0.1))
		unit_node.setup(i, side, color_variation)

		# Apply unit type if available
		var type_id: String = composition[i] if i < composition.size() else "soldier"
		var type_data: Dictionary = _get_type_data(type_id)
		if not type_data.is_empty():
			unit_node.setup_type(type_data)

		unit_node.unit_died.connect(_on_unit_died)
		units.append(unit_node)

	alive_count = UNIT_COUNT

func _load_unit_types() -> void:
	if not _unit_types_data.is_empty():
		return
	var file := FileAccess.open("res://data/unit_types.json", FileAccess.READ)
	if file:
		var data: Dictionary = JSON.parse_string(file.get_as_text())
		file.close()
		_unit_types_data = data.get("unit_types", [])

func _get_type_data(type_id: String) -> Dictionary:
	_load_unit_types()
	for td in _unit_types_data:
		if td.get("id", "") == type_id:
			return td
	return {}

func get_unit_button_for_index(idx: int) -> String:
	if idx < units.size():
		return units[idx].assigned_button
	return "face_a"

func get_alive_units() -> Array:
	return units.filter(func(u): return u.is_alive)

func get_front_unit() -> Node2D:
	## Returns the first alive unit (front-line)
	for unit in units:
		if unit.is_alive:
			return unit
	return null

func get_random_alive_unit() -> Node2D:
	var alive := get_alive_units()
	if alive.is_empty():
		return null
	return alive[randi() % alive.size()]

func is_defeated() -> bool:
	return alive_count <= 0

func get_total_hp() -> int:
	var total := 0
	for unit in units:
		if unit.is_alive:
			total += unit.hp
	return total

func get_max_total_hp() -> int:
	return UNIT_COUNT * 100

func heal_all(amount: int) -> void:
	for unit in units:
		unit.heal(amount)

func apply_damage_boost_all(turns: int) -> void:
	for unit in units:
		if unit.is_alive:
			unit.apply_damage_boost(turns)

func apply_shield_all(turns: int) -> void:
	for unit in units:
		if unit.is_alive:
			unit.apply_shield(turns)

func tick_all_buffs() -> void:
	for unit in units:
		if unit.is_alive:
			unit.tick_buffs()

func get_units_for_formation(formation: String) -> Array:
	## Returns array of unit-group arrays based on formation type.
	var alive := get_alive_units()
	var groups: Array = []
	match formation:
		"solo":
			for unit in alive:
				groups.append([unit])
		"pair", "squad":
			var i := 0
			while i < alive.size() - 1:
				groups.append([alive[i], alive[i + 1]])
				i += 2
			if i < alive.size() and groups.size() > 0:
				groups[groups.size() - 1].append(alive[i])
			elif i < alive.size():
				groups.append([alive[i]])
		"legion":
			# Falls back to squad for now
			return get_units_for_formation("squad")
		_:
			for unit in alive:
				groups.append([unit])
	return groups

func reposition_unit(unit: Node2D, target_pos: Vector2, animate: bool = true) -> void:
	## Move a unit to a target local position, optionally with tween animation.
	if not is_instance_valid(unit):
		return
	if animate:
		var tween := unit.create_tween()
		tween.tween_property(unit, "position", target_pos, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	else:
		unit.position = target_pos

func _on_unit_died() -> void:
	alive_count -= 1
	if alive_count <= 0:
		Events.army_defeated.emit(army_side)
