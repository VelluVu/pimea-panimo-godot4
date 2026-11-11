@tool
extends McpTestSuite

const MenuVisitorRulesScript := preload("res://src/customers/rules/menu_visitor_rules.gd")
const CustomerDataScript := preload("res://src/customers/customer_data.gd")
const SeasonRulesScript := preload("res://src/events/season_rules.gd")


func suite_name() -> String:
	return "menu_visitor_rules"


func _customer(title : String, busy_season : int = SeasonRulesScript.Season.NONE, busy_weight : float = 1.0) -> CustomerData:
	var data : CustomerData = CustomerDataScript.new()
	data.title = title
	data.sprite_frames = SpriteFrames.new()
	data.busy_season = busy_season
	data.busy_season_weight = busy_weight
	return data


func _never(_customer : CustomerData) -> bool:
	return false


func _always(_customer : CustomerData) -> bool:
	return true


func test_met_customers_drop_by() -> void:
	var met : CustomerData = _customer("Opiskelija")
	var stranger : CustomerData = _customer("Agentti")
	var customers : Array[CustomerData] = [met, stranger]
	assert_eq(MenuVisitorRulesScript.candidates(customers, ["Opiskelija"], _never, SeasonRulesScript.Season.NONE), [met])


func test_customers_who_could_appear_drop_by_unmet() -> void:
	var customers : Array[CustomerData] = [_customer("Opiskelija")]
	assert_eq(MenuVisitorRulesScript.candidates(customers, [], _always, SeasonRulesScript.Season.NONE).size(), 1)


func test_the_seasons_guest_comes_before_being_met_and_more_often() -> void:
	var guest : CustomerData = _customer("Tarjoushaukka", SeasonRulesScript.Season.BLACK_MONTH, 2.0)
	var customers : Array[CustomerData] = [guest]
	assert_eq(MenuVisitorRulesScript.candidates(customers, [], _never, SeasonRulesScript.Season.CYBER_WEEK), [guest])
	assert_eq(MenuVisitorRulesScript.weight(guest, SeasonRulesScript.Season.BLACK_MONTH, false), 2.0 * MenuVisitorRulesScript.SEASON_GUEST_BOOST)


func test_a_seasonal_guest_stays_away_out_of_season() -> void:
	var guest : CustomerData = _customer("Tarjoushaukka", SeasonRulesScript.Season.BLACK_MONTH, 2.0)
	guest.appearance_weight = 0.0
	var customers : Array[CustomerData] = [guest]
	assert_eq(MenuVisitorRulesScript.candidates(customers, [], _always, SeasonRulesScript.Season.HALLOWEEN).size(), 0)


func test_a_customer_without_sprites_never_walks_in() -> void:
	var ghost : CustomerData = _customer("Opiskelija")
	ghost.sprite_frames = null
	var customers : Array[CustomerData] = [ghost]
	assert_eq(MenuVisitorRulesScript.candidates(customers, ["Opiskelija"], _always, SeasonRulesScript.Season.NONE).size(), 0)
