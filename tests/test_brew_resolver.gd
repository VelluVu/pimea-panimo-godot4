@tool
extends McpTestSuite

## Unit tests for BrewResolver's pure _range_precision() math.
##
## resolve_brew_style() itself is NOT covered here: it reaches directly into
## IngredientDatabase.database (a static var populated by the autoload's own
## lifecycle), which this @tool-context test harness cannot access — the
## same limitation as BrewEngine.current_brewery in test_customer_data.gd.
## Only autoload constants and plain Resource/RefCounted logic are testable
## this way. Covering resolve_brew_style() would need either refactoring it
## to accept ingredient data as a parameter instead of reaching into the
## autoload directly, or testing it via game_eval against a running game
## instead of this suite.


func suite_name() -> String:
	return "brew_resolver"


func test_range_precision_is_perfect_at_center() -> void:
	var resolver := BrewResolver.new()
	assert_eq(resolver._range_precision(20, 10, 30), 1.0)


func test_range_precision_is_zero_at_edges() -> void:
	var resolver := BrewResolver.new()
	assert_eq(resolver._range_precision(10, 10, 30), 0.0)
	assert_eq(resolver._range_precision(30, 10, 30), 0.0)


func test_range_precision_is_clamped_outside_range() -> void:
	var resolver := BrewResolver.new()
	assert_eq(resolver._range_precision(5, 10, 30), 0.0)


func test_range_precision_handles_degenerate_range() -> void:
	var resolver := BrewResolver.new()
	assert_eq(resolver._range_precision(999, 10, 10), 1.0)
