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

## Phases
- [x] Phase 1: Core rhythm prototype (arrows, judgment, combo)
- [x] Phase 2: Battle layer (armies, damage, win condition)
- [x] Phase 3: Input depth (combos, modifiers, result types)
- [x] Phase 4: Special abilities (heal, shield, boost, auto-block)
- [x] Phase 5: Game modes & UI flow (menus, stage select)
- [x] Phase 6: 2P split-screen & results
- [x] Phase 7: Achievements
- [x] Phase 8: Save system & tests
