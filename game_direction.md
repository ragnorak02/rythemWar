# RhythmWar — Game Direction

## Vision
A 2D rhythm battler that merges the precision of rhythm games with the tactical depth of army combat. Players command their armies by hitting rhythm notes — perfect timing means devastating attacks, while misses leave them vulnerable to counter-attacks.

## Core Loop
1. Notes scroll right-to-left along the rhythm lane
2. Player presses the matching button (A/B/X/Y) when notes reach the judgment line
3. Hit quality (Perfect/Great/Good/Bad/Miss) determines attack damage
4. Armies clash visually — units lunge to attack, take damage, die
5. Combos multiply damage; misses give the enemy free attacks
6. Song ends → enemy turn → check for army defeat → Results screen

## Differentiators
- **Modifier system**: Hold RT + button for Super Strikes (1.8x damage)
- **Direction combos**: Direction + button for Directed Attacks (target any enemy unit)
- **Special abilities**: Team Heal, Tiger Fury, Iron Skin, Auto-Block with cooldowns
- **2-player local**: Split-screen rhythm lanes, both players hit notes independently
- **Army depth**: 6 units per side with individual HP, damage, defense, buffs

## Difficulty Curve
- **Easy (100 BPM)**: 20 notes, simple A/B patterns, comfortable spacing
- **Medium (130 BPM)**: 30 notes, all 4 buttons, tighter timing
- **Hard (165 BPM)**: 40 notes, rapid-fire patterns, requires modifier mastery

## Future Ideas
- More stages with real music tracks
- Boss battles with unique patterns
- Unit customization / upgrades between battles
- Online multiplayer
- Campaign mode with progression
- Rhythm editor for custom charts
- Expanded formation effects (legion unique behavior)
- More commander actions with deeper strategic variety

## Phases
- [x] Phase 1: Core rhythm prototype (arrows, judgment, combo)
- [x] Phase 2: Battle layer (armies, damage, win condition)
- [x] Phase 3: Input depth (combos, modifiers, result types)
- [x] Phase 4: Special abilities (heal, shield, boost, auto-block)
- [x] Phase 5: Game modes & UI flow (menus, stage select)
- [x] Phase 6: 2P split-screen & results
- [x] Phase 7: Achievements
- [x] Phase 8: Save system & tests
- [x] Phase 9: Tactician Mode + Micro-Engagement Battlefield + Telegraph

### Graphics Pass V1 — 2026-02-18
- Replaced 17 primitive/placeholder visuals with improved assets
- Units: custom _draw() soldier silhouettes with head, torso, legs, weapon, pauldrons, shadow
- Note arrows: diamond shapes with glow, border outlines, defend shield indicator
- Added animation cycles for: unit idle bob, attack lunge, hit flash, death fade, shield/boost overlays
- Judgment line: shader glow with pulsing
- Rhythm lane: shader with scrolling beat markers and edge glow
- Battle background: shader with starfield, ground plane, horizon glow
- Menu backgrounds: shader with vignette, stars, floating dust particles
- Stage cards: styled with border glow, accent regions, separators
- Army crests: custom _draw() faction emblems (shield, sword, leaf, crown, dagger)
- HUD HP bars: beveled frames with highlight stripe
- Results panels: bordered frames with accent bars, grade legend
- Achievement popup: styled with icon slot, border frame
- 2P separator: shader glow line with shimmer
- Judgment feedback: CPUParticles2D burst on Perfect (gold) and Great (green)
- Techniques used: Shader, Programmatic (_draw), Particle (CPUParticles2D)
- Asset stage: placeholder_v1 (swap-ready for final art)

### Tactician Mode + Micro-Engagement Battlefield — 2026-02-18
- Added pre-battle Tactician Mode panel with formation, aggression, commander actions, view/edit army, flee
- Implemented micro-engagement battlefield: units scatter into solo/pair/squad clusters
- Round-robin engagement cycling: each note targets a different cluster in rotation
- On-unit telegraph system: button icons appear above active units with glow intensity
- Note "?" reveal mechanic: distant notes show "?" until within 300px of judgment line
- 5 commander actions: +Speed, +Power, +Defense, Sleep Frontline, Reinforcement
- Aggression mode: +20% damage / -15% defense tradeoff
- Flee mechanic: 40% RNG chance, penalty on failure
- 2P split support: independent tactician panels, both must confirm
- Battle state machine expanded: TACTICIAN → INTRO → PLAYER_TURN → ENEMY_TURN → CHECK_WIN
- New files: tactician_mode, view_army_modal, edit_army_panel, commander_actions_panel, engagement_manager, unit_telegraph, commander_actions.json
- Modified: events.gd (+8 signals), battle.gd (two-phase ready), battle_state_machine.gd (engagement targeting), army.gd (formation grouping), unit.gd (telegraph + engagement_index), note_arrow.gd (? reveal)
