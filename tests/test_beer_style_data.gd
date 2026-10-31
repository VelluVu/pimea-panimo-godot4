@tool
extends McpTestSuite

## Checks the real style and ingredient data together: every style's reference recipe
## brews that style, so no style is unreachable or shadowed by another.

const BrewResolverScript := preload("res://src/brewing/brew_resolver.gd")
const STYLES_PATH : String = "res://src/resources/beer_styles/"
const INGREDIENT_FOLDERS : Array[String] = ["malts/", "hops/", "yeasts/", "spices/"]
const INGREDIENTS_PATH : String = "res://src/resources/ingredients/"
const GOOD_QUALITY : float = 0.9
const PROMPT_ID : int = 410
const CLOUDBERRY_ID : int = 411


func suite_name() -> String:
	return "beer_style_data"


func _ingredients() -> Dictionary:
	var table : Dictionary = {}
	for folder : String in INGREDIENT_FOLDERS:
		for data : IngredientData in ResourceFolder.load_all(INGREDIENTS_PATH + folder, IngredientData):
			table[data.id] = data
	return table


func _resolver() -> BrewResolverScript:
	var resolver := BrewResolverScript.new()
	resolver.use_ingredients(_ingredients())
	resolver.active_styles.assign(ResourceFolder.load_all(STYLES_PATH, BeerStyle))
	resolver.prioritize_styles()
	return resolver


func test_every_style_has_a_reference_recipe_of_known_ingredients() -> void:
	var table : Dictionary = _ingredients()
	for beer_style : BeerStyle in _resolver().active_styles:
		assert_false(beer_style.reference_recipe.is_empty(), "%s has no reference recipe" % beer_style.style_name)
		for id : int in beer_style.reference_recipe:
			assert_true(table.has(id), "%s uses unknown ingredient %d" % [beer_style.style_name, id])


func test_reference_hops_come_in_whole_hop_steps() -> void:
	var table : Dictionary = _ingredients()
	for beer_style : BeerStyle in _resolver().active_styles:
		for id : int in beer_style.reference_recipe:
			if (table[id] as IngredientData).type == IngredientData.IngredientType.HOP:
				assert_eq(beer_style.reference_recipe[id] % HopData.GRAM_STEP, 0, "%s: %d g of hop %d" % [beer_style.style_name, beer_style.reference_recipe[id], id])


func test_every_reference_recipe_brews_its_own_style() -> void:
	var resolver := _resolver()
	for beer_style : BeerStyle in resolver.active_styles:
		var result : BrewResult = resolver.resolve_brew_style(beer_style.reference_recipe)
		var got : String = result.beer_style.style_name if result != null and result.is_matched else "nothing"
		assert_eq(got, beer_style.style_name, "%s's reference recipe brews %s" % [beer_style.style_name, got])


func test_every_style_value_has_its_data_file() -> void:
	var found : Dictionary = {}
	for beer_style : BeerStyle in _resolver().active_styles:
		assert_false(found.has(beer_style.style), "two files for %s" % beer_style.style_name)
		found[beer_style.style] = true
	assert_eq(found.size(), BeerStyle.Style.size())


func test_the_typical_abv_is_inside_the_range() -> void:
	for beer_style : BeerStyle in _resolver().active_styles:
		assert_true(beer_style.abv >= beer_style.min_abv and beer_style.abv <= beer_style.max_abv, beer_style.style_name)


## The default recipe is the game showing how it is done, so it must come out "Hyvä"
## (BrewBatch's 0.9) on a normal brew day.
func test_every_reference_recipe_is_good_on_a_normal_brew_day() -> void:
	var resolver := _resolver()
	for beer_style : BeerStyle in resolver.active_styles:
		var result : BrewResult = resolver.resolve_brew_style(beer_style.reference_recipe.duplicate())
		assert_true(result.original_quality * BrewDayRules.NORMAL_MULTIPLIER >= GOOD_QUALITY, "%s: %.2f" % [beer_style.style_name, result.original_quality])


func test_a_fully_upgraded_mash_tun_holds_every_reference_recipe() -> void:
	var upgrade : CellarUpgradeData = load("res://src/resources/cellar_upgrades/12_parempi_maskipata.tres")
	var capacity : float = MashTun.capacity_kg(upgrade.extra_mash_capacity_kg * upgrade.max_level)
	var resolver := _resolver()
	for beer_style : BeerStyle in resolver.active_styles:
		assert_true(MashTun.holds(resolver.reference_malt_weight(beer_style), capacity), beer_style.style_name)


func test_the_basic_mash_tun_holds_most_styles() -> void:
	var resolver := _resolver()
	var fitting : int = 0
	for beer_style : BeerStyle in resolver.active_styles:
		if MashTun.holds(resolver.reference_malt_weight(beer_style), MashTun.BASE_CAPACITY_KG):
			fitting += 1
	assert_eq(resolver.active_styles.size() - fitting, 7, "the upgrade gates only the 7 strongest styles")


## A Kehote makes any recipe Tekoälyolut, whatever its yeast, colour or strength.
func test_a_prompt_turns_every_reference_recipe_into_ai_beer() -> void:
	var resolver := _resolver()
	for beer_style : BeerStyle in resolver.active_styles:
		var recipe : Dictionary = beer_style.reference_recipe.duplicate()
		recipe[PROMPT_ID] = 1
		var result : BrewResult = resolver.resolve_brew_style(recipe)
		var got : String = result.beer_style.style_name if result != null and result.is_matched else "nothing"
		assert_eq(got, StringContainer.TEKOALYOLUT, "%s with a prompt brews %s" % [beer_style.style_name, got])


func test_ai_beer_is_sold_and_known_only_in_cyber_week() -> void:
	var prompt : IngredientData = _ingredients()[PROMPT_ID]
	assert_true(prompt.is_sold_in(SeasonRules.Season.CYBER_WEEK))
	assert_false(prompt.is_sold_in(SeasonRules.Season.BLACK_MONTH))
	assert_false(prompt.is_sold_in(SeasonRules.Season.NONE))
	var ai_beer : BeerStyle = _resolver().get_beer_style(BeerStyle.Style.TEKOALYOLUT)
	assert_eq(ai_beer.known_in_season, SeasonRules.Season.CYBER_WEEK)
	assert_false(ai_beer.known_from_start)


## Presidentti drinks only alcohol-free, so the seltzer's own recipe must stay under the
## line, and sugar syrup without cloudberry must not pass as the seltzer.
func test_the_seltzer_recipe_is_alcohol_free_and_needs_cloudberry() -> void:
	var resolver := _resolver()
	var seltzer : BeerStyle = resolver.get_beer_style(BeerStyle.Style.LAKKASELTZERI)
	var result : BrewResult = resolver.resolve_brew_style(seltzer.reference_recipe.duplicate())
	assert_true(result.abv <= BeerStyle.ALCOHOL_FREE_MAX_ABV, "the seltzer brews at %.1f %%" % result.abv)
	var without_cloudberry : Dictionary = seltzer.reference_recipe.duplicate()
	without_cloudberry.erase(CLOUDBERRY_ID)
	var plain : BrewResult = resolver.resolve_brew_style(without_cloudberry)
	assert_false(plain != null and plain.is_matched and plain.beer_style == seltzer, "no cloudberry, no seltzer")
