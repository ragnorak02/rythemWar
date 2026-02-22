# RhythmWar — Amaris Development Spec

Engine: Godot 4.6  
Renderer: GL Compatibility  
Resolution: 1280x720  
Genre: 2D Rhythm Battler  
Studio: Amaris  
Controller Required: Yes  

---

# Amaris Studio Rules

- `project_status.json` is the single source of truth for dashboard metrics.
- This file defines architecture, systems, and structured development checkpoints.
- Do NOT duplicate completion percentages here.
- Controller-first design is mandatory.
- All major systems must be testable.
- Maintain structural consistency with other Amaris games.

If a checklist item does not apply, mark it **N/A** rather than deleting it.

---

# Project Overview

RhythmWar is a 2D side-view rhythm battler where two armies clash and the player inputs rhythm commands to attack and defend.

Core Loop:

MainMenu → StageSelect → CharacterSelect → Battle  
Battle (Tactician Mode → Engagement Phase)  
→ Results → MainMenu  

Combat resolves based on rhythm accuracy and engagement clustering.

---

# Architecture

## Autoloads (Load Order Matters)

1. Conductor — Beat clock + audio sync  
2. Events — Signal bus  
3. GameManager — Global session state  
4. InputSetup — Programmatic InputMap  
5. SaveManager — Binary save  
6. AchievementManager — Achievement tracking  
7. SfxManager — Procedural SFX generation  

---

## Key Directories

scripts/autoload/  
scripts/rhythm/  
scripts/battle/  
scripts/ui/  
scripts/tests/  
data/charts/  
data/abilities/  
data/commander_actions.json  
scenes/  

All UI is built programmatically (minimal .tscn layouts).

---

# Core Systems

## Rhythm System

- Conductor uses `AudioServer.get_time_since_last_mix()` for drift-proof timing
- Notes position from `Conductor.song_position`
- `_input()` handler used for lowest latency
- Judgment windows:
  - Perfect ±40ms
  - Great ±75ms
  - Good ±110ms
  - Bad ±150ms
  - Miss beyond
- Charts are JSON-based

## Battle System

- 2 armies of 6 units
- Micro-engagement clusters (1v1, 2v2)
- EngagementManager handles cluster logic + round-robin targeting
- Commander Actions modify pre-battle state
- 4 special abilities with cooldown tracking
- State machine:
  TACTICIAN → INTRO → PLAYER_TURN → ENEMY_TURN → CHECK_WIN → loop
- On-unit telegraph system
- Note reveal mechanic (question mark until proximity)

## Input Mapping

face_a → D / K / Controller A  
face_b → F / L / Controller B  
face_x → S / J / Controller X  
face_y → A / I / Controller Y  
Directions → W/X/Z/C / Arrow Keys / D-pad  
Modifier → Shift / Ctrl / RT  

---

# Signal Flow (Core Loop)

Input → RhythmLane → NoteSpawner → Judgment  
→ Events.judgment_made → battle_state_machine  
→ engagement_manager targeting  
→ unit.take_damage  
→ Events.unit_damaged/died  
→ achievement_manager  
→ HUD updates  

---

# SFX System

- Procedural WAV generation
- 8 AudioStreamPlayer pool
- 13 placeholder sound types
- Fully integrated into UI + battle systems

---

# Testing

Run from project root:

tests/run-tests.bat

Covers:
- Judgment windows
- Combo logic
- Score values
- Damage multipliers
- Chart validation

Outputs JSON for launcher contract.

---

# Known Gaps / Current State

- No external music system (SFX only procedural)
- No visual animation system beyond basic state changes
- Balance tuning ongoing
- Engagement clustering needs deeper stress testing
- Save persistence not fully validated
- No performance profiling pass completed

---

# Structured Development Checklist (Amaris Standard — 54 Checkpoints)

## Macro Phase 1 — Foundation (1–8)

- [x] 1. Repo standardized
- [x] 2. Boots without errors
- [x] 3. Input map created
- [x] 4. Controller navigation baseline
- [x] 5. Base scene flow wired
- [x] 6. Logging/error handling pattern
- [x] 7. Config/data loading pattern
- [x] 8. Version/build identifier visible

## Macro Phase 2 — Menus & UX (9–16)

- [x] 9. Main Menu complete
- [ ] 10. Pause Menu complete
- [ ] 11. Settings Menu complete
- [x] 12. Save/Load decision + stub
- [x] 13. Status/Info screen baseline
- [x] 14. On-screen control hints
- [x] 15. UI navigation polish
- [x] 16. Consistent Back behavior

## Macro Phase 3 — Core Gameplay Loop (17–26)

- [x] 17. Rhythm engine stable under stress
- [x] 18. Core battle loop start → win/lose works
- [x] 19. Fail condition validated
- [x] 20. Success condition validated
- [x] 21. HUD v0 essentials
- [x] 22. Feedback baseline (hit/miss clarity)
- [ ] 23. Pause/resume stable mid-chart
- [x] 24. Difficulty knobs exist
- [ ] 25. Tutorial / first-run guidance
- [x] 26. Restart / rematch flow works

## Macro Phase 4 — Systems Expansion (27–36)

- [x] 27. Engagement clustering stable
- [x] 28. AI damage/counter logic tuned
- [x] 29. Commander Actions balanced
- [x] 30. Special abilities tuned
- [x] 31. Progression / unlock system baseline
- [x] 32. Achievement hooks integrated
- [x] 33. Save persistence validated
- [x] 34. Chart content pipeline defined
- [ ] 35. Debug/dev tooling commands
- [ ] 36. Input remap support (optional)

## Macro Phase 5 — Vertical Slice & Content (37–42)

- [x] 37. First full stage vertical slice complete
- [x] 38. 3+ chart difficulties playable
- [ ] 39. Balance pass v1
- [ ] 40. Boss-stage engagement implemented
- [ ] 41. Reward loop tuned
- [ ] 42. UX clarity pass

## Macro Phase 6 — Testing & Stability (43–46)

- [x] 43. Test runner headless stable
- [x] 44. test_results.json contract implemented
- [x] 45. Smoke tests cover rhythm + battle loop
- [ ] 46. Performance baseline verified

## Macro Phase 7 — Visual + Audio + Release (47–54)

- [x] 47. Visual polish pass
- [x] 48. Placeholder visuals replaced
- [ ] 49. Combat animation/juice pass
- [ ] 50. Music integration system added
- [x] 51. Audio polish pass
- [x] 52. Controller prompts finalized
- [ ] 53. Credits screen
- [ ] 54. Release build verified

---

# Current Focus

Current Goal:  
Current Task:  
Work Mode:  
Next Milestone:  

---

# Automation Reminder

After major updates:

- Update `project_status.json`
  - macroPhase
  - subphaseIndex
  - completionPercent
  - timestamps
  - testStatus
- Commit changes
- Ensure tests are run before push