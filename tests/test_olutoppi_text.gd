@tool
extends McpTestSuite

## Unit tests for OlutoppiText: the square's short bonus and the tooltips.

const OlutoppiTextScript := preload("res://src/ui/olutoppi_text.gd")


func suite_name() -> String:
	return "olutoppi_text"


func _make_unlock() -> MetaUnlockData:
	var unlock := MetaUnlockData.new()
	unlock.perk_name = "Testiperkki"
	unlock.description = "Kuvaus"
	unlock.max_level = 3
	unlock.renown_cost_per_level = 25
	unlock.quality_bonus = 0.05 # per level
	return unlock


func test_short_bonus_is_neutral_at_level_zero() -> void:
	assert_eq(OlutoppiTextScript.short_bonus(_make_unlock(), 0), OlutoppiTextScript.BONUS_NEUTRAL_TEXT)


func test_short_bonus_shows_the_first_non_neutral_stat() -> void:
	var text : String = OlutoppiTextScript.short_bonus(_make_unlock(), 2)
	assert_ne(text, OlutoppiTextScript.BONUS_NEUTRAL_TEXT)
	assert_true(text.ends_with("%"), "a percent stat reads as a percentage")


func test_short_bonus_is_neutral_when_the_perk_sets_no_stat() -> void:
	var unlock := _make_unlock()
	unlock.quality_bonus = 0.0
	assert_eq(OlutoppiTextScript.short_bonus(unlock, 2), OlutoppiTextScript.BONUS_NEUTRAL_TEXT)


func test_locked_tooltip_lists_every_prerequisite_for_an_all_mode_node() -> void:
	var text : String = OlutoppiTextScript.locked_tooltip(_make_unlock(), PackedStringArray(["A", "B"]))
	assert_true(text.contains("A, B"), "all-mode prerequisites are joined with a comma")
	assert_true(text.begins_with("Testiperkki\nKuvaus"))


func test_locked_tooltip_joins_an_any_mode_capstone_with_or() -> void:
	var unlock := _make_unlock()
	unlock.requires_any_prerequisite = true
	var text : String = OlutoppiTextScript.locked_tooltip(unlock, PackedStringArray(["A", "B"]))
	assert_true(text.contains("A tai B"))


func test_tooltip_at_level_zero_previews_the_first_purchase_only() -> void:
	var text : String = OlutoppiTextScript.tooltip(_make_unlock(), 0, false)
	assert_false(text.contains("Nyt:"), "nothing to show as current yet")
	assert_true(text.contains("Tason 1 jälkeen:"))
	assert_true(text.contains(OlutoppiTextScript.TOOLTIP_NEXT_LEVEL_FORMAT % 25))


func test_tooltip_mid_level_shows_current_and_next() -> void:
	var text : String = OlutoppiTextScript.tooltip(_make_unlock(), 1, false)
	assert_true(text.contains("Nyt:"))
	assert_true(text.contains("Tason 2 jälkeen:"))


func test_tooltip_when_maxed_says_so_and_offers_no_next_level() -> void:
	var text : String = OlutoppiTextScript.tooltip(_make_unlock(), 3, true)
	assert_true(text.contains(OlutoppiTextScript.TOOLTIP_MAXED_TEXT))
	assert_false(text.contains("Seuraava taso"))
