@tool
extends McpTestSuite

const SeasonCatalogScript := preload("res://src/events/season_catalog.gd")
const SeasonDataScript := preload("res://src/events/season_data.gd")
const SeasonRulesScript := preload("res://src/events/season_rules.gd")


func suite_name() -> String:
	return "season_catalog"


func _seasons() -> Array[SeasonData]:
	var halloween : SeasonData = SeasonDataScript.new()
	halloween.season = SeasonRulesScript.Season.HALLOWEEN
	var black_month : SeasonData = SeasonDataScript.new()
	black_month.season = SeasonRulesScript.Season.BLACK_MONTH
	var winter : SeasonData = SeasonDataScript.new()
	winter.winter = true
	var seasons : Array[SeasonData] = [halloween, black_month, winter]
	return seasons


func test_a_named_season_wins_over_winter() -> void:
	var seasons : Array[SeasonData] = _seasons()
	assert_eq(SeasonCatalogScript.pick(SeasonRulesScript.Season.BLACK_MONTH, true, seasons), seasons[1])


func test_winter_shows_between_named_seasons() -> void:
	var seasons : Array[SeasonData] = _seasons()
	assert_eq(SeasonCatalogScript.pick(SeasonRulesScript.Season.NONE, true, seasons), seasons[2])


func test_nothing_shows_out_of_every_season() -> void:
	assert_eq(SeasonCatalogScript.pick(SeasonRulesScript.Season.NONE, false, _seasons()), null)


func test_a_season_without_data_shows_nothing() -> void:
	assert_eq(SeasonCatalogScript.pick(SeasonRulesScript.Season.CYBER_WEEK, false, _seasons()), null)


func test_every_season_has_its_data() -> void:
	var seasons : Array[SeasonData] = SeasonCatalogScript.all()
	for season : int in [SeasonRulesScript.Season.HALLOWEEN, SeasonRulesScript.Season.BLACK_MONTH, SeasonRulesScript.Season.CYBER_WEEK]:
		assert_true(SeasonCatalogScript.of(season, seasons) != null)
	assert_true(SeasonCatalogScript.pick(SeasonRulesScript.Season.NONE, true, seasons) != null)
