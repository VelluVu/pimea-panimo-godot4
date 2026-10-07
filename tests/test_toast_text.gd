@tool
extends McpTestSuite

## Unit tests for ToastText: the toasts that need a decision. Empty means no toast.

const ToastTextScript := preload("res://src/ui/toast_text.gd")


func suite_name() -> String:
	return "toast_text"


func _ingredient(ingredient_name : String) -> IngredientData:
	var ingredient := IngredientData.new()
	ingredient.name = ingredient_name
	return ingredient


func test_goal_success_lists_the_rewards() -> void:
	var text : String = ToastTextScript.goal_resolved("Rahaa", true, 10, 2, 5, 0)
	assert_true(text.contains("+10 €") and text.contains("+2 maine") and text.contains("+5 XP"))


func test_goal_failure_without_penalty_says_so() -> void:
	assert_true(ToastTextScript.goal_resolved("Erikoistapahtuma", false, 0, 0, 0, 0).contains("ei seurauksia"))


func test_goal_failure_with_penalty_lists_it() -> void:
	var text : String = ToastTextScript.goal_resolved("Rahaa", false, 0, -1, 0, 2)
	assert_true(text.contains("-1 maine") and text.contains("+2 LVV-riski"))


func test_early_close_with_nothing_lost_gives_no_toast() -> void:
	assert_eq(ToastTextScript.early_close(0.0, 0, 0), "")
	assert_false(ToastTextScript.early_close(1.5, 2, 3).is_empty())


func test_no_unlocks_gives_no_toast() -> void:
	assert_eq(ToastTextScript.ingredients_unlocked([] as Array[IngredientData]), "")


func test_several_unlocks_merge_and_drop_the_hop_suffix() -> void:
	var unlocked : Array[IngredientData] = [_ingredient("Cascade-humala"), _ingredient("Katajanoksat")]
	var text : String = ToastTextScript.ingredients_unlocked(unlocked)
	assert_true(text.contains("Cascade, Katajanoksat"))
	assert_false(text.contains("humala"))


func test_only_a_broken_purity_law_gets_a_toast() -> void:
	assert_eq(ToastTextScript.spiced_brew("Witbier", 0.1), "")
	assert_true(ToastTextScript.spiced_brew("Helles", -0.1).contains("Reinheitsgebot"))


func test_one_unlock_uses_the_single_format() -> void:
	assert_eq(ToastTextScript.unlocked("Uusi: %s!", "Uusia: %s!", ["Leipuri"] as Array[String]), "Uusi: Leipuri!")


func test_several_unlocks_share_one_toast() -> void:
	assert_eq(ToastTextScript.unlocked("Uusi: %s!", "Uusia: %s!", ["Leipuri", "Munkki"] as Array[String]), "Uusia: Leipuri, Munkki!")


func test_no_unlocks_means_no_toast() -> void:
	assert_eq(ToastTextScript.unlocked("Uusi: %s!", "Uusia: %s!", [] as Array[String]), "")


func test_a_big_unlock_lists_two_names_and_counts_the_rest() -> void:
	var unlocked : Array[IngredientData] = [_ingredient("Cascade-humala"), _ingredient("Citra-humala"), _ingredient("Kahvi"), _ingredient("Kaakaonibsit")]
	assert_eq(ToastTextScript.ingredients_unlocked(unlocked), "Uusia aineksia: Cascade, Citra +2")


func test_one_unlock_names_it_in_full() -> void:
	assert_eq(ToastTextScript.ingredients_unlocked([_ingredient("Kahvi")] as Array[IngredientData]), "Uusi aines: Kahvi")
