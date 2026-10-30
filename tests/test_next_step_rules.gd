@tool
extends McpTestSuite

## Unit tests for NextStepRules: the day-one route (recipe book, shop, brewery, Pane) and
## the empty-bar steps.

const NextStepRulesScript := preload("res://src/progression/next_step_rules.gd")

const BAR : NextStepRulesScript.View = NextStepRulesScript.View.BAR
const BREWERY : NextStepRulesScript.View = NextStepRulesScript.View.BREWERY
const SHOP : NextStepRulesScript.View = NextStepRulesScript.View.SHOP


func suite_name() -> String:
	return "next_step_rules"


func _step(view : NextStepRulesScript.View, library_open : bool, recipe_read : bool, bought_any : bool, missing : bool, can_brew : bool, kotikalja_page : bool = false) -> NextStepRulesScript.Step:
	return NextStepRulesScript.first_brew(view, library_open, kotikalja_page, recipe_read, bought_any, missing, can_brew)


func test_the_recipe_book_comes_first() -> void:
	assert_eq(_step(BAR, false, false, false, true, false), NextStepRulesScript.Step.OPEN_RECIPES)
	assert_eq(_step(BREWERY, false, false, false, true, false), NextStepRulesScript.Step.OPEN_RECIPES, "the shelf is beside the open views")
	assert_eq(_step(BAR, true, false, false, true, false), NextStepRulesScript.Step.PICK_RECIPE)


func test_the_kotikalja_page_explains_loading() -> void:
	assert_eq(_step(BAR, true, true, false, true, false, true), NextStepRulesScript.Step.LOAD_RECIPE)
	assert_eq(_step(BAR, true, true, true, true, false, true), NextStepRulesScript.Step.GO_TO_SHOP, "a buyer is past the book")


func test_a_player_who_already_bought_skips_the_book() -> void:
	assert_eq(_step(BAR, false, false, true, true, false), NextStepRulesScript.Step.GO_TO_SHOP)


func test_after_the_recipe_the_shop_then_its_buy_button() -> void:
	assert_eq(_step(BAR, false, true, false, true, false), NextStepRulesScript.Step.GO_TO_SHOP)
	assert_eq(_step(BREWERY, false, true, false, true, false), NextStepRulesScript.Step.GO_TO_SHOP)
	assert_eq(_step(SHOP, false, true, false, true, false), NextStepRulesScript.Step.BUY_MISSING)


func test_bought_ingredients_lead_to_the_brewery_table() -> void:
	assert_eq(_step(SHOP, false, true, true, false, false), NextStepRulesScript.Step.CLOSE_SHOP)
	assert_eq(_step(BAR, false, true, true, false, false), NextStepRulesScript.Step.OPEN_BREWERY)
	assert_eq(_step(BREWERY, false, true, true, false, false), NextStepRulesScript.Step.ADD_INGREDIENTS)


func test_a_full_table_points_at_pane() -> void:
	assert_eq(_step(BREWERY, false, true, true, false, true), NextStepRulesScript.Step.START_BREW)
	assert_eq(_step(SHOP, false, true, true, false, true), NextStepRulesScript.Step.START_BREW, "Pane shows beside the shop too")
	assert_eq(_step(BAR, false, true, true, false, true), NextStepRulesScript.Step.OPEN_BREWERY)


func test_after_first_brew_only_an_empty_bar_gets_a_step() -> void:
	assert_eq(NextStepRulesScript.after_first_brew(true, true), NextStepRulesScript.Step.NONE)
	assert_eq(NextStepRulesScript.after_first_brew(false, true), NextStepRulesScript.Step.WAIT_FERMENT)
	assert_eq(NextStepRulesScript.after_first_brew(false, false), NextStepRulesScript.Step.BREW_MORE)
