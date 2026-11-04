@tool
extends McpTestSuite


func suite_name() -> String:
	return "naughty_list_rules"


func test_more_tuhma_marks_bring_the_punishment() -> void:
	assert_eq(NaughtyListRules.verdict(1, 2, true), NaughtyListRules.Verdict.PUNISHMENT)


func test_a_kiltti_list_and_his_pukkibock_bring_the_gifts() -> void:
	assert_eq(NaughtyListRules.verdict(NaughtyListRules.GIFT_MIN_KILTTI, 0, true), NaughtyListRules.Verdict.GIFT)


func test_without_his_pukkibock_a_kiltti_list_only_buys_a_favour() -> void:
	assert_eq(NaughtyListRules.verdict(3, 0, false), NaughtyListRules.Verdict.FAVOUR)


func test_one_kiltti_mark_is_not_enough_for_the_gifts() -> void:
	assert_eq(NaughtyListRules.verdict(1, 0, true), NaughtyListRules.Verdict.FAVOUR)


func test_an_even_or_empty_list_gets_only_a_smile() -> void:
	assert_eq(NaughtyListRules.verdict(0, 0, true), NaughtyListRules.Verdict.NONE)
	assert_eq(NaughtyListRules.verdict(2, 2, true), NaughtyListRules.Verdict.NONE)


func test_mischief_leaves_footprints_when_there_is_nothing_to_take() -> void:
	assert_eq(NaughtyListRules.mischief(false, false, 0.5), NaughtyListRules.Mischief.FOOTPRINTS)


func test_mischief_picks_from_what_the_cellar_has() -> void:
	assert_eq(NaughtyListRules.mischief(true, false, 0.9), NaughtyListRules.Mischief.HIDE_INGREDIENT)
	assert_eq(NaughtyListRules.mischief(false, true, 0.1), NaughtyListRules.Mischief.SIP_KEG)
	assert_eq(NaughtyListRules.mischief(true, true, 0.1), NaughtyListRules.Mischief.HIDE_INGREDIENT)
	assert_eq(NaughtyListRules.mischief(true, true, 0.99), NaughtyListRules.Mischief.SIP_KEG)


func test_the_tontut_hide_a_third_but_at_least_one_unit() -> void:
	assert_eq(NaughtyListRules.hidden_amount(1), 1)
	assert_eq(NaughtyListRules.hidden_amount(9), 4)
	assert_eq(NaughtyListRules.hidden_amount(0), 0)
