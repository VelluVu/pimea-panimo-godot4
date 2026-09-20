class_name Brewery
extends Resource


const LVV_RAID_THRESHOLD : int = 100
## A run only ends in the "survived" ending if it's not currently on the
## ropes — reaching the day target with 1 reputation and a completely
## empty warehouse shouldn't read as a triumphant ending. See
## TimeManager._advance_day(). Set well above CustomerData.
## min_reputation_to_appear's rarer-customer tier (50, e.g. Agentti/
## Mafioso) so clearing it takes real sustained reputation, not just a
## couple of lucky sales.
const SURVIVAL_MIN_REPUTATION : int = 100




@export var inventory : Inventory
@export var current_day : int = 1
## Never resets — purely a stat for the end-of-run summary screen, see
## GameEndWindow. The active daily goals themselves (what they are, and
## progress toward them) are tracked below instead, not here.
@export var lifetime_bottles_sold : int = 0
## The day's 3 active daily goals and their progress — index-aligned with
## DailyGoalManager.ACTIVE_GOAL_COUNT slots. Ownership of the actual goal
## logic (picking, tracking, resolving) still lives entirely in
## DailyGoalManager; these fields exist purely so SaveManager.save_game()
## (which only ever serializes this Brewery resource) carries that state
## along too. Previously this genuinely lived only in DailyGoalManager's
## own memory, "re-derived fresh" on every new Brewery instance — which in
## practice just meant every load silently re-rolled a fresh set and threw
## away whatever the player had been working toward. See
## DailyGoalManager._load_from_brewery()/_sync_to_brewery().
@export var active_daily_goals : Array[DailyGoalData] = [null, null, null]
@export var daily_goal_progress : Array[int] = [0, 0, 0]
@export var daily_goal_reputation_baseline : Array[int] = [0, 0, 0]
@export var daily_goal_effective_target : Array[int] = [0, 0, 0]

## Snapshot of TimeManager.day_timer.time_left, refreshed right before every
## save (TimeManager.sync_remaining_time_to_brewery(), called from
## SaveManager.save_game()) — -1.0 means the day clock hasn't started yet
## (see TimeManager._on_brewery_state_changed()'s own gating), matching a
## brand-new run or a save from before the clock's first brew. Without this,
## a loaded save always restarted the day timer at the full
## day_duration_seconds regardless of how much of the day had actually
## already been spent, letting a quit-and-continue near a day's end
## effectively refund the rest of that day for free.
@export var day_time_remaining_seconds : float = -1.0
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
## How many LVV raids this run has survived — see InspectionService.check_for_raid()
## and InspectionService.BUSTED_RAID_COUNT. Never resets.
@export var raid_count : int = 0
## How many times the player has manually closed the day this run — see
## apply_early_close_cost() and InspectionService.EARLY_CLOSE_ESCALATION_PER_CLOSE. Never
## resets; letting the day timer run out naturally never increments this.
@export var early_closes_count : int = 0
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
	resolver.ingredient_price_multiplier = stats.multiplier(PerkStats.INGREDIENT_PRICE)
	discovered_styles[BeerStyle.Style.KOTIKALJA] = true

	# Zero-click first-brew hint: Kotikalja is known from the start without
	# ever being brewed, so it never goes through discover_style()'s
	# default-recipe seeding below — seed it here instead.
	var kotikalja_recipe : BrewRecipe = _ensure_default_recipe(resolver.get_beer_style(BeerStyle.Style.KOTIKALJA), false)
	if kotikalja_recipe != null:
		brew_preparation.active_recipe_target = kotikalja_recipe.ingredient_amounts.duplicate()
		brew_preparation.active_recipe_style_name = BeerStyle.get_style_string_from_style(kotikalja_recipe.beer_style)

	_seed_meta_discovered_styles()
	_seed_meta_perks()


## Pre-seeds every style ever discovered in a past run (MetaProgressManager,
## written by discover_style() below) so a brand new run doesn't start
## knowing less than the player already does — the "cheap first step" of
## meta-progression, short of a full spendable-currency unlock tree. Not
## called with emit_state_changed (discover_style() proper handles that
## path for a genuinely new discovery) since this only ever recalls
## already-known ground, and MetaProgressManager itself already has the
## record — re-writing it here would be a no-op anyway (see its own
## has_style() guard).
##
## Harmless no-op when a save is being deserialized instead of a fresh run
## started: ResourceLoader overwrites discovered_styles/saved_recipes with
## the save's own values right after _init() returns (same ordering
## _ensure_default_recipe()'s docstring already documents for
## active_daily_goals et al.), so this pre-seeding never lingers into a
## resumed run's actual state.
##
## MetaProgressManager can be null here: BrewEngine._init() constructs a
## throwaway boot-time Brewery before every autoload listed after it
## (MetaProgressManager included) has been added to the tree yet — see
## BrewEngine.start_new_game()'s own docstring on that first instance being
## replaced. Every real "Aloita uusi peli" call happens long after full
## engine boot, where MetaProgressManager is always live.
func _seed_meta_discovered_styles() -> void:
	if MetaProgressManager == null:
		return
	for style : int in MetaProgressManager.get_discovered_styles():
		if discovered_styles.has(style):
			continue
		discovered_styles[style] = true
		_ensure_default_recipe(resolver.get_beer_style(style), false)


## Folds every renown-bought node's current level, already scaled into a
## plain RunPerk (MetaProgressManager.get_active_perks() ->
## MetaUnlockData.get_scaled_perk()), straight into active_perks so it's
## live from day 1 of this run — no separate aggregation path needed on
## top of the existing get_quality_bonus()/get_reputation_gain_multiplier()/
## get_tip_income_multiplier()/etc. Same "can be null at process-boot"
## MetaProgressManager caveat as _seed_meta_discovered_styles() above, and
## the same "overwritten by a loaded save's own active_perks right after
## _init() returns, never lingers into a resumed run" non-issue.
func _seed_meta_perks() -> void:
	if MetaProgressManager == null:
		return
	for perk : RunPerk in MetaProgressManager.get_active_perks():
		active_perks.append(perk)


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
##
## emit_state_changed defaults to true for its real runtime call site
## (discover_style(), below) but is passed false from _init()'s own call —
## _init() runs during ResourceLoader deserialization too (Godot always
## constructs the object via its script's _init() first, then applies the
## saved @export values on top), so a Brewery being loaded from a save
## briefly exists mid-construction with every other field still at its
## bare _init()-time default (current_day=1, tutorial incomplete, no daily
## goals, ...) — emitting brewery_state_changed here would broadcast that
## bogus, about-to-be-overwritten snapshot to every listener a full frame
## before SaveManager.load_game() gets to call the real
## Brewery.emit_initial_values(). DailyGoalManager's own
## _load_from_brewery() was the one that actually surfaced this: it latched
## onto that premature emission as "the loaded save's daily goals are all
## null", then treated the second, genuine emission as just an ordinary
## update on an already-tracked instance instead of a fresh load — quietly
## re-rolling a random set instead of restoring the saved one.
func _ensure_default_recipe(beer_style : BeerStyle, emit_state_changed : bool = true) -> BrewRecipe:
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
	if emit_state_changed:
		BrewerySignals.brewery_state_changed.emit(self)
	BrewerySignals.recipe_saved.emit(recipe.recipe_name)

	return recipe


func add_risk(amount : int) -> void:
	risk = max(0, risk + amount)
	InspectionService.new(self).check_for_raid()


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


## Effective perk/modifier numbers for this run — see PerkStats. Rebuilt
## per access because a loaded save replaces active_perks wholesale.
var stats : PerkStats:
	get:
		return PerkStats.new(run_modifier, active_perks)


## LVV_RAID_THRESHOLD scaled by this run's modifier and perks. Kept here
## because callers with no other Brewery need (audio_manager, dev console)
## shouldn't have to know the base constant.
func get_effective_raid_threshold() -> int:
	return stats.raid_threshold(LVV_RAID_THRESHOLD)





## Owned by the service objects below: they connect their own GUISignals
## handlers in _ready() and release them in disconnect_signals().
var recipe_book : RecipeBook
var ingredient_trader : IngredientTrader
var batch_distributor : BatchDistributor


## Kept on Brewery for TimeManager; the math lives in InspectionService.
func apply_early_close_cost(earliness : float) -> void:
	InspectionService.new(self).apply_early_close_cost(earliness)


func count_total_bottles() -> int:
	var total : int = 0

	for batch : BrewBatch in inventory.brew_batches:
		total += batch.amount_bottles

	return total


## Called after anything that can push money to (or toward) zero — the
## LVV fine above, a purchase, or the daily utility bill
## (TimeManager._charge_daily_utility_bills) — since any of those can be
## the final straw. A truly dead end: no cash AND nothing left to sell
## that could raise any.
func check_bankruptcy() -> void:
	if money > 0.0 or count_total_bottles() > 0:
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
	resolver.ingredient_price_multiplier = stats.multiplier(PerkStats.INGREDIENT_PRICE)

	GUISignals.add_ingredient_to_brew_preparation.connect(_on_add_ingredient_to_brew_preparation)
	GUISignals.remove_ingredients_from_brew_preparation.connect(_on_remove_ingredient_from_brew_preparation)
	GUISignals.start_brewing.connect(start_brew)
	recipe_book = RecipeBook.new(self)
	recipe_book.connect_signals()
	ingredient_trader = IngredientTrader.new(self)
	ingredient_trader.connect_signals()
	batch_distributor = BatchDistributor.new(self)
	batch_distributor.connect_signals()


## Must be called on the outgoing Brewery before BrewEngine.current_brewery
## is replaced (new game, load game) — otherwise the old instance stays
## connected to GUISignals forever (Godot keeps it alive via the signal
## connection) and silently keeps handling player actions instead of the
## one actually shown on screen.
func disconnect_signals() -> void:
	GUISignals.add_ingredient_to_brew_preparation.disconnect(_on_add_ingredient_to_brew_preparation)
	GUISignals.remove_ingredients_from_brew_preparation.disconnect(_on_remove_ingredient_from_brew_preparation)
	GUISignals.start_brewing.disconnect(start_brew)
	for service : Variant in [recipe_book, ingredient_trader, batch_distributor]:
		if service != null:
			service.disconnect_signals()
	recipe_book = null
	ingredient_trader = null
	batch_distributor = null


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

	# Applied to the RAW yield, before bottling loss — see RunPerk.
	# brew_yield_multiplier's docstring for why this multiplies the yield
	# itself rather than reducing BrewResolver.BOTTLE_LOSS_RATE.
	var raw_yield : int = roundi(brew_report.bottle_yield * stats.multiplier(PerkStats.BREW_YIELD))
	var bottling : Dictionary = apply_bottling_costs(raw_yield)
	var effective_yield : int = bottling.effective_yield
	var bottles_lost : int = bottling.bottles_lost
	var label_cost : float = bottling.label_cost

	var new_batch := BrewBatch.new()
	new_batch.beer_style = brew_report.beer_style
	new_batch.amount_bottles = effective_yield
	new_batch.original_quality = brew_report.original_quality + stats.total(PerkStats.QUALITY_BONUS)
	new_batch.current_quality = new_batch.original_quality
	new_batch.final_ebc = brew_report.final_ebc
	new_batch.final_ibu = brew_report.final_ibu
	new_batch.precision_score = brew_report.precision_score
	new_batch.hop_diversity_count = brew_report.hop_diversity_count
	new_batch.hop_balance_bonus = brew_report.hop_balance_bonus
	new_batch.flavor_matched = brew_report.flavor_matched
	new_batch.peak_days_multiplier = stats.multiplier(PerkStats.PEAK_SPEED)
	new_batch.decline_rate_multiplier = stats.multiplier(PerkStats.DECLINE_RATE)

	inventory.brew_batches.append(new_batch)

	if brew_report.is_matched:
		var is_new_discovery : bool = not discovered_styles.has(brew_report.beer_style.style)
		discover_style(brew_report.beer_style.style)
		if is_new_discovery:
			RecipeBook.new(self).save_recipe(brew_report.beer_style, brew_preparation.selected_contents.duplicate())
		if brew_report.beer_style.style == BeerStyle.Style.KOTIKALJA:
			tutorial_brewed_kotikalja = true
		BrewerySignals.beer_brewed.emit(brew_report.beer_style.style)

		var brew_xp : int = XP_PER_SUCCESSFUL_BREW
		if is_new_discovery:
			brew_xp += XP_PER_NEW_STYLE_DISCOVERY_BONUS
		add_xp(brew_xp)
		BrewerySignals.brew_xp_gained.emit(brew_xp)

	_roll_ingredient_refund()
	brew_preparation.clear_preparation()
	print(StringContainer.SUCCESFULL_BREW_MESSAGE, BeerStyle.get_style_string_from_style(brew_report.beer_style.style))
	BrewerySignals.batch_bottled.emit(bottles_lost, label_cost, brew_report.beer_style.style_name)
	BrewerySignals.brewery_state_changed.emit(self)


## Fraction of a brew's consumed ingredients returned to inventory when
## RunPerk.ingredient_refund_chance's roll succeeds — flat regardless of
## how many perk levels contributed to that chance (only the ODDS of a
## refund scale with level, not its size, keeping this simple to reason
## about: it either saves you half your materials this brew, or it
## doesn't).
const INGREDIENT_REFUND_FRACTION : float = 0.5

## Called from start_brew() while brew_preparation.selected_contents still
## holds what this brew actually consumed — must run before
## clear_preparation() wipes that table.
func _roll_ingredient_refund() -> void:
	var chance : float = stats.chance(PerkStats.INGREDIENT_REFUND_CHANCE)
	if chance <= 0.0 or randf() >= chance:
		return

	var refunded_any : bool = false
	for ingredient_id : int in brew_preparation.selected_contents:
		var used_amount : int = brew_preparation.selected_contents[ingredient_id]
		var refund_amount : int = roundi(used_amount * INGREDIENT_REFUND_FRACTION)
		if refund_amount <= 0:
			continue
		inventory.add_amount_by_id(ingredient_id, refund_amount)
		refunded_any = true

	if refunded_any:
		BrewerySignals.ingredients_refunded.emit()
