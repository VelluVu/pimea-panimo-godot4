class_name HalloweenRules
extends RefCounted

## When the Halloween decorations are up, by the player's own clock: from late October
## until the year turns. Christmas has no season of its own yet, so Halloween stays up
## through December; when it gets one, end this season where that one begins.

const FIRST_DAY_OCTOBER : int = 20


## `date` as Time.get_date_dict_from_system() gives it.
static func is_season(date : Dictionary) -> bool:
	var month : int = date.get("month", 0)
	var day : int = date.get("day", 0)
	if month == Time.MONTH_OCTOBER:
		return day >= FIRST_DAY_OCTOBER
	return month == Time.MONTH_NOVEMBER or month == Time.MONTH_DECEMBER
