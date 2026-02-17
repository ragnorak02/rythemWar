extends Node
## AbilitySystem — loads abilities from JSON, tracks cooldowns, dispatches effects.

var _abilities: Array = []
var _cooldowns: Dictionary = {}  # ability_id -> turns remaining (0 = ready)
var _player_army: Node2D = null
var _enemy_army: Node2D = null

func _ready() -> void:
	_load_abilities()

func setup(player_army: Node2D, enemy_army: Node2D) -> void:
	_player_army = player_army
	_enemy_army = enemy_army
	# Initialize all cooldowns to ready
	for ability in _abilities:
		_cooldowns[ability["id"]] = 0

func _load_abilities() -> void:
	var file := FileAccess.open("res://data/abilities/abilities.json", FileAccess.READ)
	if file:
		var data: Dictionary = JSON.parse_string(file.get_as_text())
		file.close()
		if data.has("abilities"):
			_abilities = data["abilities"]

func get_abilities() -> Array:
	return _abilities

func get_cooldown(ability_id: String) -> int:
	return _cooldowns.get(ability_id, 0)

func is_ready(ability_id: String) -> bool:
	return _cooldowns.get(ability_id, 0) <= 0

func activate(player_id: int, ability_id: String) -> bool:
	if not is_ready(ability_id):
		return false

	var ability: Dictionary = _get_ability(ability_id)
	if ability.is_empty():
		return false

	# Set cooldown
	_cooldowns[ability_id] = ability["cooldown_turns"]

	# Dispatch effect
	var army := _player_army if player_id == 1 else _enemy_army
	match ability["effect"]:
		"heal_all":
			_effect_heal_all(army, ability["value"])
		"damage_shield":
			_effect_damage_shield(army, ability["value"])
		"damage_boost":
			_effect_damage_boost(army, ability["value"])
		"auto_defend":
			_effect_auto_defend(army, ability["value"])

	Events.ability_activated.emit(player_id, ability_id)
	return true

func tick_cooldowns() -> void:
	for ability_id in _cooldowns:
		if _cooldowns[ability_id] > 0:
			_cooldowns[ability_id] -= 1
			Events.ability_cooldown_updated.emit(1, ability_id, _cooldowns[ability_id])

func _get_ability(ability_id: String) -> Dictionary:
	for ability in _abilities:
		if ability["id"] == ability_id:
			return ability
	return {}

func _effect_heal_all(army: Node2D, value: int) -> void:
	army.heal_all(value)

func _effect_damage_shield(army: Node2D, turns: int) -> void:
	army.apply_shield_all(turns)

func _effect_damage_boost(army: Node2D, turns: int) -> void:
	army.apply_damage_boost_all(turns)

func _effect_auto_defend(army: Node2D, turns: int) -> void:
	army.apply_shield_all(turns)
