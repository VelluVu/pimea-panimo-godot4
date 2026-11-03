class_name SeasonRules
extends RefCounted

## Which season the player's own clock is in. Halloween runs from late October into early
## November; Black Month from the day after it through Cyber Monday, with Cyber Week (the
## Monday before Black Friday through Cyber Monday) blended into its end. Christmas runs
## from the day after Cyber Monday to Epiphany.

## Cyber Week is part of Black Month: see includes(). New values go at the end: saved
## resources keep the numbers.
enum Season { NONE, HALLOWEEN, BLACK_MONTH, CYBER_WEEK, CHRISTMAS }

const HALLOWEEN_FIRST_DAY_OCTOBER : int = 20
const HALLOWEEN_LAST_DAY_NOVEMBER : int = 8
## Black Friday is the day after the fourth Thursday of November.
const THANKSGIVING_THURSDAY_INDEX : int = 4
## From the Monday before Black Friday (4 days earlier) to Cyber Monday (3 days later).
const CYBER_WEEK_DAYS_BEFORE : int = 4
const CYBER_WEEK_DAYS_AFTER : int = 3
## December days count on from November's in _november_day().
const NOVEMBER_DAYS : int = 30
## Christmas ends with Epiphany (loppiainen).
const CHRISTMAS_LAST_DAY_JANUARY : int = 6
const OUTSIDE_NOVEMBER : int = -100
const WINTER_LAST_MONTH : int = Time.MONTH_MARCH
const SECONDS_PER_DAY : int = 86400
## Longer than any season: winter is the longest, about five months.
const MAX_COUNTDOWN_DAYS : int = 200

## Set by the developer console to try a season out of its dates; cleared by clear_forced().
static var _forced : Season = Season.NONE
static var _is_forced : bool = false
## Like _forced, for is_winter_now().
static var _winter_forced : bool = false
static var _is_winter_forced : bool = false


static func now() -> Season:
	return _forced if _is_forced else season_of(Time.get_date_dict_from_system())


static func force(season : Season) -> void:
	_forced = season
	_is_forced = true


static func clear_forced() -> void:
	_is_forced = false


static func is_winter_now() -> bool:
	return _winter_forced if _is_winter_forced else is_winter(Time.get_date_dict_from_system())


static func force_winter(on : bool) -> void:
	_winter_forced = on
	_is_winter_forced = true


static func clear_forced_winter() -> void:
	_is_winter_forced = false


## Winter is not a Season: it runs under Black Month and Christmas, from the day after
## Halloween to the end of March. `date` as in season_of().
static func is_winter(date : Dictionary) -> bool:
	var month : int = date.get("month", 0)
	var day : int = date.get("day", 0)
	if month == Time.MONTH_NOVEMBER:
		return day > HALLOWEEN_LAST_DAY_NOVEMBER
	return month == Time.MONTH_DECEMBER or (month >= Time.MONTH_JANUARY and month <= WINTER_LAST_MONTH)


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
	if month == Time.MONTH_JANUARY and day >= 1 and day <= CHRISTMAS_LAST_DAY_JANUARY:
		return Season.CHRISTMAS
	if year <= 0:
		return Season.NONE
	var november_day : int = _november_day(month, day)
	if november_day == OUTSIDE_NOVEMBER:
		return Season.NONE
	var friday : int = black_friday_day(year)
	if november_day > friday + CYBER_WEEK_DAYS_AFTER:
		return Season.CHRISTMAS if month == Time.MONTH_DECEMBER else Season.NONE
	if november_day >= friday - CYBER_WEEK_DAYS_BEFORE:
		return Season.CYBER_WEEK
	return Season.BLACK_MONTH


## Days the season of `date` lasts, today counted: 1 on its last day, 0 out of season.
static func days_left(date : Dictionary) -> int:
	var season : Season = season_of(date)
	if season == Season.NONE:
		return 0
	return _days_while(date, func(day : Dictionary) -> bool: return season_of(day) == season)


## Like days_left(), for winter.
static func winter_days_left(date : Dictionary) -> int:
	if not is_winter(date):
		return 0
	return _days_while(date, is_winter)


## The countdown for the season on the player's clock; 0 while the console forces one, as
## the dates then say nothing about it.
static func days_left_now(for_winter : bool) -> int:
	var today : Dictionary = Time.get_date_dict_from_system()
	if for_winter:
		return 0 if _is_winter_forced else winter_days_left(today)
	return 0 if _is_forced else days_left(today)


static func _days_while(date : Dictionary, holds : Callable) -> int:
	# Noon, so a leap second or a time zone shift never skips or repeats a day.
	var start : int = Time.get_unix_time_from_datetime_dict({"year": date.get("year", 0), "month": date.get("month", 0), "day": date.get("day", 0), "hour": 12})
	var days : int = 1
	while days < MAX_COUNTDOWN_DAYS and holds.call(Time.get_date_dict_from_unix_time(start + days * SECONDS_PER_DAY)):
		days += 1
	return days


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
