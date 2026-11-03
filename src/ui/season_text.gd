class_name SeasonText
extends RefCounted

## The season's texts: the top bar chip's tooltip and the toast when a run meets a new
## season.

const DAYS_LEFT_FORMAT : String = "Vielä %d päivää."
const LAST_DAY_TEXT : String = "Viimeinen päivä."
## Short: the chip's tooltip has the rest.
const STARTED_FORMAT : String = "%s alkoi! Yläpalkin %s kertoo, mitä se tuo."


## `days_left` as SeasonRules.days_left() gives it; 0 leaves the countdown out.
static func tooltip(data : SeasonData, days_left : int) -> String:
	var lines : PackedStringArray = [UiText.of(data.title), UiText.of(data.description)]
	if days_left > 0:
		lines.append(countdown(days_left))
	return "\n".join(lines)


## The main menu's line under the title: icon, name and countdown.
static func line(data : SeasonData, days_left : int) -> String:
	var title : String = "%s %s" % [data.icon, UiText.of(data.title)]
	return title if days_left <= 0 else title + "\n" + countdown(days_left)


static func countdown(days_left : int) -> String:
	return UiText.of(LAST_DAY_TEXT) if days_left == 1 else UiText.of(DAYS_LEFT_FORMAT) % days_left


static func started(data : SeasonData) -> String:
	return UiText.of(STARTED_FORMAT) % [UiText.of(data.title), data.icon]


## The ingredient's name with its season's mark, so the shop shows what is only for now.
static func seasonal_name(ingredient_name : String, data : SeasonData) -> String:
	return ingredient_name if data == null else "%s %s" % [data.icon, ingredient_name]
