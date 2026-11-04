@tool
extends McpTestSuite


func suite_name() -> String:
	return "christmas_gift_rules"


func _upgrade(id : String, max_level : int, is_machine : bool = false) -> CellarUpgradeData:
	var upgrade := CellarUpgradeData.new()
	upgrade.upgrade_id = id
	upgrade.perk_name = id
	upgrade.max_level = max_level
	upgrade.is_machine = is_machine
	return upgrade


func _perk(perk_name : String) -> RunPerk:
	var perk := RunPerk.new()
	perk.perk_name = perk_name
	return perk


func test_a_maxed_upgrade_is_never_wrapped() -> void:
	assert_false(ChristmasGiftRules.can_wrap_upgrade(_upgrade("hylly", 2), 2, []))
	assert_true(ChristmasGiftRules.can_wrap_upgrade(_upgrade("hylly", 2), 1, []))


func test_a_machine_owned_from_an_earlier_season_is_never_wrapped() -> void:
	assert_false(ChristmasGiftRules.can_wrap_upgrade(_upgrade("kone", 1, true), 0, ["kone"]))


func test_an_owned_perk_is_never_wrapped_even_as_a_loaded_copy() -> void:
	var owned : Array[RunPerk] = [_perk("Donin suojelus")]
	var gifts : Array[ChristmasGift] = ChristmasGiftRules.roll([], {}, [], [_perk("Donin suojelus"), _perk("Tuplatippikurssi")], owned, 3)
	assert_eq(gifts.size(), 1)
	assert_eq(gifts[0].display_name(), "Tuplatippikurssi")


func test_the_roll_gives_at_most_count_different_gifts() -> void:
	var upgrades : Array[CellarUpgradeData] = [_upgrade("a", 3), _upgrade("b", 3)]
	var perks : Array[RunPerk] = [_perk("x"), _perk("y")]
	var gifts : Array[ChristmasGift] = ChristmasGiftRules.roll(upgrades, {}, [], perks, [], 3)
	assert_eq(gifts.size(), 3)
	var names : Dictionary = {}
	for gift : ChristmasGift in gifts:
		names[gift.display_name()] = true
	assert_eq(names.size(), 3)


func test_the_gift_pool_leaves_the_cellar_cat_out() -> void:
	var pool : ChristmasGiftPool = load("res://src/resources/christmas/joulupukki_gift_pool.tres")
	assert_false(pool.perks.is_empty())
	for perk : RunPerk in pool.perks:
		assert_ne(perk.perk_name, "Kellarikissa")


func test_korvatunturi_takes_the_beer_for_free() -> void:
	var outcome := SaleOutcome.new()
	outcome.gross_income = 9.0
	outcome.tip_income = 2.0
	outcome.net_income = 11.0
	outcome.reputation_gain = 5
	outcome.waive_payment()
	assert_eq(outcome.gross_income + outcome.tip_income + outcome.net_income, 0.0)
	assert_eq(outcome.reputation_gain, 5)


func test_koivurisu_is_never_sold() -> void:
	var koivurisu : IngredientData = load("res://src/resources/ingredients/spices/koivurisu.tres")
	assert_eq(koivurisu.id, NaughtyListRules.KOIVURISU_ID)
	assert_false(koivurisu.is_sold_in(SeasonRules.Season.CHRISTMAS))
	assert_false(koivurisu.is_sold_in(SeasonRules.Season.NONE))


func test_tontut_and_joulupukki_take_for_free_and_keep_the_list() -> void:
	for name : String in ["tonttu_harmaa", "tonttu_sydan", "tonttu_punainen"]:
		var tonttu : CustomerData = load("res://src/resources/customers/%s.tres" % name)
		assert_true(tonttu.takes_for_free, name)
		assert_eq(tonttu.korvatunturi_role, CustomerData.KorvatunturiRole.TONTTU, name)
	var joulupukki : CustomerData = load("res://src/resources/customers/joulupukki.tres")
	assert_true(joulupukki.takes_for_free)
	assert_eq(joulupukki.korvatunturi_role, CustomerData.KorvatunturiRole.JOULUPUKKI)


## An unopened offer is saved with the run, so quitting with the window open loses nothing.
func test_unopened_gifts_survive_a_save() -> void:
	var path : String = "user://_test_christmas_gifts.tres"
	var brewery := Brewery.new()
	var perk : RunPerk = load("res://src/resources/event_perks/kurssi_tuplatipit.tres")
	brewery.christmas_gifts = [ChristmasGift.of_perk(perk)]
	assert_eq(ResourceSaver.save(brewery, path), OK)
	var loaded := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as Brewery
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	assert_eq(loaded.christmas_gifts.size(), 1)
	assert_eq(loaded.christmas_gifts[0].display_name(), perk.perk_name)
