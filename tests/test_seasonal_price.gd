@tool
extends McpTestSuite

const SeasonalPriceScript := preload("res://src/brewing/seasonal_price.gd")
const BeerStyleScript := preload("res://src/brewing/beer_style.gd")
const SeasonRulesScript := preload("res://src/events/season_rules.gd")


func suite_name() -> String:
	return "seasonal_price"


func _style(season : int, in_season : float, off_season : float) -> BeerStyle:
	var style : BeerStyle = BeerStyleScript.new()
	style.fixed_price_per_bottle = in_season
	style.price_season = season
	style.off_season_price_per_bottle = off_season
	return style


func test_full_price_in_its_season() -> void:
	var style := _style(SeasonRulesScript.Season.HALLOWEEN, 3.8, 3.0)
	assert_eq(SeasonalPriceScript.list_price(style, SeasonRulesScript.Season.HALLOWEEN), 3.8)


func test_off_season_price_outside_it() -> void:
	var style := _style(SeasonRulesScript.Season.HALLOWEEN, 3.8, 3.0)
	assert_eq(SeasonalPriceScript.list_price(style, SeasonRulesScript.Season.NONE), 3.0)
	assert_eq(SeasonalPriceScript.list_price(style, SeasonRulesScript.Season.BLACK_MONTH), 3.0)


## Black Month runs on through Cyber Week (SeasonRules.includes()).
func test_black_month_price_holds_in_cyber_week() -> void:
	var style := _style(SeasonRulesScript.Season.BLACK_MONTH, 3.0, 2.0)
	assert_eq(SeasonalPriceScript.list_price(style, SeasonRulesScript.Season.CYBER_WEEK), 3.0)


func test_cyber_week_price_ends_with_cyber_week() -> void:
	var style := _style(SeasonRulesScript.Season.CYBER_WEEK, 3.0, 2.0)
	assert_eq(SeasonalPriceScript.list_price(style, SeasonRulesScript.Season.BLACK_MONTH), 2.0)


func test_style_without_season_price_keeps_its_price() -> void:
	assert_eq(SeasonalPriceScript.list_price(_style(SeasonRulesScript.Season.NONE, 2.5, 0.0), SeasonRulesScript.Season.HALLOWEEN), 2.5)
	# A season without an off-season price is no season price.
	assert_eq(SeasonalPriceScript.list_price(_style(SeasonRulesScript.Season.HALLOWEEN, 2.5, 0.0), SeasonRulesScript.Season.NONE), 2.5)
