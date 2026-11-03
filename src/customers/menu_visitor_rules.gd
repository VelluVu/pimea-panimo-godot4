class_name MenuVisitorRules
extends RefCounted

## Who drops by the main menu's cellar: customers the player has met, or could meet now,
## and the season's own guests even before they are met, as a teaser of what is on.

## The season's guests come this much more often, so the menu shows the season.
const SEASON_GUEST_BOOST : float = 3.0


## `can_appear` is CustomerRegistry.is_eligible(), taken in so tests can pass their own.
static func candidates(customers : Array[CustomerData], met_titles : Array, can_appear : Callable, season : SeasonRules.Season) -> Array[CustomerData]:
	var picked : Array[CustomerData] = []
	for customer : CustomerData in customers:
		if customer.sprite_frames == null:
			continue
		if _is_season_guest(customer, season) or (customer.comes_in(season, met_titles.has(customer.title)) and (met_titles.has(customer.title) or can_appear.call(customer))):
			picked.append(customer)
	return picked


static func weight(customer : CustomerData, season : SeasonRules.Season, is_met : bool) -> float:
	var base : float = customer.get_appearance_weight(season, is_met)
	return base * SEASON_GUEST_BOOST if _is_season_guest(customer, season) else base


static func _is_season_guest(customer : CustomerData, season : SeasonRules.Season) -> bool:
	return customer.busy_season != SeasonRules.Season.NONE and SeasonRules.includes(season, customer.busy_season)
