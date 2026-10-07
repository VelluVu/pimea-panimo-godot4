class_name LeaderboardText
extends RefCounted

## Player-facing text for leaderboard entries (RunScore.entry_for()):
## the ending's name and the score broken into its parts.

const ENDING_SURVIVED : String = "Legenda"
const ENDING_SEASON_OVER : String = "Selvisi"
const ENDING_BUSTED : String = "Jäi kiinni"
const ENDING_BANKRUPT : String = "Konkurssi"
const ENDING_IN_PROGRESS : String = "Kesken"

const DAYS_LINE : String = "Päivät %d × %d"
const REPUTATION_LINE : String = "Maine %d × %d"
const REPUTATION_UNSCORED_LINE : String = "Maine %d: ei pisteitä"
const BOTTLES_LINE : String = "Annokset %d"
const WORTH_LINE : String = "Panimon arvo %d €: +%d"
const BONUS_LINE : String = "Legendabonus +%d"
const TOTAL_LINE : String = "Pisteet: %d"

## Endesga 32: gold, silver and bronze for the podium.
const PODIUM_COLORS : Array[Color] = [Color("feae34"), Color("c0cbdc"), Color("e4a672")]
const ENDING_COLORS : Dictionary = {
	"survived": Color("feae34"),
	"season_over": Color("63c74d"),
	"busted": Color("e43b44"),
	"bankrupt": Color("8b9bb4"),
	"": Color("f77622"),
}
## The theme's Label color.
const DEFAULT_COLOR : Color = Color("ecdcb8")


static func ending_label(ending_type : String) -> String:
	match ending_type:
		"survived":
			return UiText.of(ENDING_SURVIVED)
		"season_over":
			return UiText.of(ENDING_SEASON_OVER)
		"busted":
			return UiText.of(ENDING_BUSTED)
		"bankrupt":
			return UiText.of(ENDING_BANKRUPT)
		"":
			return UiText.of(ENDING_IN_PROGRESS)
	return ending_type


## Gold, silver and bronze for the top three, the plain text color below them.
static func rank_color(rank : int) -> Color:
	if rank >= 1 and rank <= PODIUM_COLORS.size():
		return PODIUM_COLORS[rank - 1]
	return DEFAULT_COLOR


static func ending_color(ending_type : String) -> Color:
	return ENDING_COLORS.get(ending_type, DEFAULT_COLOR)


## One part per line; the bonus line only when the run earned it.
static func breakdown_lines(entry : Dictionary) -> PackedStringArray:
	var lines : PackedStringArray = [
		UiText.of(DAYS_LINE) % [entry.get("days_survived", 0), RunScore.DAY_POINTS],
		_reputation_line(entry),
		UiText.of(BOTTLES_LINE) % entry.get("lifetime_bottles_sold", 0),
	]
	var worth_points : int = RunScore.worth_points(entry.get("worth", 0.0), entry.get("ending_type", ""))
	if worth_points > 0:
		lines.append(UiText.of(WORTH_LINE) % [roundi(entry.get("worth", 0.0)), worth_points])
	var bonus : int = entry.get("bonus", 0)
	if bonus > 0:
		lines.append(UiText.of(BONUS_LINE) % bonus)
	return lines


## A busted or bankrupt run's reputation is shown but earns nothing, see RunScore.
static func _reputation_line(entry : Dictionary) -> String:
	if not RunScore.counts_reputation(entry.get("ending_type", "")):
		return UiText.of(REPUTATION_UNSCORED_LINE) % entry.get("reputation", 0)
	return UiText.of(REPUTATION_LINE) % [entry.get("reputation", 0), RunScore.REPUTATION_POINTS]


static func breakdown(entry : Dictionary) -> String:
	var lines : PackedStringArray = breakdown_lines(entry)
	lines.append(UiText.of(TOTAL_LINE) % entry.get("score", 0))
	return "\n".join(lines)


## "2026-09-13T10:27:33" -> "13.09.2026".
static func format_date(iso_datetime : String) -> String:
	if iso_datetime.is_empty():
		return ""
	var parts : Dictionary = Time.get_datetime_dict_from_datetime_string(iso_datetime, false)
	return "%02d.%02d.%04d" % [parts["day"], parts["month"], parts["year"]]
