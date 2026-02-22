extends Node
## Events — global signal bus for cross-system communication.
## All signals are defined here; systems connect/emit through this singleton.

# --- Rhythm ---
signal judgment_made(player_id: int, grade: String, combo: int, note_type: String)
signal note_hit(player_id: int, note_type: String, grade: String)
signal note_missed(player_id: int, note_type: String)
signal combo_broken(player_id: int, final_combo: int)
signal song_finished()

# --- Battle ---
signal battle_started(stage_id: String)
signal battle_ended(winner: String)  # "player" / "enemy"
signal round_completed(round_number: int, player_hp: int, enemy_hp: int)
signal round_started(round_number: int)
signal turn_started(turn_number: int, is_player_turn: bool)
signal turn_ended(turn_number: int)
signal unit_attacked(attacker_army: String, attacker_index: int, target_index: int)
signal unit_damaged(army: String, unit_index: int, damage: int, new_hp: int)
signal unit_died(army: String, unit_index: int)
signal army_defeated(army: String)

# --- Abilities ---
signal ability_activated(player_id: int, ability_id: String)
signal ability_cooldown_updated(player_id: int, ability_id: String, turns_left: int)

# --- UI / Navigation ---
signal scene_change_requested(scene_path: String)
signal menu_selection_changed(index: int)
signal menu_confirmed(index: int)

# --- Achievements ---
signal achievement_unlocked(achievement_id: String, title: String)
signal achievement_progress(achievement_id: String, current: int, target: int)

# --- Tactician Mode ---
signal tactician_confirmed(player_id: int, config: Dictionary)
signal tactician_fled(player_id: int)
signal commander_action_used(player_id: int, action_id: String)

# --- Engagements ---
signal engagement_activated(index: int, player_units: Array, enemy_units: Array)
signal engagement_resolved(index: int)

# --- Telegraph ---
signal telegraph_show(unit: Node2D, button_name: String, time_until: float)
signal telegraph_hide(unit: Node2D)
signal telegraph_feedback(unit: Node2D, grade: String)

# --- Game State ---
signal game_paused()
signal game_resumed()
signal settings_changed(key: String, value: Variant)
