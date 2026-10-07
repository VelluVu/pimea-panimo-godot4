class_name DayClockText
extends RefCounted

## The tooltip of the top bar's day label and clock. A day is a real-time timer with no
## hours of its own, so it is shown as the cellar's opening hours.

const OPEN_HOUR : int = 18
const OPEN_HOURS : int = 8
## The shown time moves in steps like a wall clock, not every in-game minute.
const MINUTE_STEP : int = 5

const DAY_FORMAT : String = "Päivä %d/%d"
const CONTINUED_DAY_FORMAT : String = "Päivä %d, kausi on jo pelattu"
const TIME_FORMAT : String = "Kello %s, valot sammuvat klo %s"
const TIME_LEFT_FORMAT : String = "Päivää jäljellä %d min %02d s"
const CLOCK_STOPPED_TEXT : String = "Kello lähtee käyntiin, kun ensimmäinen olut on pantu."


## `progress` 0..1 through the day -> "21.30", Finnish style.
static func clock_time(progress : float) -> String:
	var minutes : int = floori(clampf(progress, 0.0, 1.0) * OPEN_HOURS * 60.0 / MINUTE_STEP) * MINUTE_STEP
	return _hh_mm(OPEN_HOUR * 60 + minutes)


static func closing_time() -> String:
	return _hh_mm((OPEN_HOUR + OPEN_HOURS) * 60)


## `seconds_left` is negative while the clock has not started.
static func tooltip(day : int, target_day : int, progress : float, seconds_left : float) -> String:
	var lines : PackedStringArray = []
	if day <= target_day:
		lines.append(UiText.of(DAY_FORMAT) % [day, target_day])
	else:
		lines.append(UiText.of(CONTINUED_DAY_FORMAT) % day)
	if seconds_left < 0.0:
		lines.append(UiText.of(CLOCK_STOPPED_TEXT))
		return "\n".join(lines)
	lines.append(UiText.of(TIME_FORMAT) % [clock_time(progress), closing_time()])
	var whole_seconds : int = ceili(seconds_left)
	lines.append(UiText.of(TIME_LEFT_FORMAT) % [floori(whole_seconds / 60.0), whole_seconds % 60])
	return "\n".join(lines)


static func _hh_mm(total_minutes : int) -> String:
	return "%02d.%02d" % [floori(total_minutes / 60.0) % 24, total_minutes % 60]
