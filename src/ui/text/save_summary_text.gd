class_name SaveSummaryText
extends RefCounted

## The main menu's line under "Jatka peliä": where the saved run stands.

const DAY_FORMAT : String = "Päivä %d"
const SEPARATOR : String = " · "


static func line(day : int, money : float) -> String:
	return UiText.of(DAY_FORMAT) % day + SEPARATOR + NumberText.money(money)
