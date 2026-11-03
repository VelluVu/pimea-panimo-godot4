class_name SeasonalPrice
extends RefCounted

## The hand-set list price of a style in the season `current`: a seasonal style's full price
## only in its own season (Kurpitsaolut in Halloween), its off-season price the rest of the
## year, so a style learned in season stays worth brewing but not worth stockpiling for.


## 0 when the style has no hand-set price (StylePricing then uses cost plus margin).
static func list_price(beer_style : BeerStyle, current : SeasonRules.Season) -> float:
	if not has_season_price(beer_style) or SeasonRules.includes(current, beer_style.price_season):
		return beer_style.fixed_price_per_bottle
	return beer_style.off_season_price_per_bottle


static func has_season_price(beer_style : BeerStyle) -> bool:
	return beer_style.price_season != SeasonRules.Season.NONE and beer_style.off_season_price_per_bottle > 0.0
