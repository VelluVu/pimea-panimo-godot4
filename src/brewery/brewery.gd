class_name Brewery
extends Resource


const LVV_RAID_THRESHOLD : int = 100
## Reputation needed for the "survived" ending, so scraping through the last
## day on the ropes doesn't read as a win. Set above the rarer-customer tier
## (CustomerData.min_reputation_to_appear = 70) to take sustained reputation.
const SURVIVAL_MIN_REPUTATION : int = 100

const TUTORIAL_MALT_TARGET_KG : int = 3

const XP_PER_SUCCESSFUL_BREW : int = 20
const XP_PER_NEW_STYLE_DISCOVERY_BONUS : int = 20
const XP_PER_BOTTLE_SOLD : int = 3
## Level n needs BASE + (n - 1) * GROWTH xp: a quick first level-up that
## slows steadily over a long run.
const XP_LEVEL_BASE : int = 40
const XP_LEVEL_GROWTH_PER_LEVEL : int = 20


## Which SaveWiring.SAVE_VERSION wrote this brewery; 0 for saves that
## predate versioning.
@export var save_version : int = 0
@export var inventory : Inventory
@export var current_day : int = 1
## Never resets; only feeds the end-of-run summary.
@export var lifetime_bottles_sold : int = 0

## The active daily goals and their progress, index-aligned with
## DailyGoalManager's slots. DailyGoalManager owns the logic and writes these
## just before a save so they survive a load.
@export var active_daily_goals : Array[DailyGoalData] = [null, null, null]
@export var daily_goal_progress : Array[int] = [0, 0, 0]
@export var daily_goal_reputation_baseline : Array[int] = [0, 0, 0]
@export var daily_goal_effective_target : Array[int] = [0, 0, 0]
## Daily goals rolled today, against GoalWiring.DAILY_GOAL_ROLLS.
@export var daily_goal_rolls_used : int = 0

## Snapshot of the day timer, written before each save. -1.0 means the clock
## has not started. Without it a load restarts the full day, so quitting and
## continuing near day's end refunded the rest of it.
@export var day_time_remaining_seconds : float = -1.0
## Amounts are snapped to 0.1 (beer prices are not whole euros). The 20 EUR
## start clears the 8 EUR tutorial recipe with little room, keeping the early
## bankruptcy risk real.
@export var money: float = 20.0
@export var risk: int = 0
@export var reputation: int = 0
## LVV raids survived this run. Never resets.
@export var raid_count : int = 0
## Times the player closed the day manually. Never resets.
@export var early_closes_count : int = 0
## Latched by trigger_ending() so two endings met on the same tick cannot both
## fire. Not saved: the end screen blocks play, and continuing clears it.
var game_has_ended : bool = false
## Set when the player picks "Jatka pelaamista" after the season ending, so it
## never fires again. The run is already scored: nothing after it reaches the
## leaderboard, and each night pays only reduced renown (RunScore).
@export var has_continued_past_survival : bool = false
## lifetime_bottles_sold already paid out in renown, for continued play's nightly renown.
@export var renown_bottles_counted : int = 0
@export var run_xp : int = 0
@export var run_level : int = 1
@export var active_perks : Array[RunPerk] = []
@export var brew_preparation : BrewPreparation
@export var saved_recipes : Array[BrewRecipe] = []
@export var discovered_styles : Dictionary = {} # Avain: BeerStyle.Style -> Arvo: true
## Styles brewed this run. Unlike discovered_styles it is not seeded from earlier
## runs, so each run's first brew of a style can still earn reputation.
@export var brewed_styles : Dictionary = {} # BeerStyle.Style -> true
## How each customer type (CustomerData.title) has been treated this run, see RegularRules.
@export var customer_standing : Dictionary = {} # String -> int
## Cellar upgrades bought this run, see CellarUpgradeShop.
@export var cellar_upgrade_levels : Dictionary = {} # CellarUpgradeData.upgrade_id -> level

## First-brew tutorial progress. One-way latches, so a step stays done after
## its ingredients are used up. tutorial_complete() derives from these.
@export var lifetime_malt_kg_bought : int = 0
@export var tutorial_bought_yeast : bool = false
@export var tutorial_brewed_kotikalja : bool = false

## Runtime only, not saved.
var resolver : BrewResolver = null
## The tier last toasted, see ReputationTiers.announced_tier(). Runtime only: after a
## load it starts from the current tier.
var _announced_tier : ReputationTier = null

## Today's sales for the receipt log window; cleared each day, not saved.
var today_sale_receipts : Array[SaleReceiptEntry] = []

## Effective perk and cellar upgrade numbers, see PerkStats. Rebuilt on each
## access because a loaded save replaces active_perks wholesale.
var stats : PerkStats:
	get:
		var perks : Array[RunPerk] = active_perks.duplicate()
		perks.append_array(CellarUpgrades.perks_for(cellar_upgrade_levels, CellarUpgrades.all()))
		return PerkStats.new(perks)

## Services holding the Brewery's behaviour. They connect their own GUISignals
## handlers in _ready() and release them in disconnect_signals().
var _services : Array = []


## Godot also calls _init() when loading a save, then overwrites the exported fields.
func _init() -> void:
	inventory = Inventory.new()
	brew_preparation = BrewPreparation.new()
	resolver = BrewResolver.new()
	resolver._ready()
	resolver.ingredient_price_multiplier = stats.multiplier(PerkStats.INGREDIENT_PRICE)
	discovered_styles[BeerStyle.Style.KOTIKALJA] = true

	# Kotikalja is known from the start, so it never goes through
	# discover_style() and needs its default recipe seeded here.
	var discovery := StyleDiscovery.new(self)
	var kotikalja_recipe : BrewRecipe = discovery.ensure_default_recipe(resolver.get_beer_style(BeerStyle.Style.KOTIKALJA), false)
	if kotikalja_recipe != null:
		brew_preparation.active_recipe_target = kotikalja_recipe.ingredient_amounts.duplicate()
		brew_preparation.active_recipe_style_name = BeerStyle.get_style_string_from_style(kotikalja_recipe.beer_style)

	discovery.seed_from_meta()
	_seed_meta_perks()


func _seed_meta_perks() -> void:
	# Null while BrewEngine builds its boot-time Brewery, before this autoload exists.
	if MetaProgressManager == null:
		return
	for perk : RunPerk in MetaProgressManager.get_active_perks():
		active_perks.append(perk)


func is_style_known(style : BeerStyle.Style) -> bool:
	return BrewEngine.is_developer_mode() or discovered_styles.has(style)


func tutorial_complete() -> bool:
	return lifetime_malt_kg_bought >= TUTORIAL_MALT_TARGET_KG and tutorial_bought_yeast and tutorial_brewed_kotikalja


func skip_tutorial() -> void:
	lifetime_malt_kg_bought = TUTORIAL_MALT_TARGET_KG
	tutorial_bought_yeast = true
	tutorial_brewed_kotikalja = true


func add_risk(amount : int) -> void:
	risk = max(0, risk + amount)
	InspectionService.new(self).check_for_raid()


## Gains shrink as reputation grows (ReputationRules); losses apply in full.
## Returns the change actually applied. `source` feeds the day recap's breakdown.
func change_reputation(amount : int, source : ReputationRules.Source = ReputationRules.Source.OTHER) -> int:
	var before : int = reputation
	reputation = ReputationRules.apply(reputation, amount)
	var applied : int = reputation - before
	if applied != 0:
		BrewerySignals.reputation_changed.emit(applied, source)

	var tiers : Array[ReputationTier] = ReputationTiers.all()
	if _announced_tier == null:
		_announced_tier = ReputationTiers.tier_for(before, tiers)
	var tier : ReputationTier = ReputationTiers.announced_tier(_announced_tier, reputation, tiers)
	if tier != null and tier != _announced_tier:
		BrewerySignals.reputation_tier_changed.emit(tier, tier.min_reputation > _announced_tier.min_reputation)
	_announced_tier = tier
	return applied


## Static so the curve can be unit-tested without a live Brewery.
static func xp_required_for_level(level : int) -> int:
	return XP_LEVEL_BASE + (level - 1) * XP_LEVEL_GROWTH_PER_LEVEL


## A while loop so one large grant that crosses several thresholds still
## fires one level_up_reached (and one perk choice) per level.
func add_xp(amount : int) -> void:
	if amount <= 0:
		return

	run_xp += amount
	while run_xp >= xp_required_for_level(run_level):
		run_xp -= xp_required_for_level(run_level)
		run_level += 1
		BrewerySignals.level_up_reached.emit(run_level)

	BrewerySignals.brewery_state_changed.emit(self)


func apply_perk(perk : RunPerk) -> void:
	active_perks.append(perk)
	BrewerySignals.brewery_state_changed.emit(self)


## The raid threshold after this run's modifier and perks.
func get_effective_raid_threshold() -> int:
	return ReputationRules.raid_threshold(stats.raid_threshold(LVV_RAID_THRESHOLD), get_reputation_tier())


func get_reputation_tier() -> ReputationTier:
	return ReputationTiers.tier_for(reputation, ReputationTiers.all())


## Call after anything that can drain money. See BankruptcyRules: a run ends only
## when no known recipe can be brewed any more.
func check_bankruptcy() -> void:
	if money > 0.0 or inventory.count_bottles() > 0:
		return

	var recipes : Array[Dictionary] = []
	for recipe : BrewRecipe in saved_recipes:
		recipes.append(recipe.ingredient_amounts)
	var price_multiplier : float = stats.multiplier(PerkStats.INGREDIENT_PRICE)
	var buy_prices : Dictionary = {}
	var sell_prices : Dictionary = {}
	for id : int in IngredientDatabase.database:
		var ingredient : IngredientData = IngredientDatabase.database[id]
		var price : float = ingredient.base_price * price_multiplier
		sell_prices[id] = price * IngredientTrader.SELL_BACK_RATE
		if reputation >= ingredient.min_reputation:
			buy_prices[id] = price

	if BankruptcyRules.is_bankrupt(money, 0, _owned_ingredient_amounts(), recipes, buy_prices, sell_prices):
		trigger_ending("bankrupt")


## Storage plus what is on the brewing table, id -> amount.
func _owned_ingredient_amounts() -> Dictionary:
	var owned : Dictionary = brew_preparation.selected_contents.duplicate()
	for type_items : Dictionary in inventory.items.values():
		for id : int in type_items:
			owned[id] = owned.get(id, 0) + (type_items[id] as InventoryItem).amount
	return owned


## ending_type is "busted", "bankrupt", "survived" or "season_over"; only the first fires.
func trigger_ending(ending_type : String) -> void:
	if game_has_ended:
		return
	game_has_ended = true
	BrewerySignals.game_ended.emit(ending_type)


func _ready() -> void:
	# A loaded save replaces active_perks after _init(), and the resolver is
	# not saved, so its pricing has to be re-synced here.
	resolver.ingredient_price_multiplier = stats.multiplier(PerkStats.INGREDIENT_PRICE)

	_services = [RecipeBook.new(self), IngredientTrader.new(self), BatchDistributor.new(self), Brewer.new(self), CellarUpgradeShop.new(self)]
	for service : Variant in _services:
		service.connect_signals()


## Call on the outgoing Brewery before BrewEngine replaces it, otherwise it
## stays connected to GUISignals and keeps handling player actions.
func disconnect_signals() -> void:
	for service : Variant in _services:
		service.disconnect_signals()
	_services.clear()


func emit_initial_values() -> void:
	BrewerySignals.brewery_state_changed.emit(self)
