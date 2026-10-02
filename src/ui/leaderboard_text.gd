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
const BONUS_LINE : String = "Legendabonus +%d"
const MULTIPLIER_LINE : String = "%s × %s"
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
			return ENDING_SURVIVED
		"season_over":
			return ENDING_SEASON_OVER
		"busted":
			return ENDING_BUSTED
		"bankrupt":
			return ENDING_BANKRUPT
		"":
			return ENDING_IN_PROGRESS
	return ending_type


## Gold, silver and bronze for the top three, the plain text color below them.
static func rank_color(rank : int) -> Color:
	if rank >= 1 and rank <= PODIUM_COLORS.size():
		return PODIUM_COLORS[rank - 1]
	return DEFAULT_COLOR


static func ending_color(ending_type : String) -> Color:
	return ENDING_COLORS.get(ending_type, DEFAULT_COLOR)


## One part per line; the bonus and multiplier lines only when they change the score.
static func breakdown_lines(entry : Dictionary) -> PackedStringArray:
	var lines : PackedStringArray = [
		DAYS_LINE % [entry.get("days_survived", 0), RunScore.DAY_POINTS],
		_reputation_line(entry),
		BOTTLES_LINE % entry.get("lifetime_bottles_sold", 0),
	]
	var bonus : int = entry.get("bonus", 0)
	if bonus > 0:
		lines.append(BONUS_LINE % bonus)
	var multiplier : float = entry.get("multiplier", 1.0)
	if not is_equal_approx(multiplier, 1.0):
		lines.append(MULTIPLIER_LINE % [entry.get("modifier_name", ""), format_multiplier(multiplier)])
	return lines


## A busted or bankrupt run's reputation is shown but earns nothing, see RunScore.
static func _reputation_line(entry : Dictionary) -> String:
	if not RunScore.counts_reputation(entry.get("ending_type", "")):
		return REPUTATION_UNSCORED_LINE % entry.get("reputation", 0)
	return REPUTATION_LINE % [entry.get("reputation", 0), RunScore.REPUTATION_POINTS]


static func breakdown(entry : Dictionary) -> String:
	var lines : PackedStringArray = breakdown_lines(entry)
	lines.append(TOTAL_LINE % entry.get("score", 0))
	return "\n".join(lines)


## Finnish decimal comma, at most two decimals: 1.35 -> "1,35", 0.95 -> "0,95".
static func format_multiplier(multiplier : float) -> String:
	return String.num(snappedf(multiplier, 0.01), 2).replace(".", ",")


## "2026-09-13T10:27:33" -> "13.09.2026".
static func format_date(iso_datetime : String) -> String:
	if iso_datetime.is_empty():
		return ""
	var parts : Dictionary = Time.get_datetime_dict_from_datetime_string(iso_datetime, false)
	return "%02d.%02d.%04d" % [parts["day"], parts["month"], parts["year"]]
