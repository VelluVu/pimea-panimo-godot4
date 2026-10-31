class_name SeasonRules
extends RefCounted

## Which season the player's own clock is in. Halloween runs from late October into early
## November; Black Month from the day after it through Cyber Monday, with Cyber Week (the
## Monday before Black Friday through Cyber Monday) blended into its end. Christmas has no
## season yet: when it gets one, add it here.

## Cyber Week is part of Black Month: see includes().
enum Season { NONE, HALLOWEEN, BLACK_MONTH, CYBER_WEEK }

const HALLOWEEN_FIRST_DAY_OCTOBER : int = 20
const HALLOWEEN_LAST_DAY_NOVEMBER : int = 8
## Black Friday is the day after the fourth Thursday of November.
const THANKSGIVING_THURSDAY_INDEX : int = 4
## From the Monday before Black Friday (4 days earlier) to Cyber Monday (3 days later).
const CYBER_WEEK_DAYS_BEFORE : int = 4
const CYBER_WEEK_DAYS_AFTER : int = 3
## December days count on from November's in _november_day().
const NOVEMBER_DAYS : int = 30
const OUTSIDE_NOVEMBER : int = -100

## Set by the developer console to try a season out of its dates; cleared by clear_forced().
static var _forced : Season = Season.NONE
static var _is_forced : bool = false


static func now() -> Season:
	return _forced if _is_forced else season_of(Time.get_date_dict_from_system())


static func force(season : Season) -> void:
	_forced = season
	_is_forced = true


static func clear_forced() -> void:
	_is_forced = false


## True when something made for `wanted` belongs in `current`: its own season, and
## everything of Black Month in Cyber Week too.
static func includes(current : Season, wanted : Season) -> bool:
	return current == wanted or (wanted == Season.BLACK_MONTH and current == Season.CYBER_WEEK)


## `date` as Time.get_date_dict_from_system() gives it.
static func season_of(date : Dictionary) -> Season:
	var year : int = date.get("year", 0)
	var month : int = date.get("month", 0)
	var day : int = date.get("day", 0)
	if month == Time.MONTH_OCTOBER and day >= HALLOWEEN_FIRST_DAY_OCTOBER:
		return Season.HALLOWEEN
	if month == Time.MONTH_NOVEMBER and day <= HALLOWEEN_LAST_DAY_NOVEMBER:
		return Season.HALLOWEEN
	if year <= 0:
		return Season.NONE
	var november_day : int = _november_day(month, day)
	var friday : int = black_friday_day(year)
	if november_day > friday + CYBER_WEEK_DAYS_AFTER or november_day == OUTSIDE_NOVEMBER:
		return Season.NONE
	if november_day >= friday - CYBER_WEEK_DAYS_BEFORE:
		return Season.CYBER_WEEK
	return Season.BLACK_MONTH


## The November day of Black Friday in `year`.
static func black_friday_day(year : int) -> int:
	var first_weekday : int = Time.get_datetime_dict_from_datetime_string("%04d-11-01" % year, true).weekday
	var first_thursday : int = 1 + posmod(Time.WEEKDAY_THURSDAY - first_weekday, 7)
	return first_thursday + (THANKSGIVING_THURSDAY_INDEX - 1) * 7 + 1


## Cyber Monday can fall in December (Black Friday on the 28th or later), so December days
## count on from 30 November; any other month is OUTSIDE_NOVEMBER.
static func _november_day(month : int, day : int) -> int:
	if month == Time.MONTH_NOVEMBER:
		return day
	if month == Time.MONTH_DECEMBER:
		return NOVEMBER_DAYS + day
	return OUTSIDE_NOVEMBER
