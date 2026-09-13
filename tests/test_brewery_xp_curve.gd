@tool
extends McpTestSuite

## Unit tests for Brewery.xp_required_for_level() — the per-run XP/level
## curve driving LevelUpWindow. Deliberately static (see its own
## docstring) so it's testable without constructing a Brewery, which
## needs live autoloads in its own _init() (RunModifierRegistry) — same
## limitation documented in test_brew_resolver.gd for resolve_brew_style().


func suite_name() -> String:
	return "brewery_xp_curve"


func test_xp_required_for_level_one_is_the_base_amount() -> void:
	assert_eq(Brewery.xp_required_for_level(1), 40)


func test_xp_required_for_level_grows_linearly() -> void:
	assert_eq(Brewery.xp_required_for_level(2), 60)
	assert_eq(Brewery.xp_required_for_level(3), 80)
	assert_eq(Brewery.xp_required_for_level(5), 120)
