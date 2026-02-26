# RhythmWar — AMARIS Master Manuscript

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

| Order | Autoload | Responsibility |
|-------|----------|---------------|
| 1 | Conductor | Beat clock + audio sync |
| 2 | Events | Global signal bus |
| 3 | GameManager | Session state, scene transitions |
| 4 | InputSetup | Programmatic InputMap registration |
| 5 | SaveManager | Binary save/load persistence |
| 6 | AchievementManager | Achievement tracking + unlock |
| 7 | SfxManager | Procedural SFX generation + playback pool |

## Key Directories

```
scripts/autoload/       — singleton scripts (load order above)
scripts/rhythm/         — Conductor, NoteSpawner, RhythmLane, judgments
scripts/battle/         — BattleStateMachine, EngagementManager, Unit
scripts/ui/             — menus, HUD, overlays (programmatic)
scripts/tests/          — test_suite.gd and individual test scripts
data/charts/            — JSON chart files (per-stage, per-difficulty)
data/abilities/         — abilities.json
data/commander_actions.json
data/unit_types.json
scenes/                 — .tscn scene files (minimal — UI is code-built)
tests/                  — headless runner (run-tests.bat, run_tests.gd)
```

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

# AMARIS Contract Files

Every AMARIS game must ship these JSON files at the repo root. The launcher reads them directly — no markdown parsing.

## game.config.json

```jsonc
{
  "id": "rythemWar",                     // folder name, lowercase OK
  "title": "RhythmWar",                  // display name
  "subtitle": "2D Rhythm Battler",       // tagline
  "engine": "Godot 4.6",                 // engine + version
  "genre": "Rhythm / Strategy",
  "description": "...",                   // 1–3 sentence pitch
  "status": "in-development",            // in-development | alpha | beta | release
  "version": "0.1.0",                    // semver
  "launch": {
    "type": "godot",                     // godot | unity | exe | web
    "main_scene": "scenes/Main.tscn"     // entry point for launcher
  },
  "features": [ "..." ],                 // feature bullet list
  "controls": {
    "keyboard_p1": "...",
    "keyboard_p2": "...",
    "controller": "..."
  },
  "lastArtUpdate": "2026-02-18",         // ISO8601 date (day precision OK)
  "asset_stage": "placeholder_v1"        // placeholder_v1 | wip | final
}
```

**Required keys:** `id`, `title`, `engine`, `status`, `version`, `launch`.
All other keys are recommended but optional. Launcher gracefully skips missing keys.

## project_status.json

```jsonc
{
  "schemaVersion": 1,
  "gameId": "rythemwar",
  "title": "RhythmWar",
  "lastUpdated": "2026-02-22T17:30:00Z",  // ISO8601 minute precision
  "health": {
    "progressPercent": 76,                 // 0–100 integer
    "buildVersion": "0.6.0",
    "assetStage": "wip"                    // placeholder | wip | final
  },
  "tech": {
    "engine": "Godot",
    "engineVersion": "4.6",
    "languages": ["GDScript"],
    "graphicsType": "2D"
  },
  "features": {
    "controllerSupport": "complete",       // missing | partial | complete
    "achievementsSystem": "complete",
    "testScripts": "partial",
    "saveSystem": "complete",
    "settingsMenu": "missing",
    "audio": "partial",
    "vfx": "partial"
  },
  "milestones": {
    "firstGraphicsPass": true,
    "controllerIntegration": true,
    "coreGameplayLoop": true,
    "verticalSlice": false,
    "contentComplete": false,
    "productionReady": false
  },
  "testing": {
    "testCommand": "tests/run-tests.bat",
    "lastRunAt": "2026-02-22T17:16:00Z",
    "status": "passed",                    // passed | failed | skipped
    "notes": "23/23 tests passing"
  },
  "links": {
    "repo": null,
    "launcherId": "rythemwar"
  }
}
```

**Required keys:** `schemaVersion`, `gameId`, `title`, `lastUpdated`, `health.progressPercent`, `testing.status`.
**Update rules:** Update `lastUpdated` on every meaningful commit. Update `health.progressPercent` when checklist items change. Update `testing` after every test run. Git hooks should automate timestamps.

## test_results.json

Output by the headless test runner (`tests/run_tests.gd`). Written to stdout as JSON.

```jsonc
{
  "gameId": "rythemWar",
  "status": "passed",           // "passed" if failures == 0, else "failed"
  "testsTotal": 23,
  "testsPassed": 23,
  "details": [                  // per-test breakdown
    {
      "name": "test_judgment_perfect",
      "passed": true,
      "message": ""
    }
  ]
}
```

The AMARIS dashboard reads `status`, `testsTotal`, and `testsPassed` for the test health indicator.

## achievements.json (if applicable)

```jsonc
{
  "achievements": [
    {
      "id": "first_perfect",
      "title": "Perfect Start",
      "description": "Land your first Perfect judgment",
      "icon": "res://assets/achievements/first_perfect.png",  // optional
      "hidden": false,
      "trigger": "judgment_perfect_count >= 1"                 // human-readable
    }
  ]
}
```

Achievement definitions live in data or are embedded in AchievementManager. The schema above is the recommended external format if the game externalizes definitions.

## data/ Folder Conventions

| Path | Purpose |
|------|---------|
| `data/charts/*.json` | Rhythm chart files — one per stage+difficulty |
| `data/abilities/abilities.json` | Ability definitions (name, cooldown, effect) |
| `data/commander_actions.json` | Commander action definitions |
| `data/unit_types.json` | Unit type stats (HP, damage, speed) |

All game data is JSON. No CSV, no YAML, no binary data files.

---

# AMARIS Master Checklist — 300 Checkpoints / 14 Macro Phases

This checklist is the canonical AMARIS development template. Other studio games copy this structure and adapt item descriptions to their genre. Mark items `[x]` when complete, `[ ]` when pending, `**N/A**` when not applicable.

---

## Macro Phase 1 — Foundation & Repo Standardization (1–16)

**Purpose:** Establish repo structure, boot the project cleanly, configure version control.
**Inputs:** Empty repo or early prototype.
**Outputs:** A project that boots, has standard folder layout, and meets AMARIS file contracts.
**Validation:** `godot --headless --script tests/run_tests.gd` exits cleanly; all contract JSON files parse without error.
**Gate:** Project boots in editor AND headless. All contract files present. Do not proceed to Phase 2 until this gate passes.

- [x] 1. Git repo initialized with .gitignore for Godot
- [x] 2. Folder structure matches AMARIS standard (scripts/, scenes/, data/, tests/)
- [x] 3. game.config.json present and valid against schema
- [x] 4. project_status.json present and valid against schema
- [x] 5. CLAUDE.md present with master checklist
- [x] 6. Project boots without errors in Godot editor
- [x] 7. Project boots without errors headless (CLI)
- [x] 8. Root scene tree configured (Main.tscn as entry)
- [x] 9. Export presets stub created
- [x] 10. Version identifier visible in-game (title screen or HUD)
- [x] 11. Build number or commit hash accessible at runtime
- [x] 12. Code style convention documented or enforced (.editorconfig or CLAUDE.md)
- [x] 13. All placeholder assets organized in known directories
- [x] 14. README or project card present for launcher description
- [x] 15. License file present or marked N/A
- [x] 16. CI-ready folder structure (tests/, data/, scenes/, scripts/ all present)

---

## Macro Phase 2 — Architecture & Autoloads (17–30)

**Purpose:** Wire core singletons, signal bus, and data pipeline. Establish the backbone every other system depends on.
**Inputs:** Booting project from Phase 1.
**Outputs:** All autoloads registered, signal bus functional, data loading patterns established.
**Validation:** Each autoload can be instantiated independently without crash. Signal bus emits and receives a test signal.
**Gate:** All 7 autoloads load in correct order. No circular dependencies. Signal bus test passes.

- [x] 17. Autoload load order defined and documented in CLAUDE.md
- [x] 18. Conductor autoload — beat clock and audio sync
- [x] 19. Events autoload — global signal bus
- [x] 20. GameManager autoload — session state and scene transitions
- [x] 21. InputSetup autoload — programmatic InputMap registration
- [x] 22. SaveManager autoload — persistence backbone
- [x] 23. AchievementManager autoload — achievement tracking and unlock
- [x] 24. SfxManager autoload — procedural SFX generation and playback pool
- [x] 25. No circular dependencies between autoloads
- [x] 26. Autoloads do not reference scene-tree nodes directly (use signals or deferred calls)
- [x] 27. Signal naming convention enforced (snake_case verb phrases)
- [x] 28. Data directory conventions established (data/, data/charts/, data/abilities/)
- [x] 29. Resource and config loading utility pattern established
- [x] 30. Autoload integration smoke test passes

---

## Macro Phase 3 — Input System (31–46)

**Purpose:** Map all inputs for keyboard and controller. Ensure input works everywhere and supports future rebinding.
**Inputs:** InputSetup autoload from Phase 2.
**Outputs:** Full input coverage for all screens. Controller and keyboard parity.
**Validation:** Every mapped action fires correctly on keyboard P1, keyboard P2, and Xbox controller. No input bleed between screens.
**Gate:** All face buttons, directionals, and modifier fire correctly on all input devices. Controller hot-plug works.

- [x] 31. Input actions defined programmatically in InputSetup autoload
- [x] 32. face_a / face_b / face_x / face_y actions mapped
- [x] 33. Directional inputs mapped (up / down / left / right)
- [x] 34. Modifier input mapped (shift / ctrl / RT)
- [x] 35. Keyboard Player 1 layout functional (A/S/D/F + W/X/Z/C + Shift)
- [x] 36. Keyboard Player 2 layout functional (I/J/K/L + Arrows + Ctrl)
- [x] 37. Xbox controller layout functional (A/B/X/Y + D-pad + RT)
- [x] 38. Analog stick deadzone handling configured
- [x] 39. Input works correctly in all menu screens
- [x] 40. Input works correctly in battle / gameplay
- [x] 41. Input does not bleed between screens (no ghost presses on transition)
- [x] 42. Controller hot-plug detection (connect mid-session)
- [x] 43. Controller disconnect handled gracefully (pause or prompt)
- [x] 44. Controller button prompts display correct glyphs
- [ ] 45. Input remap screen accessible from Settings menu
- [ ] 46. Remap persistence saved and loaded across sessions

---

## Macro Phase 4 — UI / Menus (47–74)

**Purpose:** Build all menu screens, HUD elements, and UI navigation. Controller-first, keyboard-supported.
**Inputs:** Input system from Phase 3, GameManager for scene transitions.
**Outputs:** Every screen navigable, HUD displaying all essential info, consistent UX patterns.
**Validation:** Navigate every screen with controller only. All buttons do what they say. HUD updates in real time during battle.
**Gate:** All menu screens reachable. HUD displays health, combo, score, round, cooldowns. No dead-end screens.

- [x] 47. Main Menu — layout and navigation
- [x] 48. Main Menu — all buttons functional (Play, Settings, Quit, etc.)
- [x] 49. Main Menu — fully controller-navigable
- [x] 50. Stage Select screen — layout and navigation
- [x] 51. Stage Select — difficulty indicators visible per stage
- [x] 52. Character / Commander Select screen
- [x] 53. Pause Menu — accessible mid-gameplay
- [x] 54. Pause Menu — resume / restart / quit options
- [x] 55. Pause Menu — does not break game state on resume
- [ ] 56. Settings Menu — layout and navigation
- [ ] 57. Settings Menu — audio volume controls (master / SFX / music)
- [ ] 58. Settings Menu — display or graphics options
- [ ] 59. Settings Menu — input remap access
- [ ] 60. Settings Menu — values persist on close
- [x] 61. Results Screen — win/lose state displayed clearly
- [x] 62. Results Screen — score summary with judgment breakdown
- [x] 63. Results Screen — navigation to rematch or return to menu
- [x] 64. HUD — health / HP bars for both armies
- [x] 65. HUD — combo counter
- [x] 66. HUD — score display
- [x] 67. HUD — round indicator
- [x] 68. HUD — ability cooldown indicators
- [x] 69. On-screen control hints — context-sensitive per screen
- [x] 70. Consistent Back / Cancel behavior across all screens
- [x] 71. Focus / selection highlight visible on all interactive elements
- [ ] 72. Tutorial overlay or first-run guidance flow
- [ ] 73. UX clarity pass — all screens reviewed for confusion points
- [ ] 74. Accessibility review — text size, contrast, colorblind considerations

---

## Macro Phase 5 — Core Gameplay Loop (75–98)

**Purpose:** Get the full rhythm-to-battle loop working end-to-end. Every mechanical system functional.
**Inputs:** Architecture, input, and UI from Phases 1–4.
**Outputs:** A complete play session from chart start to win/lose resolution.
**Validation:** Play a full battle on Easy, Medium, and Hard. Win and lose conditions trigger. Score calculates correctly. Pause/resume/restart all work.
**Gate:** Full loop playable with no crashes. All judgment tiers register. State machine cycles correctly.

- [x] 75. Rhythm engine processes beats accurately at target BPM
- [x] 76. Conductor.song_position synced to audio output
- [x] 77. AudioServer.get_time_since_last_mix() drift correction active
- [x] 78. Notes spawn from JSON chart data at correct times
- [x] 79. Note scroll speed tied to BPM and configurable
- [x] 80. Judgment window — Perfect ±40ms
- [x] 81. Judgment window — Great ±75ms
- [x] 82. Judgment window — Good ±110ms
- [x] 83. Judgment window — Bad ±150ms
- [x] 84. Judgment window — Miss (beyond threshold)
- [x] 85. Combo counter increments on consecutive hits
- [x] 86. Combo resets on miss
- [x] 87. Score calculation correct per judgment tier
- [x] 88. Multiplier system tied to combo length
- [x] 89. Battle state machine — TACTICIAN state functional
- [x] 90. Battle state machine — INTRO transition plays
- [x] 91. Battle state machine — PLAYER_TURN executes rhythm phase
- [x] 92. Battle state machine — ENEMY_TURN executes AI phase
- [x] 93. Battle state machine — CHECK_WIN evaluates round outcome
- [x] 94. Win condition triggers end-of-battle correctly
- [x] 95. Lose condition triggers end-of-battle correctly
- [x] 96. Difficulty scaling — note density and speed knobs functional
- [x] 97. Pause mid-chart does not desync audio or rhythm timing
- [x] 98. Restart / rematch clears all state cleanly (no stale data)

---

## Macro Phase 6 — Combat & Encounters (99–124)

**Purpose:** Flesh out the battle system — units, engagement clusters, damage, bosses, encounter variety.
**Inputs:** Working gameplay loop from Phase 5.
**Outputs:** Rich combat with multiple encounter types, multi-round battles, and boss stages.
**Validation:** Play 5+ different encounters. Engagement clusters form correctly. Boss stage has unique mechanics. Damage numbers feel fair.
**Gate:** Vertical slice of one full stage (3 difficulties) is playable. Engagement clustering stable under stress.

- [x] 99. Two armies of 6 units instantiated per battle
- [x] 100. Unit health system functional (damage, heal, clamp)
- [x] 101. Unit death and removal handled (removed from engagements)
- [x] 102. Micro-engagement clustering — 1v1 assignments
- [x] 103. Micro-engagement clustering — 2v2 assignments
- [x] 104. EngagementManager cluster assignment logic
- [x] 105. EngagementManager round-robin targeting
- [x] 106. Damage dealt scales with judgment accuracy
- [x] 107. Damage multipliers per judgment tier (Perfect > Great > Good > Bad)
- [x] 108. Critical hit / bonus damage on Perfect streaks
- [x] 109. Unit telegraph system — pre-attack indicators on units
- [x] 110. Note reveal mechanic — question mark until proximity threshold
- [x] 111. Multi-round battle — round transitions work
- [x] 112. Between-round stance selection functional
- [x] 113. Commander Actions — pre-battle buff/debuff selection
- [x] 114. Commander Actions — effects applied to engagement state
- [x] 115. First full stage vertical slice playable end-to-end
- [x] 116. 3+ chart difficulties playable per stage
- [ ] 117. Balance pass v1 — damage output numbers reviewed
- [ ] 118. Balance pass v1 — health pool values reviewed
- [ ] 119. Boss-stage encounter — unique mechanics defined
- [ ] 120. Boss-stage encounter — phase transitions implemented
- [ ] 121. Boss-stage encounter — special attack patterns
- [ ] 122. Environment hazards or battlefield modifiers
- [ ] 123. Encounter variety — different unit compositions per stage
- [ ] 124. Encounter pacing — tension curve validated across difficulties

---

## Macro Phase 7 — Skills, Spells & Abilities (125–146)

**Purpose:** Expand the ability system — cooldowns, commander actions, balance, unlock progression.
**Inputs:** Combat system from Phase 6.
**Outputs:** A rich ability layer with balanced cooldowns, multiple commanders, and visual/audio feedback.
**Validation:** All 4 abilities activate, apply effects, respect cooldowns. Commander Actions modify battle meaningfully. Balance pass numbers documented.
**Gate:** Every ability activatable and observable. No softlocks from ability state. Commander Actions feel impactful.

- [x] 125. Ability definitions loaded from JSON (data/abilities/)
- [x] 126. 4 special abilities defined with distinct effects
- [x] 127. Ability activation triggered by correct input sequence
- [x] 128. Cooldown tracking per ability (turns or time-based)
- [x] 129. Cooldown indicators visible on HUD
- [x] 130. Ability effects applied to battle state correctly
- [x] 131. Commander Actions data loaded from JSON
- [x] 132. Commander Actions — pre-battle selection UI
- [x] 133. Commander Actions — buff/debuff applied to units
- [x] 134. Commander Actions — visual feedback on application
- [x] 135. Ability cannot activate during cooldown (input rejected)
- [x] 136. Ability cancellation / interrupt rules defined and enforced
- [ ] 137. Ability combo chains — sequential ability use bonuses
- [ ] 138. Passive abilities or stance modifiers
- [ ] 139. Ability unlock progression tied to meta-progression
- [ ] 140. Ability balance pass — cooldown values reviewed
- [ ] 141. Ability balance pass — damage/effect magnitudes reviewed
- [ ] 142. Ability tooltip / description system for player reference
- [ ] 143. Commander Action balance pass — impact values reviewed
- [ ] 144. Unique ability sets per commander or character
- [ ] 145. Ability VFX feedback (placeholder acceptable)
- [ ] 146. Ability SFX feedback (placeholder acceptable)

---

## Macro Phase 8 — Enemy AI (147–164)

**Purpose:** CPU opponent behavior — targeting, difficulty scaling, personality, fairness.
**Inputs:** Combat and ability systems from Phases 6–7.
**Outputs:** AI that provides appropriate challenge, scales with difficulty, and feels fair.
**Validation:** AI plays correctly at all difficulty levels. No exploits. No information cheating. Stress test 100 rounds without error.
**Gate:** AI completes battles at 3 difficulty levels without crashing. Winrate within acceptable range per difficulty.

- [x] 147. AI takes actions during ENEMY_TURN phase
- [x] 148. AI selects targets from player army
- [x] 149. AI damage calculation functional
- [x] 150. AI counter-attack logic tuned
- [x] 151. AI respects engagement cluster assignments
- [x] 152. AI difficulty scaling exists (damage variance per difficulty)
- [ ] 153. AI pattern variety — multiple behavior profiles
- [ ] 154. AI adapts to player performance (rubber-banding or escalation)
- [ ] 155. AI uses abilities / special moves
- [ ] 156. AI commander action selection logic
- [ ] 157. AI telegraphs attacks clearly for player readability
- [ ] 158. AI difficulty presets defined (Easy / Medium / Hard)
- [ ] 159. AI does not exploit information player cannot see (no cheating)
- [ ] 160. AI turn timing feels natural (paced, not instant)
- [ ] 161. AI behavior documented for balance designers
- [ ] 162. AI stress test — 100 automated rounds without error
- [ ] 163. AI fairness pass — winrate per difficulty validated
- [ ] 164. AI personality per commander (optional flavor variation)

---

## Macro Phase 9 — Save/Load, Persistence & Meta Progression (165–184)

**Purpose:** Persist player progress — saves, achievements, unlocks, progression currency.
**Inputs:** All gameplay systems from Phases 5–8.
**Outputs:** Save system that round-trips correctly, achievement system that tracks and displays, progression that rewards play.
**Validation:** Save, quit, reload — all state preserved. Achievements trigger on correct events. Unlocks persist.
**Gate:** Save round-trip verified. Achievements fire and persist. No data loss on normal quit.

- [x] 165. Save system architecture defined (binary format)
- [x] 166. Binary save format implemented (SaveManager)
- [x] 167. Save to disk completes without error
- [x] 168. Load from disk completes without error
- [x] 169. Save file versioning or migration path defined
- [x] 170. New game creates fresh save state
- [x] 171. Achievement definitions loaded from data
- [x] 172. Achievement hooks fire on gameplay events
- [x] 173. Achievement unlock state persisted in save
- [x] 174. Achievement notification displayed on unlock
- [x] 175. Progression system — stage unlock tracking
- [x] 176. Progression system — high score per stage per difficulty
- [x] 177. Progression system — difficulty completion tracking
- [ ] 178. Meta currency or reward points system
- [ ] 179. Reward loop — earn currency from battles
- [ ] 180. Reward loop — spend currency on unlocks (cosmetic or gameplay)
- [ ] 181. Save integrity check and corruption recovery
- [ ] 182. Multiple save slot support
- [ ] 183. Cloud save stub or marked N/A
- [ ] 184. Save system stress test — rapid save/load cycles without corruption

---

## Macro Phase 10 — Graphics Pipeline: 3-Pass (185–220)

**Purpose:** Three visual passes from layout to detail to polish. Covers characters, environments, UI, animations, VFX, and micro-interactions.
**Inputs:** All gameplay and UI from Phases 4–9.
**Outputs:** Visually coherent game at target resolution. Animations convey game state. VFX enhances feedback.
**Validation:** Screenshot every screen — silhouettes readable, detail consistent, animations smooth. No placeholder art visible in final pass.
**Gate:** Pass 1 complete before Pass 2 begins. Pass 2 complete before Pass 3 begins. Each pass reviewed before proceeding.

### Pass 1 — Silhouette & Layout (185–196)

- [x] 185. Character silhouettes readable at 1280x720
- [x] 186. Unit types visually distinguishable from each other
- [x] 187. Army color coding — player vs enemy instantly clear
- [x] 188. Battlefield layout — units positioned in readable formation
- [x] 189. HUD elements do not obscure gameplay area
- [x] 190. Menu layouts use consistent spacing and alignment
- [x] 191. Rhythm lane / note visual hierarchy clear (notes pop from background)
- [x] 192. Judgment feedback — hit vs miss distinguishable at a glance
- [ ] 193. Environment backgrounds — establish setting and mood
- [ ] 194. UI iconography — consistent style language across all icons
- [ ] 195. Screen transitions — basic fade or cut (no jarring jump)
- [ ] 196. Camera framing — key action always visible, no off-screen surprises

### Pass 2 — Detail & Texture (197–208)

- [x] 197. Character sprites — detail pass (replace programmer art)
- [x] 198. Unit type sprites — detail and differentiation pass
- [ ] 199. Environment backgrounds — detail and atmosphere pass
- [ ] 200. Battlefield props and decoration elements
- [ ] 201. Menu backgrounds — detail pass
- [ ] 202. HUD frames, borders, and panel styling
- [ ] 203. Note skins — themed or stylized per stage
- [ ] 204. Judgment text — styled typography (not plain Label node)
- [ ] 205. Results screen — visual layout and hierarchy pass
- [ ] 206. Font selection — consistent family across all UI
- [ ] 207. Color palette documented and enforced across all screens
- [ ] 208. UI element hover / focus / pressed states fully styled

### Pass 3 — Animation, VFX & Micro-interactions (209–220)

- [ ] 209. Unit idle animations
- [ ] 210. Unit attack animations
- [ ] 211. Unit hit-react animations
- [ ] 212. Unit death animations
- [ ] 213. Ability activation VFX
- [ ] 214. Commander Action VFX
- [ ] 215. Note hit particles / judgment flare
- [ ] 216. Combo milestone VFX (10x, 25x, 50x visual escalation)
- [ ] 217. Screen shake on big hits or critical moments
- [ ] 218. HUD number pop / tween on score change
- [ ] 219. Menu transition animations (slide, fade, scale)
- [ ] 220. Results screen celebration (win) and defeat (lose) VFX

---

## Macro Phase 11 — Audio Pipeline: 3-Pass (221–254)

**Purpose:** Three audio passes — SFX foundation, music and ambience, mixing and accessibility. Covers the full SFX list, procedural vs sampled decisions, temp music contexts, mixing passes, and audio accessibility.
**Inputs:** All gameplay, VFX, and UI from Phases 4–10.
**Outputs:** Complete audio coverage for every interaction. Music system functional. Mix balanced. Accessibility considered.
**Validation:** Play full session with eyes closed — every action has audio feedback. Music enhances mood. No clipping. No silence gaps.
**Gate:** Pass 1 complete before Pass 2. All SFX present before music integration. Mix pass is final.

### Pass 1 — SFX Foundation (221–234)

Every interaction needs a sound. Procedural generation acceptable for Pass 1; sampled replacements in Pass 2/3.

- [x] 221. SfxManager autoload active and functional
- [x] 222. Procedural WAV generation system operational
- [x] 223. AudioStreamPlayer pool (8 players) — no starvation under load
- [x] 224. Menu navigation SFX (move between items)
- [x] 225. Menu confirm SFX (select / press A)
- [x] 226. Menu cancel / back SFX (press B / Escape)
- [x] 227. Judgment SFX — Perfect hit
- [x] 228. Judgment SFX — Great hit
- [x] 229. Judgment SFX — Good hit
- [x] 230. Judgment SFX — Miss
- [x] 231. Combo milestone SFX (threshold celebrations)
- [x] 232. Unit damage SFX
- [x] 233. Unit death SFX
- [x] 234. Ability activation SFX

### Pass 2 — Music & Ambience (235–244)

Temp music is acceptable. Define contexts and integration points even if final tracks are not ready.

- [ ] 235. Music system architecture defined (playback, crossfade, layering)
- [ ] 236. Battle music — tempo synced to Conductor BPM
- [ ] 237. Menu music / ambient loop
- [ ] 238. Results screen — victory fanfare
- [ ] 239. Results screen — defeat sting
- [ ] 240. Music crossfade between screen transitions
- [ ] 241. Dynamic music layers — react to gameplay state (intensity, danger)
- [ ] 242. Ambient SFX — battlefield atmosphere (wind, crowd, tension)
- [ ] 243. Ambient SFX — menu atmosphere (subtle hum or tone)
- [ ] 244. Music volume independent of SFX volume (separate bus)

### Pass 3 — Mixing, Polish & Accessibility (245–254)

- [ ] 245. Master mix pass — relative volumes balanced across all sounds
- [ ] 246. Spatial audio for unit positions (pan left/right, optional)
- [ ] 247. Audio ducking during important dialogue or events
- [ ] 248. Judgment SFX variation — pitch shift or alternates to avoid repetition fatigue
- [ ] 249. Menu SFX variation — subtle pitch shift per press
- [ ] 250. Visual cues paired with audio for deaf/HoH accessibility
- [ ] 251. Audio cue for off-screen or obscured events
- [ ] 252. Mute and unmute works correctly (no orphan sounds)
- [ ] 253. No audio clipping or distortion at any volume level
- [ ] 254. Audio latency within acceptable range (<20ms for rhythm gameplay)

---

## Macro Phase 12 — Testing & Headless Automation (255–274)

**Purpose:** Automated test coverage for all major systems. Headless runner outputs JSON for AMARIS dashboard.
**Inputs:** All systems from Phases 1–11.
**Outputs:** Comprehensive test suite. Headless runner. JSON contract output. CI-ready.
**Validation:** `tests/run-tests.bat` passes. test_results.json is valid. All critical paths have test coverage.
**Gate:** Zero test failures. test_results.json contract met. Launcher can parse test output.

- [x] 255. Test runner script exists (tests/run-tests.bat)
- [x] 256. Test runner executes headless without GUI dependency
- [x] 257. test_results.json output matches AMARIS contract schema
- [x] 258. Judgment window tests — all tiers (Perfect through Miss)
- [x] 259. Combo logic tests — increment on hit, reset on miss
- [x] 260. Score calculation tests — correct values per tier
- [x] 261. Damage multiplier tests — accuracy-to-damage mapping
- [x] 262. Chart validation tests — malformed JSON detected and rejected
- [x] 263. Test results reported to AMARIS dashboard (launcher reads output)
- [ ] 264. Battle state machine transition tests — all state transitions
- [ ] 265. Engagement clustering edge-case tests (odd numbers, deaths mid-cluster)
- [ ] 266. Save / load round-trip tests — save, reload, compare state
- [ ] 267. Achievement trigger tests — events fire correct achievements
- [ ] 268. Ability cooldown tests — activate, wait, reactivate
- [ ] 269. AI behavior tests — AI completes turns without error
- [ ] 270. Input mapping validation tests — all actions fire correctly
- [ ] 271. Regression tests for known fixed bugs
- [ ] 272. Test coverage report generation
- [ ] 273. CI integration — tests run automatically on push
- [ ] 274. Flaky test detection and quarantine process

---

## Macro Phase 13 — Debug Tooling & Dev Commands (275–284)

**Purpose:** Developer-only tools for testing, tuning, and diagnostics. Stripped from release builds.
**Inputs:** All systems.
**Outputs:** Debug overlay, cheat commands, visualizers for internal state.
**Validation:** Each command works without side effects. All tools disabled in release.
**Gate:** Debug overlay toggleable. At least 5 dev commands functional. Release build confirms tools are stripped.

- [ ] 275. Debug overlay toggle — FPS, battle state, Conductor position
- [ ] 276. God mode — player units invincible
- [ ] 277. Skip-to-round command — jump to specific round
- [ ] 278. Force win / force lose command
- [ ] 279. BPM override for rhythm testing at arbitrary tempos
- [ ] 280. Judgment window visualizer — overlay showing window boundaries
- [ ] 281. Engagement cluster visualizer — show cluster assignments on screen
- [ ] 282. Damage log / combat log output to console or file
- [ ] 283. Asset hot-reload support (if engine permits)
- [ ] 284. All dev tools confirmed disabled in release / export builds

---

## Macro Phase 14 — Optimization, Packaging & Release (285–300)

**Purpose:** Performance profiling, export configuration, final smoke test, and release candidate approval.
**Inputs:** Feature-complete build from Phases 1–13.
**Outputs:** Optimized, packaged, release-ready build.
**Validation:** Stable 60fps at 1280x720. No memory leaks. Release build runs full loop. Credits present.
**Gate:** Release candidate tagged. Full smoke test passed in release build. File size within budget.

- [ ] 285. Performance baseline profiled — stable 60fps at 1280x720
- [ ] 286. Memory usage profiled — no leaks in core gameplay loop
- [ ] 287. GC pressure minimized in hot paths (no per-frame allocations)
- [ ] 288. Draw call budget established and met
- [ ] 289. Shader compilation stutter-free (GL Compatibility pre-warm)
- [ ] 290. Load time profiled — scene transitions under target threshold
- [ ] 291. Export template configured for target platform(s)
- [ ] 292. Release build compiles without errors or warnings
- [ ] 293. Release build runs full gameplay loop without errors
- [ ] 294. Release build file size within budget
- [ ] 295. All debug / dev tools stripped from release build
- [ ] 296. Credits screen present and accurate
- [ ] 297. Controller prompts correct in release build (no debug labels)
- [ ] 298. Save compatibility verified between dev and release builds
- [ ] 299. Final smoke test — full play session in release build
- [ ] 300. Release candidate approved and tagged in git

---

# Known Gaps / Current State

- No external music system (SFX only — procedural generation)
- No visual animation system beyond basic state changes
- Balance tuning ongoing — no formal balance pass completed
- Engagement clustering needs deeper stress testing with edge cases
- Save persistence not stress-tested (rapid save/load cycles)
- No performance profiling pass completed
- Settings menu not implemented
- Debug tooling not implemented
- Boss encounters not implemented

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
