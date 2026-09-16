class_name Brewery
extends Resource


const LVV_RAID_THRESHOLD : int = 100
const LVV_RAID_FINE_PERCENT : float = 0.3
const LVV_RAID_REPUTATION_PENALTY_PERCENT : float = 0.25
## How much steeper LVV_RAID_FINE_PERCENT/REPUTATION_PENALTY_PERCENT get per
## prior raid this run — same escalation shape as EARLY_CLOSE_ESCALATION_
## PER_CLOSE, just steeper, since a raid is the rarer, harsher event of the
## two. 1.0 means each successive raid's percentages grow by a full
## multiple of the first: raid 1 is the unescalated base (30%/25%), raid 2
## doubles it (60%/50%), raid 3 (which also busts the run via
## BUSTED_RAID_COUNT below) triples it — a repeat offender gets genuinely
## wrecked instead of every raid costing the same bite. See
## _check_for_lvv_raid().
const LVV_RAID_ESCALATION_PER_RAID : float = 1.0
## Three strikes: the raid that pushes raid_count to this becomes
## permanent instead of just another costly setback — see
## _check_for_lvv_raid() and BrewerySignals.game_ended.
const BUSTED_RAID_COUNT : int = 3
## A run only ends in the "survived" ending if it's not currently on the
## ropes — reaching the day target with 1 reputation and a completely
## empty warehouse shouldn't read as a triumphant ending. See
## TimeManager._advance_day(). Set well above CustomerData.
## min_reputation_to_appear's rarer-customer tier (50, e.g. Agentti/
## Mafioso) so clearing it takes real sustained reputation, not just a
## couple of lucky sales.
const SURVIVAL_MIN_REPUTATION : int = 100

## Manually closing the day (TimeManager.force_advance_day()) at earliness
## 1.0 (right as the day began) costs this much money/reputation before
## escalation — see apply_early_close_cost(). Scales down to 0 at earliness
## 0.0 (closed right as the timer would have ended anyway, i.e. no real
## early-close at all).
const EARLY_CLOSE_BASE_MONEY_COST : float = 5.0
const EARLY_CLOSE_BASE_REPUTATION_COST : int = 1
## How much EARLY_CLOSE_BASE_*_COST grows per prior manual close this run —
## 0.5 means the 2nd close's base cost is 1.5x, the 3rd is 2.0x, etc. Keeps
## spamming Close Day from staying a flat, repeatable freebie. See
## early_closes_count.
const EARLY_CLOSE_ESCALATION_PER_CLOSE : float = 0.5
## LVV risk relief for closing at earliness 1.0, scaling down to 0 at
## earliness 0.0 — the trade-off side of the same mechanic (deliberately
## NOT escalated by early_closes_count: the cost gets steeper with repeat
## use, but the risk relief it buys stays consistent).
const EARLY_CLOSE_MAX_RISK_RELIEF : int = 10

## Per-bottle payout for bulk-selling a batch (see _on_bulk_sell_batch_
## requested()) as a fraction of raw_cost_per_bottle — deliberately below
## 1.0 so even a peak-quality batch nets less than it cost to brew; it's a
## "clear the warehouse" release valve, not an alternate income source.
## current_quality is also clamped to 1.0 before this multiplies it, so a
## spoiled/declining batch (current_quality well under 1.0) pays out even
## less, potentially far under ingredient cost.
const BULK_SELL_RATE : float = 0.5

## Quality clamp range applied before BarContact.price_multiplier in
## ship_batch_to_bar() — a floor above 0.0 (unlike bulk-sell's) since a bar
## still expects the batch to be drinkable, and a ceiling above 1.0 (unlike
## bulk-sell's hard cap at 1.0) since a genuinely excellent batch is worth
## a real premium to a paying venue, not just "no worse than average".
const SHIP_TO_BAR_QUALITY_CLAMP_MIN : float = 0.3
const SHIP_TO_BAR_QUALITY_CLAMP_MAX : float = 1.3

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
## How many LVV raids this run has survived — see _check_for_lvv_raid()
## and BUSTED_RAID_COUNT. Never resets.
@export var raid_count : int = 0
## How many times the player has manually closed the day this run — see
## apply_early_close_cost() and EARLY_CLOSE_ESCALATION_PER_CLOSE. Never
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
	resolver.ingredient_price_multiplier = run_modifier.ingredient_price_multiplier
	discovered_styles[BeerStyle.Style.KOTIKALJA] = true

	# Zero-click first-brew hint: Kotikalja is known from the start without
	# ever being brewed, so it never goes through discover_style()'s
	# default-recipe seeding below — seed it here instead.
	var kotikalja_recipe : BrewRecipe = _ensure_default_recipe(resolver.get_beer_style(BeerStyle.Style.KOTIKALJA), false)
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
	_check_for_lvv_raid()


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


## Sums every active perk's quality_bonus plus this run's RunModifier's own
## quality_bonus (see that resource's docstring) — the modifier's is a
## fixed part of the run's starting conditions, the perks accumulate on
## top of it as the run goes on.
func get_quality_bonus() -> float:
	var total : float = run_modifier.quality_bonus
	for perk : RunPerk in active_perks:
		total += perk.quality_bonus
	return total


## Combined via RunPerk.combine_stacking() rather than a plain loop —
## see stacks_additively's own docstring for why a perk can opt into
## flat, non-compounding growth instead of the default multiplicative
## stack.
func get_reputation_gain_multiplier() -> float:
	return RunPerk.combine_stacking(run_modifier.reputation_gain_multiplier, active_perks, func(perk : RunPerk) -> float: return perk.reputation_gain_multiplier)


func get_tip_income_multiplier() -> float:
	return RunPerk.combine_stacking(run_modifier.tip_income_multiplier, active_perks, func(perk : RunPerk) -> float: return perk.tip_income_multiplier)


## LVV_RAID_THRESHOLD scaled by this run's modifier — see RunModifier.
## lvv_threshold_multiplier. Kept separate from the raw constant since that
## constant is also read by call sites with no Brewery instance in scope
## (audio_manager.gd's ambient tension scaling, the dev console's "raid"
## cheat) — both of those now call this instead so they stay accurate
## under any modifier.
func get_effective_raid_threshold() -> int:
	var multiplier : float = RunPerk.combine_stacking(run_modifier.lvv_threshold_multiplier, active_perks, func(perk : RunPerk) -> float: return perk.raid_threshold_multiplier)
	return roundi(LVV_RAID_THRESHOLD * multiplier)


## No RunModifier counterpart (unlike get_reputation_gain_multiplier()/
## get_tip_income_multiplier(), which both start from a run_modifier
## field) — distribution income only exists as a perk axis, see
## RunPerk.distribution_income_multiplier's docstring for why.
func get_distribution_income_multiplier() -> float:
	return RunPerk.combine_stacking(1.0, active_perks, func(perk : RunPerk) -> float: return perk.distribution_income_multiplier)


func _check_for_lvv_raid() -> void:
	if risk < get_effective_raid_threshold():
		return

	var confiscated_bottles : int = _count_total_bottles()
	inventory.brew_batches.clear()

	# raid_count still reflects prior raids only — incremented below, after
	# this raid's own escalation is locked in, same ordering
	# apply_early_close_cost() uses for early_closes_count.
	var escalation : float = 1.0 + raid_count * LVV_RAID_ESCALATION_PER_RAID
	var fine_amount : float = snappedf(money * LVV_RAID_FINE_PERCENT * escalation, 0.1)
	var reputation_penalty : int = roundi(reputation * LVV_RAID_REPUTATION_PENALTY_PERCENT * escalation)

	money -= fine_amount
	reputation = max(0, reputation - reputation_penalty)
	risk = 0
	raid_count += 1

	BrewerySignals.lvv_raid_triggered.emit(confiscated_bottles, fine_amount, reputation_penalty)
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
## LVV fine above, a purchase, or the daily utility bill
## (TimeManager._charge_daily_utility_bills) — since any of those can be
## the final straw. A truly dead end: no cash AND nothing left to sell
## that could raise any.
func check_bankruptcy() -> void:
	if money > 0.0 or _count_total_bottles() > 0:
		return
	trigger_ending("bankrupt")


## Called by TimeManager.force_advance_day() before the day actually
## advances, whenever the player shuts the doors manually instead of
## waiting out the timer. earliness is 0.0 (closed right as the timer
## would have ended anyway — no real cost or relief) to 1.0 (closed the
## instant the day began). Trades a lost sales window for a bit of safety:
## LVV risk drops, but money/reputation take a hit that gets steeper with
## every prior manual close this run (EARLY_CLOSE_ESCALATION_PER_CLOSE) —
## without that escalation, spamming this at earliness ~0 would still cost
## nothing while resetting nothing either, so it has to bite even on a
## late, "harmless-looking" close to actually discourage habitual use.
func apply_early_close_cost(earliness : float) -> void:
	earliness = clampf(earliness, 0.0, 1.0)
	var escalation : float = 1.0 + early_closes_count * EARLY_CLOSE_ESCALATION_PER_CLOSE

	var money_cost : float = snappedf(EARLY_CLOSE_BASE_MONEY_COST * escalation * earliness, 0.1)
	var reputation_cost : int = roundi(EARLY_CLOSE_BASE_REPUTATION_COST * escalation * earliness)
	var risk_relief : int = roundi(EARLY_CLOSE_MAX_RISK_RELIEF * earliness)

	money -= money_cost
	reputation = max(0, reputation - reputation_cost)
	risk = max(0, risk - risk_relief)
	early_closes_count += 1

	BrewerySignals.early_day_close_applied.emit(money_cost, reputation_cost, risk_relief, early_closes_count)
	BrewerySignals.brewery_state_changed.emit(self)
	check_bankruptcy()


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
	GUISignals.bulk_sell_batch_requested.connect(_on_bulk_sell_batch_requested)
	GUISignals.ship_batch_to_bar_requested.connect(_on_ship_batch_to_bar_requested)
	GUISignals.start_brewing.connect(start_brew)
	GUISignals.save_recipe_requested.connect(_on_save_recipe_requested)
	GUISignals.load_recipe_requested.connect(_on_load_recipe_requested)
	GUISignals.fill_recipe_from_inventory_requested.connect(_on_fill_recipe_from_inventory_requested)
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
	GUISignals.bulk_sell_batch_requested.disconnect(_on_bulk_sell_batch_requested)
	GUISignals.ship_batch_to_bar_requested.disconnect(_on_ship_batch_to_bar_requested)
	GUISignals.start_brewing.disconnect(start_brew)
	GUISignals.save_recipe_requested.disconnect(_on_save_recipe_requested)
	GUISignals.load_recipe_requested.disconnect(_on_load_recipe_requested)
	GUISignals.fill_recipe_from_inventory_requested.disconnect(_on_fill_recipe_from_inventory_requested)
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
		BrewerySignals.ingredient_purchase_locked.emit(ingredient.name, ingredient.min_reputation)
		return

	var buy_price : int = roundi(ingredient.base_price * amount * run_modifier.ingredient_price_multiplier)

	if money < buy_price:
		print(StringContainer.RESOURCE_ERROR % [money, buy_price, StringContainer.MONEY_STRING])
		BrewerySignals.ingredient_purchase_underfunded.emit(ingredient.name, buy_price, money)
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


## Pure payout math for bulk-selling a batch, split out from
## _on_bulk_sell_batch_requested() so it's directly unit-testable without
## constructing a Brewery (which needs live autoloads — see _init()) —
## same "static function, instance method wraps it" split as
## BrewResolver.calculate_price_breakdown()/get_price_breakdown(). See
## BULK_SELL_RATE's docstring for why the result is deliberately
## underwater against raw_cost_per_bottle even at quality 1.0.
static func calculate_bulk_sell_payout(raw_cost_per_bottle : float, quality : float, amount_bottles : int) -> float:
	var quality_factor : float = clampf(quality, 0.0, 1.0)
	return snappedf(raw_cost_per_bottle * BULK_SELL_RATE * quality_factor * amount_bottles, 0.1)


## Dumps an entire batch for cheap warehouse-clearing cash instead of
## waiting for customers — see BULK_SELL_RATE's docstring for why the
## payout is deliberately underwater against what the batch cost to brew.
## No reputation/XP/tip and no risk change: unlike a real sale
## (CustomerManager.process_auto_sale()) this never reaches a customer at
## all, it's just inventory leaving the warehouse for money.
func _on_bulk_sell_batch_requested(batch : BrewBatch) -> void:
	if batch == null or not inventory.brew_batches.has(batch) or batch.amount_bottles <= 0:
		return

	var raw_cost_per_bottle : float = resolver.get_price_breakdown(batch.beer_style).raw_cost_per_bottle
	var payout : float = calculate_bulk_sell_payout(raw_cost_per_bottle, batch.current_quality, batch.amount_bottles)
	payout = snappedf(payout * get_distribution_income_multiplier(), 0.1)

	money += payout
	BrewerySignals.batch_bulk_sold.emit(batch.get_style_name(), batch.amount_bottles, payout)

	inventory.brew_batches.erase(batch)
	BrewerySignals.brewery_state_changed.emit(self)


## Pure payout math for shipping a batch to a BarContact — same "static
## twin of the instance handler" split as calculate_bulk_sell_payout()
## above, for the same reason (unit-testable without a live Brewery).
static func calculate_ship_payout(raw_cost_per_bottle : float, quality : float, amount_bottles : int, price_multiplier : float) -> float:
	var quality_factor : float = clampf(quality, SHIP_TO_BAR_QUALITY_CLAMP_MIN, SHIP_TO_BAR_QUALITY_CLAMP_MAX)
	return snappedf(raw_cost_per_bottle * price_multiplier * quality_factor * amount_bottles, 0.1)


## Hands an entire batch off to a BarContact instead of the counter — see
## SHIP_TO_BAR_QUALITY_CLAMP_MIN/MAX and BarContact.price_multiplier for
## the payout formula, and BarContact.risk_per_shipment for the trade-off:
## unlike _on_bulk_sell_batch_requested(), this raises risk since the
## batch is now circulating outside the player's own cellar. Silently
## refuses a bar the player's reputation hasn't unlocked yet — mirrors
## Brewery._on_buy_ingredient()'s locked-ingredient guard, and
## BarContactOptionButton disables locked contacts in the picker itself so
## a real player can't normally reach this path either.
func _on_ship_batch_to_bar_requested(batch : BrewBatch, bar : BarContact) -> void:
	if batch == null or bar == null or not inventory.brew_batches.has(batch) or batch.amount_bottles <= 0:
		return
	if reputation < bar.required_reputation:
		return

	var raw_cost_per_bottle : float = resolver.get_price_breakdown(batch.beer_style).raw_cost_per_bottle
	var payout : float = calculate_ship_payout(raw_cost_per_bottle, batch.current_quality, batch.amount_bottles, bar.price_multiplier)
	payout = snappedf(payout * get_distribution_income_multiplier(), 0.1)

	money += payout
	add_risk(bar.risk_per_shipment)
	BrewerySignals.keg_shipped_to_bar.emit(batch.get_style_name(), bar.bar_name, batch.amount_bottles, payout, bar.risk_per_shipment)

	inventory.brew_batches.erase(batch)
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


## Tops the table up to the currently active recipe's target amounts —
## unlike _on_load_recipe_requested() above (which withdraws whatever it
## can even if that's short of the target, since loading IS the point at
## which a fresh target gets set), this is strictly all-or-nothing: it
## checks every missing ingredient against inventory FIRST, and refuses
## outright if any single one is short, rather than partially draining
## inventory into a table that still can't brew. BrewPreparationPanel
## mirrors this same check to keep its "Täytä" button disabled whenever
## this would refuse, so a real player should never actually reach the
## refusal path — same defense-in-depth reasoning as the reputation guard
## in _on_ship_batch_to_bar_requested().
func _on_fill_recipe_from_inventory_requested() -> void:
	var recipe_target : Dictionary = brew_preparation.active_recipe_target
	if recipe_target.is_empty():
		return

	var missing_amounts : Dictionary = {}
	for ingredient_id : int in recipe_target:
		var required : int = recipe_target[ingredient_id]
		var on_table : int = brew_preparation.selected_contents.get(ingredient_id, 0)
		var missing : int = required - on_table
		if missing <= 0:
			continue

		var item : InventoryItem = inventory.get_item_by_id(ingredient_id)
		var available : int = item.amount if item else 0
		if available < missing:
			return

		missing_amounts[ingredient_id] = missing

	if missing_amounts.is_empty():
		return

	for ingredient_id : int in missing_amounts:
		var withdrawn : int = inventory.withdraw_item_by_id(ingredient_id, missing_amounts[ingredient_id])
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
