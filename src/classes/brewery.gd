class_name Brewery
extends Resource


const AVI_RAID_THRESHOLD : int = 100
const AVI_RAID_FINE_PERCENT : float = 0.3
const AVI_RAID_REPUTATION_PENALTY_PERCENT : float = 0.25
## Three strikes: the raid that pushes raid_count to this becomes
## permanent instead of just another costly setback — see
## _check_for_avi_raid() and BrewerySignals.game_ended.
const BUSTED_RAID_COUNT : int = 3
## A run only ends in the "survived" ending if it's not currently on the
## ropes — reaching the day target with 1 reputation and a completely
## empty warehouse shouldn't read as a triumphant ending. See
## TimeManager._advance_day().
const SURVIVAL_MIN_REPUTATION : int = 20

@export var inventory : Inventory
@export var current_day : int = 1
## Toward the bottles daily-goal target — deliberately NOT reset on day
## change (see TimeManager._advance_day()): a slow day's progress carries
## into the next one instead of being wiped, and only resets (with any
## overflow preserved) once the goal is actually reached and rewarded, in
## CustomerManager._check_bottles_goal_reward().
@export var bottles_sold_toward_goal : int = 0
## Never resets (unlike bottles_sold_toward_goal above) — purely a stat
## for the end-of-run summary screen, see GameEndWindow.
@export var lifetime_bottles_sold : int = 0
## One decimal of real precision (10-cent steps) — beer prices aren't all
## whole euros (see BeerStyle.fixed_price_per_bottle), so money has to
## carry fractions too. See CustomerManager.process_auto_sale() and
## CustomerData.evaluate_brew_batch() for where amounts get snapped to the
## 0.1 grid before landing here.
##
## Deliberately tight (not the old 100) — the tutorial's guaranteed recipe
## only costs 8 EUR, so a much larger cushion made the first several days
## consequence-free. 20 EUR clears the tutorial with a little room to
## experiment, without eliminating the early "can I actually afford my
## next brew" tension that the bankruptcy ending now depends on.
@export var money: float = 20.0
@export var risk: int = 0
@export var reputation: int = 0
## How many AVI raids this run has survived — see _check_for_avi_raid()
## and BUSTED_RAID_COUNT. Never resets.
@export var raid_count : int = 0
## Latched true the instant any ending fires (busted/bankrupt/survived) so
## a second condition met on the same tick (e.g. a raid that both busts
## you and would also read as bankrupt) can't emit a second, contradictory
## game_ended signal. See trigger_ending(). Not persisted — it's only ever
## true while the (paused, blocking) end screen is up; GameEndWindow's
## continue path clears it back to false before play resumes.
var game_has_ended : bool = false
## Set once the player chooses "Jatka pelaamista" on the survived ending
## (GameEndWindow) — permanently exempts this run from re-triggering the
## survived ending on every later day close. Exported: a continued run
## gets saved/loaded like any other, so this has to stick across that.
## Continued play is intentionally unbounded and NOT meant to feed any
## future leaderboard/best-run tracking — this flag is what that tracking
## should check to exclude it.
@export var has_continued_past_survival : bool = false
## Rolled once per run in _init() (see RunModifierRegistry.get_random_modifier())
## and never changes for the rest of the run. Read by
## get_effective_raid_threshold() and the ingredient buy/sell price
## calculations below — see run_modifier.gd for what each field does.
@export var run_modifier : RunModifier
## XP/level/perks are the "growth" half of the run — unlike run_modifier
## (fixed at run start), these accumulate through play via add_xp() and
## reset with the rest of the run on a new game. See RunPerk and
## LevelUpWindow.
@export var run_xp : int = 0
@export var run_level : int = 1
@export var active_perks : Array[RunPerk] = []
@export var brew_preparation : BrewPreparation
@export var saved_recipes : Array[BrewRecipe] = []
var resolver : BrewResolver = null
@export var discovered_styles : Dictionary = {} # Avain: BeerStyle.Style -> Arvo: true

## Today's completed sales, for the receipt library dropdown
## (SaleReceiptLogWindow) — cleared each day in TimeManager._advance_day().
## Not persisted: a same-day UI convenience, like `resolver` above.
var today_sale_receipts : Array[SaleReceiptEntry] = []

# First-brew tutorial tracking — one-time latches, not daily resets, so
# completing a later step never un-checks an earlier one just because the
# ingredients it used got consumed. tutorial_complete() derives from these
# rather than a separate flag, so there's a single source of truth.
@export var lifetime_malt_kg_bought : int = 0
@export var tutorial_bought_yeast : bool = false
@export var tutorial_brewed_kotikalja : bool = false

const TUTORIAL_MALT_TARGET_KG : int = 3

const XP_PER_SUCCESSFUL_BREW : int = 20
const XP_PER_NEW_STYLE_DISCOVERY_BONUS : int = 20
const XP_PER_BOTTLE_SOLD : int = 3
## level_required_xp(1) -> 40, (2) -> 60, (3) -> 80, ... — an easy, quick
## first level-up (achievable from ~2-3 brews or sales) that gradually
## slows down over a long run rather than either stalling early game or
## trivializing late game.
const XP_LEVEL_BASE : int = 40
const XP_LEVEL_GROWTH_PER_LEVEL : int = 20


## preset_modifier lets the caller hand in a specific RunModifier (the
## player's pick from ModifierSelectWindow) instead of rolling a random
## one — see BrewEngine.start_new_game(). Left null for a fresh random
## roll wherever the choice doesn't apply (loading a save reconstructs
## run_modifier from the saved data instead of going through _init() at
## all — see SaveManager).
func _init(preset_modifier : RunModifier = null) -> void:
	inventory = Inventory.new()
	brew_preparation = BrewPreparation.new()
	run_modifier = preset_modifier if preset_modifier != null else RunModifierRegistry.get_random_modifier()
	resolver = BrewResolver.new()
	resolver._ready()
	resolver.ingredient_price_multiplier = run_modifier.ingredient_price_multiplier
	discovered_styles[BeerStyle.Style.KOTIKALJA] = true

	# Zero-click first-brew hint: Kotikalja is known from the start without
	# ever being brewed, so it never goes through discover_style()'s
	# default-recipe seeding below — seed it here instead.
	var kotikalja_recipe : BrewRecipe = _ensure_default_recipe(resolver.get_beer_style(BeerStyle.Style.KOTIKALJA))
	if kotikalja_recipe != null:
		brew_preparation.active_recipe_target = kotikalja_recipe.ingredient_amounts.duplicate()
		brew_preparation.active_recipe_style_name = BeerStyle.get_style_string_from_style(kotikalja_recipe.beer_style)


func is_style_known(style : BeerStyle.Style) -> bool:
	return BrewEngine.is_developer_mode() or discovered_styles.has(style)


func tutorial_complete() -> bool:
	return lifetime_malt_kg_bought >= TUTORIAL_MALT_TARGET_KG and tutorial_bought_yeast and tutorial_brewed_kotikalja


func discover_style(style : BeerStyle.Style) -> void:
	if discovered_styles.has(style):
		return

	discovered_styles[style] = true
	_ensure_default_recipe(resolver.get_beer_style(style))
	BrewerySignals.style_discovered.emit(style)


## Guarantees every unlocked style has at least one saved recipe showing
## its bare-minimum valid ingredients, even for styles unlocked without
## ever being brewed (Kotikalja) or where the player's own brew used more
## than the minimum. Idempotent — returns the existing default recipe
## if this style already has one instead of adding a duplicate.
func _ensure_default_recipe(beer_style : BeerStyle) -> BrewRecipe:
	if beer_style == null:
		return null

	for existing : BrewRecipe in saved_recipes:
		if existing.beer_style == beer_style.style and existing.is_default:
			return existing

	var ingredients : Dictionary = resolver.compute_minimum_ingredients(beer_style)
	if ingredients.is_empty():
		return null

	var recipe := BrewRecipe.new()
	recipe.beer_style = beer_style.style
	recipe.ingredient_amounts = ingredients
	recipe.recipe_name = "%s (perusresepti)" % beer_style.style_name
	recipe.is_default = true

	saved_recipes.append(recipe)
	BrewerySignals.brewery_state_changed.emit(self)
	BrewerySignals.recipe_saved.emit(recipe.recipe_name)

	return recipe


func add_risk(amount : int) -> void:
	risk = max(0, risk + amount)
	_check_for_avi_raid()


func clear_risk() -> void:
	risk = 0


## Pure and static so the curve itself is directly unit-testable without
## constructing a Brewery (which needs live autoloads — see _init()) —
## same reasoning as BrewResolver.calculate_price_breakdown().
static func xp_required_for_level(level : int) -> int:
	return XP_LEVEL_BASE + (level - 1) * XP_LEVEL_GROWTH_PER_LEVEL


## Central XP/leveling math for both brewing (start_brew()) and selling
## (CustomerManager.process_auto_sale()) — those two call sites emit
## their own popup-facing signal (brew_xp_gained/sale_xp_gained) with the
## same raw amount they pass in here, since each knows exactly where its
## own popup should appear (a fixed button vs. a customer's position) and
## this method has no business knowing either. A while loop (not an if)
## so a single large XP grant can still only ever cross one level at a
## time in practice, but won't get stuck mid-level-up if it somehow
## crossed two thresholds at once. Each level gained fires its own
## BrewerySignals.level_up_reached so LevelUpWindow shows one perk choice
## per level, never silently skipping one.
func add_xp(amount : int) -> void:
	if amount <= 0:
		return

	run_xp += amount
	while run_xp >= xp_required_for_level(run_level):
		run_xp -= xp_required_for_level(run_level)
		run_level += 1
		BrewerySignals.level_up_reached.emit(run_level)

	BrewerySignals.brewery_state_changed.emit(self)


## Called by LevelUpWindow once the player picks one of PerkRegistry's
## rolled choices. Perks only ever accumulate — see RunPerk's own
## docstring for why repeats are fine and expected.
func apply_perk(perk : RunPerk) -> void:
	active_perks.append(perk)
	BrewerySignals.brewery_state_changed.emit(self)


func get_quality_bonus() -> float:
	var total : float = 0.0
	for perk : RunPerk in active_perks:
		total += perk.quality_bonus
	return total


func get_reputation_gain_multiplier() -> float:
	var multiplier : float = 1.0
	for perk : RunPerk in active_perks:
		multiplier *= perk.reputation_gain_multiplier
	return multiplier


func get_tip_income_multiplier() -> float:
	var multiplier : float = 1.0
	for perk : RunPerk in active_perks:
		multiplier *= perk.tip_income_multiplier
	return multiplier


## AVI_RAID_THRESHOLD scaled by this run's modifier — see RunModifier.
## avi_threshold_multiplier. Kept separate from the raw constant since that
## constant is also read by call sites with no Brewery instance in scope
## (audio_manager.gd's ambient tension scaling, the dev console's "raid"
## cheat) — both of those now call this instead so they stay accurate
## under any modifier.
func get_effective_raid_threshold() -> int:
	return roundi(AVI_RAID_THRESHOLD * run_modifier.avi_threshold_multiplier)


func _check_for_avi_raid() -> void:
	if risk < get_effective_raid_threshold():
		return

	var confiscated_bottles : int = _count_total_bottles()
	inventory.brew_batches.clear()

	var fine_amount : float = snappedf(money * AVI_RAID_FINE_PERCENT, 0.1)
	var reputation_penalty : int = roundi(reputation * AVI_RAID_REPUTATION_PENALTY_PERCENT)

	money -= fine_amount
	reputation = max(0, reputation - reputation_penalty)
	risk = 0
	raid_count += 1

	BrewerySignals.avi_raid_triggered.emit(confiscated_bottles, fine_amount, reputation_penalty)
	BrewerySignals.brewery_state_changed.emit(self)

	if raid_count >= BUSTED_RAID_COUNT:
		trigger_ending("busted")
		return

	check_bankruptcy()


func _count_total_bottles() -> int:
	var total : int = 0

	for batch : BrewBatch in inventory.brew_batches:
		total += batch.amount_bottles

	return total


## Called after anything that can push money to (or toward) zero — the
## AVI fine above, a purchase, or the daily utility bill
## (TimeManager._charge_daily_utility_bills) — since any of those can be
## the final straw. A truly dead end: no cash AND nothing left to sell
## that could raise any.
func check_bankruptcy() -> void:
	if money > 0.0 or _count_total_bottles() > 0:
		return
	trigger_ending("bankrupt")


## Latches game_has_ended so only the first ending condition met in a run
## actually fires — see that flag's own docstring. ending_type is one of
## "busted", "bankrupt", "survived"; GameEndWindow reads it to pick the
## right title/flavor text.
func trigger_ending(ending_type : String) -> void:
	if game_has_ended:
		return
	game_has_ended = true
	BrewerySignals.game_ended.emit(ending_type)


func _ready() -> void:
	# Re-sync in case run_modifier was overwritten after _init() ran (e.g.
	# ResourceLoader loading a save: _init() always rolls/receives a
	# run_modifier first, then the loader applies the saved @export value
	# on top of it — resolver isn't @export, so without this line it would
	# keep pricing by whatever run_modifier happened to be current at
	# construction time instead of the one actually loaded).
	resolver.ingredient_price_multiplier = run_modifier.ingredient_price_multiplier

	GUISignals.add_ingredient_to_brew_preparation.connect(_on_add_ingredient_to_brew_preparation)
	GUISignals.remove_ingredients_from_brew_preparation.connect(_on_remove_ingredient_from_brew_preparation)
	GUISignals.buy_ingredient.connect(_on_buy_ingredient)
	GUISignals.sell_ingredient.connect(_on_sell_ingredient)
	GUISignals.start_brewing.connect(start_brew)
	GUISignals.save_recipe_requested.connect(_on_save_recipe_requested)
	GUISignals.load_recipe_requested.connect(_on_load_recipe_requested)
	GUISignals.clear_brew_preparation_requested.connect(_on_clear_brew_preparation_requested)


## Must be called on the outgoing Brewery before BrewEngine.current_brewery
## is replaced (new game, load game) — otherwise the old instance stays
## connected to GUISignals forever (Godot keeps it alive via the signal
## connection) and silently keeps handling player actions instead of the
## one actually shown on screen.
func disconnect_signals() -> void:
	GUISignals.add_ingredient_to_brew_preparation.disconnect(_on_add_ingredient_to_brew_preparation)
	GUISignals.remove_ingredients_from_brew_preparation.disconnect(_on_remove_ingredient_from_brew_preparation)
	GUISignals.buy_ingredient.disconnect(_on_buy_ingredient)
	GUISignals.sell_ingredient.disconnect(_on_sell_ingredient)
	GUISignals.start_brewing.disconnect(start_brew)
	GUISignals.save_recipe_requested.disconnect(_on_save_recipe_requested)
	GUISignals.load_recipe_requested.disconnect(_on_load_recipe_requested)
	GUISignals.clear_brew_preparation_requested.disconnect(_on_clear_brew_preparation_requested)


func emit_initial_values() -> void:
	BrewerySignals.brewery_state_changed.emit(self)


func _on_add_ingredient_to_brew_preparation(ingredient_id : int, amount : int) -> void:
	var final_amount : int =  inventory.withdraw_item_by_id(ingredient_id, amount)
	
	if final_amount <= 0:
		return
	
	brew_preparation.add_to_table(ingredient_id, final_amount)
	BrewerySignals.brewery_state_changed.emit(self)


func _on_remove_ingredient_from_brew_preparation(ingredient_id : int, amount : int) -> void:
	var exact_amount : int = brew_preparation.remove_from_table(ingredient_id, amount)
	inventory.add_amount_by_id(ingredient_id, exact_amount)
	BrewerySignals.brewery_state_changed.emit(self)


func _on_buy_ingredient(ingredient_id : int, amount : int) -> void:
	var ingredient: IngredientData = IngredientDatabase.get_item_by_id(ingredient_id)
	if ingredient == null:
		return

	if reputation < ingredient.min_reputation:
		print(StringContainer.INGREDIENT_LOCKED_ERROR % [ingredient.name, ingredient.min_reputation])
		return

	var buy_price : int = roundi(ingredient.base_price * amount * run_modifier.ingredient_price_multiplier)

	if money < buy_price:
		print(StringContainer.RESOURCE_ERROR % [money, buy_price, StringContainer.MONEY_STRING])
		return

	money -= buy_price
	inventory.add_amount(ingredient, amount)
	_track_tutorial_purchase(ingredient, amount)
	BrewerySignals.ingredient_purchased.emit(buy_price)
	BrewerySignals.brewery_state_changed.emit(self)
	check_bankruptcy()


func _track_tutorial_purchase(ingredient : IngredientData, amount : int) -> void:
	if ingredient.type == IngredientData.IngredientType.MALT:
		lifetime_malt_kg_bought += amount
		return

	var kotikalja : BeerStyle = resolver.get_beer_style(BeerStyle.Style.KOTIKALJA)
	if kotikalja != null and ingredient.id == kotikalja.required_yeast_id:
		tutorial_bought_yeast = true


func _on_sell_ingredient(ingredient_id : int, amount : int) -> void:
	var ingredient: IngredientData = IngredientDatabase.get_item_by_id(ingredient_id)
	if ingredient == null:
		return
	
	var final_amount : int = inventory.withdraw_item_by_id(ingredient_id, amount)
	
	if final_amount <= 0:
		return
		
	var sell_price : float = snappedf(final_amount * ingredient.base_price * run_modifier.ingredient_price_multiplier * 0.75, 0.1)
	money += sell_price #ei saa ihan samaa hintaa takas millä joskus osti...
	print(StringContainer.SELL_MESSAGE % [final_amount, sell_price])
	BrewerySignals.brewery_state_changed.emit(self)


func _on_save_recipe_requested() -> void:
	if brew_preparation.selected_contents.is_empty():
		return

	var preview : BrewResult = resolver.resolve_brew_style(brew_preparation.selected_contents)
	if preview == null:
		return

	# Don't let the player name-peek an undiscovered style just by saving the
	# recipe — that would spoil the "brew it to find out" surprise. Styles
	# save themselves automatically the moment they're actually discovered.
	if not is_style_known(preview.beer_style.style):
		BrewerySignals.recipe_save_rejected.emit()
		return

	_save_recipe(preview.beer_style, brew_preparation.selected_contents.duplicate())


func _save_recipe(beer_style : BeerStyle, ingredient_amounts : Dictionary) -> void:
	var recipe := BrewRecipe.new()
	recipe.beer_style = beer_style.style
	recipe.ingredient_amounts = ingredient_amounts

	var existing_count : int = 0
	for other_recipe : BrewRecipe in saved_recipes:
		if other_recipe.beer_style == recipe.beer_style:
			existing_count += 1

	recipe.recipe_name = "%s #%d" % [beer_style.style_name, existing_count + 1]

	saved_recipes.append(recipe)
	BrewerySignals.brewery_state_changed.emit(self)
	BrewerySignals.recipe_saved.emit(recipe.recipe_name)


## Clears whatever's currently on the brewing table, refunding it to
## inventory first — used by the brew preparation panel's erase button.
func _on_clear_brew_preparation_requested() -> void:
	for ingredient_id : int in brew_preparation.selected_contents:
		var amount : int = brew_preparation.selected_contents[ingredient_id]
		inventory.add_amount_by_id(ingredient_id, amount)

	brew_preparation.clear_preparation()
	BrewerySignals.brewery_state_changed.emit(self)


func _on_load_recipe_requested(recipe : BrewRecipe) -> void:
	if recipe == null:
		return

	brew_preparation.active_recipe_target = recipe.ingredient_amounts.duplicate()
	brew_preparation.active_recipe_style_name = BeerStyle.get_style_string_from_style(recipe.beer_style)

	for ingredient_id : int in recipe.ingredient_amounts:
		var wanted : int = recipe.ingredient_amounts[ingredient_id]
		var item : InventoryItem = inventory.get_item_by_id(ingredient_id)
		var available : int = item.amount if item else 0
		var withdrawn : int = inventory.withdraw_item_by_id(ingredient_id, min(wanted, available))

		if withdrawn > 0:
			brew_preparation.add_to_table(ingredient_id, withdrawn)

	BrewerySignals.brewery_state_changed.emit(self)


## Bottling always costs something, win or lose (even a failed/kotikalja
## fallback batch still gets bottled, and a dev-conjured test batch is no
## exception either — see dev_console.gd's "sell" command) — a slice of
## the raw yield breaks or spills (BrewResolver.BOTTLE_LOSS_RATE), and
## every bottle produced needs a printed label
## (BrewResolver.LABEL_ART_COST_PER_BOTTLE), paid up front here regardless
## of whether the batch ends up profitable to sell. Shared by start_brew()
## and dev_console._ensure_batch_stock() so both charge identically
## instead of the dev shortcut producing bottles for free.
func apply_bottling_costs(raw_yield : int) -> Dictionary:
	var effective_yield : int = BrewResolver.get_effective_bottle_yield(raw_yield)
	var bottles_lost : int = raw_yield - effective_yield
	var label_cost : float = snappedf(raw_yield * BrewResolver.LABEL_ART_COST_PER_BOTTLE, 0.1)
	money -= label_cost

	return {
		"effective_yield": effective_yield,
		"bottles_lost": bottles_lost,
		"label_cost": label_cost,
	}


func start_brew() -> void:
	if brew_preparation.selected_contents.is_empty():
		print(StringContainer.TABLE_EMPTY_ERROR)
		return
	
	var brew_report : BrewResult = resolver.resolve_brew_style(brew_preparation.selected_contents)
	
	if brew_report == null:
		brew_preparation.clear_preparation()
		BrewerySignals.brewery_state_changed.emit(self)
		return

	var bottling : Dictionary = apply_bottling_costs(brew_report.bottle_yield)
	var effective_yield : int = bottling.effective_yield
	var bottles_lost : int = bottling.bottles_lost
	var label_cost : float = bottling.label_cost

	var new_batch := BrewBatch.new()
	new_batch.beer_style = brew_report.beer_style
	new_batch.amount_bottles = effective_yield
	new_batch.original_quality = brew_report.original_quality + get_quality_bonus()
	new_batch.current_quality = new_batch.original_quality
	new_batch.final_ebc = brew_report.final_ebc
	new_batch.final_ibu = brew_report.final_ibu
	new_batch.precision_score = brew_report.precision_score
	new_batch.hop_diversity_count = brew_report.hop_diversity_count
	new_batch.hop_balance_bonus = brew_report.hop_balance_bonus
	new_batch.flavor_matched = brew_report.flavor_matched

	inventory.brew_batches.append(new_batch)

	if brew_report.is_matched:
		var is_new_discovery : bool = not discovered_styles.has(brew_report.beer_style.style)
		discover_style(brew_report.beer_style.style)
		if is_new_discovery:
			_save_recipe(brew_report.beer_style, brew_preparation.selected_contents.duplicate())
		if brew_report.beer_style.style == BeerStyle.Style.KOTIKALJA:
			tutorial_brewed_kotikalja = true
		BrewerySignals.beer_brewed.emit(brew_report.beer_style.style)

		var brew_xp : int = XP_PER_SUCCESSFUL_BREW
		if is_new_discovery:
			brew_xp += XP_PER_NEW_STYLE_DISCOVERY_BONUS
		add_xp(brew_xp)
		BrewerySignals.brew_xp_gained.emit(brew_xp)

	brew_preparation.clear_preparation()
	print(StringContainer.SUCCESFULL_BREW_MESSAGE, BeerStyle.get_style_string_from_style(brew_report.beer_style.style))
	BrewerySignals.batch_bottled.emit(bottles_lost, label_cost, brew_report.beer_style.style_name)
	BrewerySignals.brewery_state_changed.emit(self)
