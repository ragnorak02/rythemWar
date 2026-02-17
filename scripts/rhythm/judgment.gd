class_name Judgment
extends RefCounted
## Judgment — static timing window evaluator for rhythm hits.
## Grades: PERFECT (+-40ms), GREAT (+-75ms), GOOD (+-110ms), BAD (+-150ms), MISS (beyond).

# Timing windows in seconds
const PERFECT_WINDOW := 0.040
const GREAT_WINDOW := 0.075
const GOOD_WINDOW := 0.110
const BAD_WINDOW := 0.150

# Grade names
const GRADE_PERFECT := "PERFECT"
const GRADE_GREAT := "GREAT"
const GRADE_GOOD := "GOOD"
const GRADE_BAD := "BAD"
const GRADE_MISS := "MISS"

# Score values per grade
const SCORE_VALUES := {
	GRADE_PERFECT: 300,
	GRADE_GREAT: 200,
	GRADE_GOOD: 100,
	GRADE_BAD: 50,
	GRADE_MISS: 0,
}

# Combo continues on these grades (miss and bad break combo)
const COMBO_GRADES := [GRADE_PERFECT, GRADE_GREAT, GRADE_GOOD]

# Colors for each grade
static func get_grade_color(grade: String) -> Color:
	match grade:
		GRADE_PERFECT: return Color(1.0, 0.84, 0.0)      # Gold
		GRADE_GREAT:   return Color(0.0, 1.0, 0.4)       # Green
		GRADE_GOOD:    return Color(0.3, 0.7, 1.0)       # Blue
		GRADE_BAD:     return Color(0.8, 0.4, 0.1)       # Orange
		GRADE_MISS:    return Color(1.0, 0.2, 0.2)       # Red
		_:             return Color.WHITE

## Evaluate timing difference and return grade string.
## diff_sec: absolute difference in seconds between input time and note target time
static func evaluate(song_position: float, note_time: float) -> String:
	var diff: float = absf(song_position - note_time)
	if diff <= PERFECT_WINDOW:
		return GRADE_PERFECT
	elif diff <= GREAT_WINDOW:
		return GRADE_GREAT
	elif diff <= GOOD_WINDOW:
		return GRADE_GOOD
	elif diff <= BAD_WINDOW:
		return GRADE_BAD
	else:
		return GRADE_MISS

## Returns true if the grade keeps the combo alive
static func keeps_combo(grade: String) -> bool:
	return grade in COMBO_GRADES

## Returns damage multiplier for battle system
static func get_damage_multiplier(grade: String) -> float:
	match grade:
		GRADE_PERFECT: return 1.5
		GRADE_GREAT:   return 1.2
		GRADE_GOOD:    return 1.0
		GRADE_BAD:     return 0.5
		_:             return 0.0
