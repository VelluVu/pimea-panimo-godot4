class_name RunScore
extends RefCounted

## The run's score and the renown paid for it. Scored once, at its first ending, so playing
## on never raises it; continued nights only pay reduced renown.

const DAY_POINTS : int = 100
const REPUTATION_POINTS : int = 10
## One point per this many servings, by integer division like the board's SQL.
const SERVINGS_PER_POINT : int = 2
## Reaching the target day as a legend must always beat any run that did not.
const SURVIVAL_BONUS : int = 1500
## Endings that close the brewery: no points for reputation or worth, so a failed run never
## outscores one that made it.
const FAILED_ENDINGS : PackedStringArray = ["busted", "bankrupt"]
## Points per euro of worth (money and cellar upgrades), so buying one never lowers the score.
const WORTH_POINTS_PER_EURO : float = 0.5
const MONEY_WORTH_SHARE : float = 0.5
## Per style brewed this season, so the range pays, not one safe style.
const STYLE_POINTS : int = 100

const RENOWN_DIVISOR : float = 20.0
## A bust already costs the run, so it still pays a little.
const RENOWN_FLOOR : int = 5
## A night of continued play pays this share of what the same day would have scored.
const CONTINUED_RENOWN_RATE : float = 0.5


static func scored_days(day : int) -> int:
	return mini(day, DayRules.SURVIVAL_DAY_TARGET)


static func bonus(ending_type : String) -> int:
	return SURVIVAL_BONUS if ending_type == DayRules.ENDING_SURVIVED else 0


static func counts_reputation(ending_type : String) -> bool:
	return not FAILED_ENDINGS.has(ending_type)


static func reputation_points(reputation : int, ending_type : String) -> int:
	return maxi(0, reputation) * REPUTATION_POINTS if counts_reputation(ending_type) else 0


@warning_ignore("integer_division")
static func bottle_points(bottles : int) -> int:
	return maxi(0, bottles) / SERVINGS_PER_POINT


static func worth_points(worth : float, ending_type : String) -> int:
	return roundi(maxf(0.0, worth) * WORTH_POINTS_PER_EURO) if counts_reputation(ending_type) else 0


static func base_points(day : int, reputation : int, bottles : int, ending_type : String, worth : float = 0.0, styles : int = 0) -> int:
	return scored_days(day) * DAY_POINTS + reputation_points(reputation, ending_type) + bottle_points(bottles) + bonus(ending_type) + worth_points(worth, ending_type) \
			+ styles * STYLE_POINTS


static func score(day : int, reputation : int, bottles : int, ending_type : String, worth : float = 0.0, styles : int = 0) -> int:
	return base_points(day, reputation, bottles, ending_type, worth, styles)


static func renown(run_score : int) -> int:
	return maxi(RENOWN_FLOOR, roundi(run_score / RENOWN_DIVISOR))


## Renown for one night after the run was scored: that day's points and bottles, at a reduced rate.
static func continued_day_renown(bottles_sold_that_day : int) -> int:
	var points : int = DAY_POINTS + bottle_points(bottles_sold_that_day)
	return roundi(points / RENOWN_DIVISOR * CONTINUED_RENOWN_RATE)


## The score with its parts, as the leaderboard stores it. An empty `ending_type` is the run
## in progress, without the survival bonus.
static func entry(day : int, reputation : int, bottles : int, ending_type : String, worth : float = 0.0, styles : int = 0) -> Dictionary:
	return {
		"ending_type": ending_type,
		"days_survived": scored_days(day),
		"reputation": reputation,
		"lifetime_bottles_sold": bottles,
		"worth": snappedf(maxf(0.0, worth), 0.1),
		"styles_brewed": styles,
		"bonus": bonus(ending_type),
		"score": score(day, reputation, bottles, ending_type, worth, styles),
	}


## A stored entry's score under today's formula, from the parts it keeps.
static func rescore(stored : Dictionary) -> int:
	var ending_type : String = stored.get("ending_type", "")
	return base_points(stored.get("days_survived", 0), stored.get("reputation", 0), stored.get("lifetime_bottles_sold", 0), ending_type, stored.get("worth", 0.0), stored.get("styles_brewed", 0))


static func entry_for(brewery : Brewery, ending_type : String) -> Dictionary:
	return entry(brewery.current_day, brewery.reputation, brewery.lifetime_bottles_sold, ending_type, brewery_worth(brewery), brewery.brewed_styles.size())


static func brewery_worth(brewery : Brewery) -> float:
	return worth_of(brewery.money, CellarUpgrades.invested_value(brewery.cellar_upgrade_levels, CellarUpgrades.all()))


## Upgrades count at what they cost, money left over at MONEY_WORTH_SHARE, so building
## the cellar out scores better than sitting on cash.
static func worth_of(money : float, invested : float) -> float:
	return money * MONEY_WORTH_SHARE + invested
