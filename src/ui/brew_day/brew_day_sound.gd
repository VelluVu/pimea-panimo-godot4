class_name BrewDaySound
extends RefCounted

## The brew day's one-shot sounds, played by the audio wiring through
## GUISignals.brew_day_sound.

const MALTS : StringName = &"malts"
const PLOP : StringName = &"plop"
const CLUMP_HIT : StringName = &"clump_hit"
const CLUMP_BOUNCE : StringName = &"clump_bounce"
const CLUMP_BREAK : StringName = &"clump_break"
const PADDLE_KNOCK : StringName = &"paddle_knock"
const STEP_DONE : StringName = &"step_done"
const BOIL_OVER : StringName = &"boil_over"
const MARK_HIT : StringName = &"mark_hit"
const MARK_MISS : StringName = &"mark_miss"
const RESULT_GOOD : StringName = &"result_good"
const RESULT_LOW : StringName = &"result_low"


static func play(sound : StringName) -> void:
	GUISignals.brew_day_sound.emit(sound)
