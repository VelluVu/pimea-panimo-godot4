class_name Brewery
extends Resource


const LVV_RAID_THRESHOLD : int = 100
## Reputation the "survived" ending needs, above the rarer customers' 70, so scraping
## through the last day does not read as a win.
const SURVIVAL_MIN_REPUTATION : int = 100

const TUTORIAL_MALT_TARGET_KG : int = 3
## LVV warnings, once a season each, well before the raid: a hint explaining the risk,
## then the inspector walking in to look around.
const LVV_HINT_RISK : int = 30
const LVV_INSPECTOR_VISIT_RISK : int = 45

const XP_PER_SUCCESSFUL_BREW : int = 20
const XP_PER_NEW_STYLE_DISCOVERY_BONUS : int = 20
const XP_PER_BOTTLE_SOLD : int = 3
## Level n needs BASE + (n - 1) * GROWTH xp: a quick first level, slower after.
const XP_LEVEL_BASE : int = 40
const XP_LEVEL_GROWTH_PER_LEVEL : int = 20


## The SaveWiring.SAVE_VERSION that wrote this brewery; 0 before versioning.
@export var save_version : int = 0
@export var inventory : Inventory
@export var current_day : int = 1
## Never resets; only feeds the end-of-run summary.
@export var lifetime_bottles_sold : int = 0

## The daily goals and their progress, index-aligned with DailyGoalManager's slots, which
## writes them before a save.
@export var active_daily_goals : Array[DailyGoalData] = [null, null, null]
@export var daily_goal_progress : Array[int] = [0, 0, 0]
@export var daily_goal_reputation_baseline : Array[int] = [0, 0, 0]
@export var daily_goal_effective_target : Array[int] = [0, 0, 0]
## Daily goals rolled today, against GoalWiring.DAILY_GOAL_ROLLS.
@export var daily_goal_rolls_used : int = 0

## The day timer's time left, written before each save; -1.0 = not started. Without it a
## load restarted the full day.
@export var day_time_remaining_seconds : float = -1.0
## Snapped to 0.1. The 20 EUR start just clears the 8 EUR tutorial recipe, so early
## bankruptcy stays a real risk.
@export var money: float = 20.0
## Customers and crowds in the cellar at the save, each frozen mid-visit, so continuing
## picks every visit up where it was (CustomerSpawner).
@export var cellar_customers : Array[CustomerSnapshot] = []
@export var cellar_groups : Array[GroupVisitSnapshot] = []
## Walk-ins already on their way (a recommended friend, a walk-in's company): each
## {"data": CustomerData or null for a random one, "seconds": float until they come in}.
@export var scheduled_walk_ins : Array[Dictionary] = []
@export var lvv_raid : LvvRaidSnapshot
@export var open_special_events : Array[SpecialEventSnapshot] = []
## Seconds left on the cellar's clocks at the save (-1 = not running), so the next walk-in,
## crowd and special event come when they would have.
@export var walk_in_time_left : float = -1.0
@export var group_visit_time_left : float = -1.0
@export var special_event_time_left : float = -1.0
## Today's money per MoneyLedger.Source, and the net of the last days (oldest first).
@export var money_today : Dictionary = {}
@export var money_recent_days : Array[float] = []
@export var risk: int = 0
@export var reputation: int = 0
## LVV raids survived this run. Never resets.
@export var raid_count : int = 0
## Times the player closed the day manually. Never resets.
@export var early_closes_count : int = 0
## Latched so two endings on the same tick cannot both fire. Not saved: the end screen
## blocks play, and continuing clears it.
var game_has_ended : bool = false
## Set by "Jatka pelaamista" after the season ending. The run is already scored; each later
## night pays only reduced renown (RunScore).
@export var has_continued_past_survival : bool = false
## lifetime_bottles_sold already paid out in renown, for continued play's nightly renown.
@export var renown_bottles_counted : int = 0
@export var run_xp : int = 0
@export var run_level : int = 1
@export var active_perks : Array[RunPerk] = []
@export var brew_preparation : BrewPreparation
@export var saved_recipes : Array[BrewRecipe] = []
@export var discovered_styles : Dictionary = {} # BeerStyle.Style -> true
## Styles brewed this run. Unlike discovered_styles it is not seeded from earlier
## runs, so each run's first brew of a style can still earn reputation.
@export var brewed_styles : Dictionary = {} # BeerStyle.Style -> true
## How each customer type (CustomerData.title) has been treated this run, see RegularRules.
@export var customer_standing : Dictionary = {} # String -> int
## Cellar upgrades bought this run, see CellarUpgradeShop.
@export var cellar_upgrade_levels : Dictionary = {} # CellarUpgradeData.upgrade_id -> level
## Machines bought in an earlier season and switched off by the player, see CellarMachines.
@export var owned_machines : Array[String] = []
@export var machines_off : Array[String] = []

## First-brew tutorial progress. One-way latches, so a step stays done after
## its ingredients are used up. tutorial_complete() derives from these.
@export var lifetime_malt_kg_bought : int = 0
@export var tutorial_bought_yeast : bool = false
@export var tutorial_brewed_kotikalja : bool = false
## Set by the run's first brew, which skips fermentation, see FermentationRules.duration().
@export var has_brewed : bool = false
## Parts of Aatu's tutorial seen through or skipped in this run (GuideParts.Part).
@export var guide_parts_done : Array[int] = []
## The Don's protection (ProtectionEventData): no Agentti walks in before this day, and
## Mafioso walk-ins weigh mafioso_cut_multiplier before mafioso_cut_until_day.
@export var agentti_free_until_day : int = 0
@export var mafioso_cut_until_day : int = 0
@export var mafioso_cut_multiplier : float = 1.0
## Styles the old master has told about (StyleHintEventData): their exact EBC and IBU
## show in the recipe library before discovery. BeerStyle.Style -> true.
@export var hinted_styles : Dictionary = {}
## The cellar cat stays for the season once adopted (AdoptionEventData).
@export var cellar_cat_adopted : bool = false
## One-way latches for the LVV warnings, see LVV_HINT_RISK.
@export var lvv_hint_shown : bool = false
@export var lvv_inspector_visited : bool = false

## Runtime only, not saved.
var resolver : BrewResolver = null
## The tier last toasted (ReputationTiers.announced_tier()); runtime only.
var _announced_tier : ReputationTier = null

## Today's sales for the receipt log window; cleared each day, not saved.
var today_sale_receipts : Array[SaleReceiptEntry] = []

## Effective perk and upgrade numbers (PerkStats), rebuilt on each access since a load
## replaces active_perks.
var stats : PerkStats:
	get:
		var perks : Array[RunPerk] = active_perks.duplicate()
		perks.append_array(CellarUpgrades.perks_for(cellar_upgrade_levels, CellarUpgrades.all()))
		return PerkStats.new(perks)

## The services that hold the Brewery's behaviour, each with its own GUISignals handlers.
var _services : Array = []


## Godot also calls _init() when loading a save, then overwrites the exported fields.
func _init() -> void:
	inventory = Inventory.new()
	brew_preparation = BrewPreparation.new()
	resolver = BrewResolver.new()
	resolver._ready()
	resolver.ingredient_price_multiplier = stats.multiplier(PerkStats.INGREDIENT_PRICE)
	discovered_styles[BeerStyle.Style.KOTIKALJA] = true

	# Kotikalja is known from the start, so its default recipe is seeded here.
	var discovery := StyleDiscovery.new(self)
	var kotikalja_recipe : BrewRecipe = discovery.ensure_default_recipe(resolver.get_beer_style(BeerStyle.Style.KOTIKALJA), false)
	if kotikalja_recipe != null:
		brew_preparation.active_recipe_target = kotikalja_recipe.ingredient_amounts.duplicate()
		brew_preparation.active_recipe_style_name = BeerStyle.get_style_string_from_style(kotikalja_recipe.beer_style)
	for beer_style : BeerStyle in resolver.active_styles:
		if beer_style.known_from_start:
			discovered_styles[beer_style.style] = true
			discovery.ensure_default_recipe(beer_style, false)

	discovery.seed_from_meta()
	_seed_meta_perks()
	_seed_meta_machines()


func _seed_meta_machines() -> void:
	if MetaProgressManager == null:
		return
	owned_machines.assign(MetaProgressManager.get_owned_machines())
	machines_off.assign(MetaProgressManager.get_machines_off())


func owns_machine(upgrade_id : String) -> bool:
	return CellarMachines.is_owned(upgrade_id, cellar_upgrade_levels, owned_machines)


func machine_active(upgrade_id : String) -> bool:
	return CellarMachines.is_active(upgrade_id, cellar_upgrade_levels, owned_machines, machines_off)


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
	# After the raid check: a raid empties the risk, so no warning lands on top of it.
	InspectionService.new(self).check_for_raid()
	_check_lvv_warnings()


func _check_lvv_warnings() -> void:
	if not lvv_hint_shown and risk >= LVV_HINT_RISK:
		lvv_hint_shown = true
		BrewerySignals.lvv_hint_reached.emit()
	# Asked again on every rise until the inspector gets in (CustomerSpawner sets the latch).
	if not lvv_inspector_visited and risk >= LVV_INSPECTOR_VISIT_RISK:
		BrewerySignals.lvv_inspector_visit_due.emit(self)


## Every change of money goes through here, so the money tooltip can tell where it went.
func change_money(amount : float, source : MoneyLedger.Source) -> void:
	money += amount
	MoneyLedger.record(money_today, source, amount)


## Called after the night's bills, which still count for the day that ends.
func close_money_day() -> void:
	money_recent_days = MoneyLedger.closed_day(money_today, money_recent_days)
	money_today = {}


## Gains shrink as reputation grows (ReputationRules); losses apply in full. Returns the
## change applied; `source` is for the day recap.
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


## Static for tests.
static func xp_required_for_level(level : int) -> int:
	return XP_LEVEL_BASE + (level - 1) * XP_LEVEL_GROWTH_PER_LEVEL


## Loops so a grant crossing several levels fires level_up_reached once per level.
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
	resolver.ingredient_price_multiplier = stats.multiplier(PerkStats.INGREDIENT_PRICE)
	BrewerySignals.brewery_state_changed.emit(self)


## Kilograms of malt one brew can hold, see MashTun.
func mash_capacity_kg() -> float:
	return MashTun.capacity_kg(int(stats.total(PerkStats.EXTRA_MASH_CAPACITY)))


func get_effective_raid_threshold() -> int:
	return ReputationRules.raid_threshold(stats.raid_threshold(LVV_RAID_THRESHOLD), get_reputation_tier())


func get_reputation_tier() -> ReputationTier:
	return ReputationTiers.tier_for(reputation, ReputationTiers.all())


## Counter prices after the marketing perks and the fame of the reputation tier.
func counter_price_multiplier() -> float:
	var tier : ReputationTier = get_reputation_tier()
	return stats.multiplier(PerkStats.COUNTER_PRICE) * (1.0 + (tier.counter_price_bonus if tier != null else 0.0))


## Gaps between customers after the perks and the reputation tier's draw.
func spawn_interval_multiplier() -> float:
	var tier : ReputationTier = get_reputation_tier()
	return stats.multiplier(PerkStats.SPAWN_INTERVAL) * (1.0 - (tier.spawn_speed_bonus if tier != null else 0.0))


## Call after anything that drains money. A run ends only when no known recipe can be
## brewed (BankruptcyRules).
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

	if BankruptcyRules.is_bankrupt(money, 0, owned_ingredient_amounts(), recipes, buy_prices, sell_prices):
		trigger_ending("bankrupt")


## Storage plus what is on the brewing table, id -> amount.
func owned_ingredient_amounts() -> Dictionary:
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
	# A load replaces active_perks after _init() and the resolver is not saved, so its
	# pricing is re-synced here.
	resolver.ingredient_price_multiplier = stats.multiplier(PerkStats.INGREDIENT_PRICE)

	_services = [RecipeBook.new(self), IngredientTrader.new(self), BatchDistributor.new(self), Brewer.new(self), CellarUpgradeShop.new(self), KegWasher.new(self)]
	for service : Variant in _services:
		service.connect_signals()


## Call on the outgoing Brewery, or it keeps handling GUISignals.
func disconnect_signals() -> void:
	for service : Variant in _services:
		service.disconnect_signals()
	_services.clear()


func emit_initial_values() -> void:
	BrewerySignals.brewery_state_changed.emit(self)
