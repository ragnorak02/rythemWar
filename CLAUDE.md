# RhythmWar — 2D Rhythm Battler

## Overview
A 2D side-view rhythm battler where two armies clash and the player inputs rhythm commands to attack/defend. Built in Godot 4.6 (GL Compatibility, 1280x720).

## Architecture

### Autoloads (load order matters)
| # | Name | File | Purpose |
|---|------|------|---------|
| 1 | Conductor | `scripts/autoload/conductor.gd` | Beat clock + audio sync (system clock approach) |
| 2 | Events | `scripts/autoload/events.gd` | Signal bus — all cross-system signals |
| 3 | GameManager | `scripts/autoload/game_manager.gd` | Global session state, scene changes |
| 4 | InputSetup | `scripts/autoload/input_setup.gd` | Programmatic InputMap (p1_/p2_ prefixes) |
| 5 | SaveManager | `scripts/autoload/save_manager.gd` | Binary save at user://rhythmwar_save.dat |
| 6 | AchievementManager | `scripts/autoload/achievement_manager.gd` | Achievement tracking, JSON-driven |

### Key Directories
```
scripts/autoload/    — 6 singleton autoloads
scripts/rhythm/      — note_arrow, note_spawner, rhythm_lane, judgment
scripts/battle/      — unit, army, battle, battle_state_machine, ability_system
scripts/ui/          — main_menu, stage_select, character_select, hud, results_screen, achievement_popup
scripts/tests/       — test_suite
scenes/              — .tscn files (minimal — all UI is programmatic)
data/charts/         — stage JSON files (easy_01, medium_01, hard_01)
data/abilities/      — abilities.json
```

### Rhythm System
- **Conductor** uses `AudioServer.get_time_since_last_mix()` for drift-proof timing
- **Notes** position from `Conductor.song_position` each frame (not velocity*delta)
- **Input** via `_input()` event handler (lowest latency for rhythm games)
- **Judgment windows**: Perfect ±40ms, Great ±75ms, Good ±110ms, Bad ±150ms, Miss beyond
- **Charts** are JSON with `{ time, button, type }` note arrays

### Battle System
- 2 armies of 6 units each in stagger formation
- Rhythm hits resolve as attacks; misses let enemy counter-attack
- Direction combos + RT modifier for Super Strike / Super Counter / Block / Directed Attack
- 4 special abilities (Team Heal, Iron Skin, Tiger Fury, Auto-Block) with cooldown tracking
- State machine: INTRO → PLAYER_TURN → ENEMY_TURN → CHECK_WIN → loop

### Input Mapping
| Action | P1 Keyboard | P2 Keyboard | Controller |
|--------|-------------|-------------|------------|
| face_a | D | K | A |
| face_b | F | L | B |
| face_x | S | J | X |
| face_y | A | I | Y |
| directions | W/X/Z/C | Arrow keys | D-pad |
| modifier | Shift | Ctrl | RT |

### Scene Flow
`MainMenu → StageSelect → CharacterSelect → Battle → Results → MainMenu`

### Signal Flow (Core Loop)
```
Player presses D → rhythm_lane._input() → _on_button_pressed("face_a")
  → NoteSpawner.get_hittable_note() → Judgment.evaluate() → Grade
  → Events.judgment_made → battle_state_machine resolves attack
    → unit.take_damage() → Events.unit_damaged/died
    → achievement_manager tracks → Events.achievement_unlocked
    → hud updates score/combo
```

## Conventions
- All UI built programmatically in code (no .tscn UI layouts)
- IIFE-like pattern: autoload singletons, signal-based communication
- State machines: `enum + match` pattern
- Chart data: JSON, not hardcoded
- Tests: `tests/run-tests.bat` → JSON stdout (launcher contract)

## Testing
```
cd Z:/Development/amatris/rythemWar
tests/run-tests.bat
```
Tests cover: judgment windows, combo logic, score values, damage multipliers, chart validation.
