extends Node

## Plays a run with one strategy and writes a JSON report when the run ends or
## max_days is reached.
##   greedy  - brews what unlocked customers want most, accepts every event
##   variety - keeps several styles in stock, accepts events only when they pay off
##   careful - like variety, and closes the day early when LVV risk gets high
##   cheap   - always the cheapest recipe, declines every event
##   expert  - knows every recipe: brews any style the unlocked ingredients allow, aiming at
##             reputation, profit, first brews and styles that unlock customers; plays
##             events and LVV risk like careful, and buys cellar upgrades with spare money
##   gourmet - plays like expert, then tunes each recipe one ingredient unit at a time
##             towards the best quality its unlocked, affordable ingredients reach
##   minmax  - plays like gourmet, aiming straight at RunScore: takes an event only when
##             its rewards outweigh what it costs in score points, and cashes out every
##             leftover batch and ingredient on the last scored day
## Both experts also play the rest of the game the way their Olutoppi spec rewards: they
## finish the tutorial, ship surplus batches to bars, pick level-up cards by value and
## play closer to the raid line when a raid would be survivable.
## Every bot chases daily goals unless --goals=0: it brews a brew-style goal's style
## from its minimum recipe (what the recipe library's hints lead a player to), ships a
## batch to the safest bar for a ship-to-bar goal and takes a risk-free favour for a
## special-event goal. The other goal types follow from playing well.

## Strategies that play like the expert.
const EXPERTS: Array[String] = ["expert", "gourmet", "minmax"]
## Strategies that tune their recipes for quality.
const TUNERS: Array[String] = ["gourmet", "minmax"]

var cfg: Dictionary = {}
var days: Array = []
var notes: Array = []
var counts: Dictionary = {}
var ending: String = ""
var _tick: float = 0.0
var _brew_cooldown: float = 0.0
var _ship_cooldown: float = 0.0
var _done: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	BrewerySignals.friend_recommended.connect(func(_d: CustomerData) -> void: _inc("friends"))
	BrewerySignals.bad_review_spread.connect(func() -> void: _inc("bad_reviews"))
	BrewerySignals.regular_status_changed.connect(func(t: String, r: bool) -> void: _note("regular %s %s" % [t, "gained" if r else "lost"]))
	BrewerySignals.reputation_tier_changed.connect(func(t: ReputationTier, r: bool) -> void: _note("tier %s %s" % [t.tier_name, "up" if r else "down"]); _inc("tier_toasts"))
	BrewerySignals.reputation_decayed.connect(func(a: int, _t: ReputationTier) -> void: _inc("decay_total", a))
	BrewerySignals.lvv_raid_triggered.connect(func(b: int, f: float, r: int) -> void: _note("RAID bottles %d fine %.0f rep -%d" % [b, f, r]))
	BrewerySignals.special_event_resolved.connect(func(ok: bool, e: SpecialEventData) -> void: _inc("event_%s_%s" % [e.event_caller_name, "ok" if ok else "fail"]))
	BrewerySignals.customer_unhappy.connect(func() -> void: _inc("unhappy"))
	BrewerySignals.customer_served.connect(func(d: CustomerData) -> void: _inc("served:" + d.title))
	BrewerySignals.bottles_sold.connect(func(n: int) -> void: _inc("bottles", n))
	BrewerySignals.bar_fight_triggered.connect(func(_m: String) -> void: _inc("bar_fights"))
	BrewerySignals.game_ended.connect(func(t: String) -> void: ending = t)
	CustomerRegistry.customer_unlocked.connect(func(t: String) -> void: _note("unlocked %s" % t))
	TimeManager.day_changed.connect(_on_day_changed)
	BrewerySignals.beer_sale_breakdown.connect(func(e: SaleReceiptEntry) -> void: _inc("counter_money", roundi(e.net_income)); _inc("tip_money", roundi(e.tip_income)))
	BrewerySignals.batch_bulk_sold.connect(func(_s: String, _n: int, pay: float) -> void: _inc("bulk_money", roundi(pay)))
	BrewerySignals.keg_shipped_to_bar.connect(func(_s: String, _b: String, n: int, pay: float, _r: int) -> void: _inc("shipments"); _inc("shipped_bottles", n); _inc("shipped_money", roundi(pay)))
	DailyGoalManager.daily_goal_resolved.connect(func(n: String, ok: bool, _m: int, _r: int, _x: int, _k: int) -> void: _inc("goals_ok" if ok else "goals_failed"); _inc(("goal_ok:" if ok else "goal_fail:") + n))


func _inc(key: String, n: int = 1) -> void:
	counts[key] = counts.get(key, 0) + n


func _note(text: String) -> void:
	var b: Brewery = BrewEngine.current_brewery
	notes.append("d%d r%d %s" % [b.current_day if b else 0, b.reputation if b else 0, text])


func _on_day_changed(_day: int) -> void:
	var b: Brewery = BrewEngine.current_brewery
	var tier: ReputationTier = b.get_reputation_tier()
	var regulars: int = 0
	for t: String in b.customer_standing:
		if RegularRules.is_regular(b.customer_standing[t]):
			regulars += 1
	days.append({"day": b.current_day, "rep": b.reputation, "tier": tier.tier_name if tier else "", "money": snappedf(b.money, 0.1), "risk": b.risk, "raids": b.raid_count, "level": b.run_level, "regulars": regulars})


func _process(delta: float) -> void:
	if _done:
		return
	_tick += delta
	_brew_cooldown -= delta
	_ship_cooldown -= delta
	if _tick < 0.5:
		return
	_tick = 0.0
	var b: Brewery = BrewEngine.current_brewery
	if b == null:
		return
	if b.game_has_ended or b.current_day > int(cfg.max_days):
		_finish(b)
		return

	for w: Node in get_tree().root.find_children("LevelUpWindow", "", true, false):
		if w.visible:
			w._on_card_pressed(_pick_card(b, w._offered_perks) if cfg.strategy in EXPERTS else randi() % 3)
	for w: Node in get_tree().root.find_children("SpecialEventWindow", "", true, false):
		if w.visible and w.joo_button.visible and _wants_event(b, w.event_data):
			w._on_joo_button_pressed()
	for w: Node in get_tree().root.find_children("DayRecapWindow", "", true, false):
		if w.visible:
			if not days.is_empty():
				days[-1]["recap"] = w.message_label.text.get_slice("\n", 3)
				days[-1]["risk_line"] = w.message_label.text.get_slice("\n", 4)
			w._on_close_button_pressed()

	if get_tree().paused:
		return
	if cfg.strategy == "minmax":
		_cash_out(b)
	if (cfg.strategy == "careful" or cfg.strategy in EXPERTS) and not TimeManager.day_timer.is_stopped() and b.risk >= _close_ratio(b) * b.get_effective_raid_threshold():
		_inc("early_closes")
		if cfg.strategy == "minmax":
			_cash_out(b, true)
		TimeManager.force_advance_day()
		return
	if _brew_cooldown <= 0.0 and _needs_brew(b):
		_brew(b)
	if cfg.strategy in EXPERTS:
		_manage_cellar(b)
		_buy_upgrade(b)
	if cfg.strategy in EXPERTS or _open_goal(DailyGoalData.GoalType.SHIP_TO_BAR) != -1:
		_maybe_ship(b)


## Holds a young batch of a style that pays more aged (BeerStyle.aged_price_bonus) until
## its peak, but never the last beer the counter has: a customer with nothing to buy
## leaves unhappy.
func _manage_cellar(b: Brewery) -> void:
	for batch: BrewBatch in b.inventory.brew_batches:
		var aging: bool = _still_aging(batch)
		var others: int = b.inventory.count_bottles() - _held_bottles(b) - (0 if batch.held else batch.amount_bottles)
		var should_hold: bool = aging and others >= CELLAR_COUNTER_FLOOR
		if should_hold != batch.held:
			GUISignals.batch_hold_toggled.emit(batch)
			if should_hold:
				_inc("cellar_holds")


func _still_aging(batch: BrewBatch) -> bool:
	return batch.beer_style.aged_price_bonus > 0.0 and batch.age_in_days < batch.get_effective_peak_days()


func _held_bottles(b: Brewery) -> int:
	var held: int = 0
	for batch: BrewBatch in b.inventory.brew_batches:
		if batch.held:
			held += batch.amount_bottles
	return held


func _wants_event(b: Brewery, e: SpecialEventData) -> bool:
	var threshold: int = b.get_effective_raid_threshold()
	if e is ReputationFavourEventData and (e as ReputationFavourEventData).reward_risk <= 0 and _open_goal(DailyGoalData.GoalType.SPECIAL_EVENT) != -1:
		return true
	match cfg.strategy:
		"minmax":
			return _event_points(b, e) > 0.0
		"greedy":
			return true
		"cheap":
			return false
	if e is ReputationFavourEventData:
		var favour := e as ReputationFavourEventData
		if favour.reward_risk < 0:
			return b.risk >= 0.6 * threshold
		return b.money < 40.0
	if e is RiskBribeEventData:
		return b.risk >= 0.6 * threshold and b.money >= (e as RiskBribeEventData).bribe_cost + 20
	if e.get_script() == SpecialEventData:
		for batch: BrewBatch in b.inventory.brew_batches:
			if batch.beer_style.style == e.required_style and batch.amount_bottles >= e.required_bottles:
				return true
		return false
	return true


func _needs_brew(b: Brewery) -> bool:
	if cfg.strategy == "minmax" and _is_last_day(b) and TimeManager.get_day_progress() >= LAST_BREW_PROGRESS:
		return false
	if cfg.strategy in EXPERTS:
		# Held batches are aging, not for sale, so they do not count as counter stock.
		if b.inventory.count_bottles() - _held_bottles(b) < COUNTER_STOCK or b.inventory.brew_batches.size() < 3:
			return true
		if not b.tutorial_complete() or _goal_style_recipe(b) != null:
			return true
		# Brews extra batches to ship while the risk and the cash allow it.
		return b.inventory.brew_batches.size() < 5 and b.money >= EXPORT_BREW_RESERVE and _best_bar(b) != null
	if _goal_style_recipe(b) != null:
		return true
	if cfg.strategy in ["variety", "careful"]:
		return b.inventory.count_bottles() < 30 or b.inventory.brew_batches.size() < 2
	return b.inventory.count_bottles() < 15


func _brew(b: Brewery) -> void:
	if cfg.strategy in EXPERTS:
		_brew_recipe(b, _expert_recipe(b))
		return
	var goal_recipe: BrewRecipe = _goal_style_recipe(b)
	if goal_recipe != null:
		_inc("goal_brews")
		_brew_recipe(b, goal_recipe)
		return
	var demand: Dictionary = {}
	for c: CustomerData in CustomerRegistry.customer_pool:
		if CustomerRegistry.is_eligible(c):
			demand[c.primary_style] = demand.get(c.primary_style, 0) + 2
			demand[c.secondary_style] = demand.get(c.secondary_style, 0) + 1
	var in_stock: Dictionary = {}
	for batch: BrewBatch in b.inventory.brew_batches:
		in_stock[batch.beer_style.style] = true

	var best: BrewRecipe = null
	var best_score: float = -INF
	for r: BrewRecipe in b.saved_recipes:
		var cost: int = _missing_cost(b, r)
		if cost + _reserve(b) > b.money:
			continue
		var score: float
		match cfg.strategy:
			"cheap":
				score = -cost
			"greedy":
				score = demand.get(r.beer_style, 0) + 0.001 * (100 - cost)
			_:
				score = demand.get(r.beer_style, 0) - (6.0 if in_stock.has(r.beer_style) else 0.0) + 0.001 * (100 - cost)
		if score > best_score:
			best_score = score
			best = r
	_brew_recipe(b, best)


func _brew_recipe(b: Brewery, recipe: BrewRecipe) -> void:
	if recipe == null:
		_brew_cooldown = 5.0
		return

	for id: int in recipe.ingredient_amounts:
		var missing: int = maxi(0, recipe.ingredient_amounts[id] - _owned(b, id))
		if missing > 0:
			GUISignals.buy_ingredient.emit(id, missing)
	var result: BrewResult = b.resolver.resolve_brew_style(recipe.ingredient_amounts)
	if result != null:
		counts["quality_sum"] = counts.get("quality_sum", 0.0) + result.original_quality
		if result.spice_bonus > 0.0:
			_inc("spiced_brews")
		elif result.spice_bonus < 0.0:
			_inc("purity_law_broken")
	GUISignals.load_recipe_requested.emit(recipe)
	GUISignals.start_brewing.emit()
	_inc("brews")
	_inc("brew:" + BeerStyle.get_style_string_from_style(recipe.beer_style))
	_brew_cooldown = 3.0


## The best style to brew next, from every style the unlocked ingredients can make.
func _expert_recipe(b: Brewery) -> BrewRecipe:
	var forced: BrewRecipe = _goal_style_recipe(b)
	if not b.tutorial_complete():
		forced = _style_recipe(b, BeerStyle.Style.KOTIKALJA)
	if forced != null:
		if cfg.strategy in TUNERS:
			forced.ingredient_amounts = _tune_for_quality(b, forced.beer_style, forced.ingredient_amounts)
		return forced
	var in_stock: Dictionary = {}
	for batch: BrewBatch in b.inventory.brew_batches:
		if batch.held:
			continue
		in_stock[batch.beer_style.style] = in_stock.get(batch.beer_style.style, 0) + batch.amount_bottles

	var candidates: Array[BrewRecipe] = []
	var scores: Array[float] = []
	for style: BeerStyle in b.resolver.active_styles:
		var ingredients: Dictionary = _with_spices(b, style, b.resolver.compute_minimum_ingredients(style))
		if ingredients.is_empty() or not _all_unlocked(b, ingredients):
			continue
		var cost: int = _missing_cost_of(b, ingredients)
		if cost + _reserve(b) > b.money:
			continue
		var score: float = _expert_demand(b, style.style, in_stock)
		if score <= 0.0:
			continue
		if not b.brewed_styles.has(style.style):
			score += maxi(0, style.reputation_change)
		score += b.resolver.get_style_base_price(style) - b.resolver.get_style_cost_per_bottle(style)
		# Half the aged bonus: the bot waits for it, and sells some young.
		score += b.resolver.get_style_base_price(style) * style.aged_price_bonus * 0.5
		var recipe := BrewRecipe.new()
		recipe.beer_style = style.style
		recipe.ingredient_amounts = ingredients
		candidates.append(recipe)
		scores.append(score)
	var best: BrewRecipe = _pick_near_best(candidates, scores)
	if best != null and cfg.strategy in TUNERS:
		best.ingredient_amounts = _tune_for_quality(b, best.beer_style, best.ingredient_amounts)
	return best


## Styles scoring at least this share of the best are all in the running.
const NEAR_BEST_SHARE: float = 0.75


## A weighted pick among the styles close to the best score, like a player who
## serves several tastes. Always taking the top one made a one-point gap flip
## a whole style on or off (Baltic Porter 1 vs 28 brews per run).
func _pick_near_best(candidates: Array[BrewRecipe], scores: Array[float]) -> BrewRecipe:
	if candidates.is_empty():
		return null
	var best_score: float = scores.max()
	var near: Array[BrewRecipe] = []
	var weights: Array[float] = []
	for i: int in candidates.size():
		if scores[i] >= best_score * NEAR_BEST_SHARE:
			near.append(candidates[i])
			weights.append(scores[i])
	return WeightedPicker.pick(near, weights) as BrewRecipe


## Bottles an expert keeps for the counter before it ships or brews for bars.
const COUNTER_STOCK: int = 40
## Cash an expert keeps before brewing a batch only to ship it.
const EXPORT_BREW_RESERVE: float = 150.0
## Plain exports wait for the end of the day and stay under this share of the raid
## threshold: risk spent on a shipment is risk the counter cannot use, and counter sales
## (reputation) are worth far more score than export money.
const EXPORT_DAY_PROGRESS: float = 0.85
const EXPORT_RISK_SHARE: float = 0.5


## A minimum recipe for `style` if the unlocked ingredients and the cash allow it.
func _style_recipe(b: Brewery, style: BeerStyle.Style) -> BrewRecipe:
	var beer_style: BeerStyle = b.resolver.get_beer_style(style)
	if beer_style == null:
		return null
	var ingredients: Dictionary = _with_spices(b, beer_style, b.resolver.compute_minimum_ingredients(beer_style))
	if ingredients.is_empty() or not _all_unlocked(b, ingredients) or _missing_cost_of(b, ingredients) + _reserve(b) > b.money:
		return null
	var recipe := BrewRecipe.new()
	recipe.beer_style = style
	recipe.ingredient_amounts = ingredients
	return recipe


## One unit of each unlocked spice the style likes, up to the bonus cap. A German
## style gets none, since it keeps the Reinheitsgebot.
func _with_spices(b: Brewery, style: BeerStyle, ingredients: Dictionary) -> Dictionary:
	if ingredients.is_empty() or style.forbids_spices:
		return ingredients
	var spiced: Dictionary = ingredients.duplicate()
	var added: int = 0
	for spice_id: int in style.preferred_spice_ids:
		if added * BrewQuality.SPICE_MATCH_STEP >= BrewQuality.SPICE_MATCH_MAX:
			break
		var spice: IngredientData = IngredientDatabase.get_item_by_id(spice_id)
		if spice != null and spice.min_reputation <= b.reputation:
			spiced[spice_id] = 1
			added += 1
	return spiced


## The slot of an unfinished daily goal of `kind`, or -1. Always -1 with --goals=0.
func _open_goal(kind: DailyGoalData.GoalType) -> int:
	if cfg.get("goals", "1") == "0":
		return -1
	var goals: Array[GoalData] = DailyGoalManager.active_goals
	for i: int in goals.size():
		var goal := goals[i] as DailyGoalData
		if goal != null and goal.goal_type == kind and DailyGoalManager.get_progress(i) < DailyGoalManager.get_effective_target(i):
			return i
	return -1


## A recipe for an open brew-this-style goal, if it can be brewed now.
func _goal_style_recipe(b: Brewery) -> BrewRecipe:
	var slot: int = _open_goal(DailyGoalData.GoalType.BREW_STYLE)
	if slot == -1:
		return null
	return _style_recipe(b, (DailyGoalManager.active_goals[slot] as DailyGoalData).target_style)


## Share of the raid threshold where the expert closes the day. A spare strike or a hidden
## batch makes one raid survivable, so such a spec plays closer to the line.
func _close_ratio(b: Brewery) -> float:
	var strikes: int = int(b.stats.total(PerkStats.EXTRA_RAID_STRIKES))
	var strikes_left: int = InspectionService.BUSTED_RAID_COUNT + strikes - b.raid_count
	var cushioned: bool = strikes > 0 or b.stats.total(PerkStats.RAID_HIDDEN_BATCHES) > 0
	return 0.95 if cushioned and strikes_left >= 3 else 0.8


## The best-paying unlocked bar that keeps risk under EXPORT_RISK_SHARE. For a ship-to-bar
## goal it is the lowest-risk bar under the close-early line instead: failing the goal
## would add more risk than the cheapest shipment.
func _best_bar(b: Brewery, for_goal: bool = false) -> BarContact:
	var share: float = _close_ratio(b) if for_goal else EXPORT_RISK_SHARE
	var limit: float = share * b.get_effective_raid_threshold()
	var best: BarContact = null
	for bar: BarContact in CustomerRegistry.bar_contact_pool:
		if b.reputation < bar.required_reputation or b.risk + bar.risk_per_shipment > limit:
			continue
		if best == null:
			best = bar
		elif for_goal and bar.risk_per_shipment < best.risk_per_shipment:
			best = bar
		elif not for_goal and bar.price_multiplier > best.price_multiplier:
			best = bar
	return best


## Ships one batch the counter can spare: the one with the least demand, once the counter
## keeps COUNTER_STOCK bottles, or any batch while a ship-to-bar goal is open. A shipment
## must at least pay back the batch's ingredients.
func _maybe_ship(b: Brewery) -> void:
	if _ship_cooldown > 0.0 or TimeManager.day_timer.is_stopped():
		return
	_ship_cooldown = 2.0
	var goal_open: bool = _open_goal(DailyGoalData.GoalType.SHIP_TO_BAR) != -1
	if not goal_open and TimeManager.get_day_progress() < EXPORT_DAY_PROGRESS:
		return
	var bar: BarContact = _best_bar(b, goal_open)
	if bar == null:
		return
	var total: int = b.inventory.count_bottles()
	var in_stock: Dictionary = {}
	for batch: BrewBatch in b.inventory.brew_batches:
		if batch.held:
			continue
		in_stock[batch.beer_style.style] = in_stock.get(batch.beer_style.style, 0) + batch.amount_bottles
	var pick: BrewBatch = null
	var pick_demand: float = INF
	for batch: BrewBatch in b.inventory.brew_batches:
		if not goal_open and (total - batch.amount_bottles < COUNTER_STOCK or _still_aging(batch)):
			continue
		var raw_cost: float = b.resolver.get_price_breakdown(batch.beer_style).raw_cost_per_bottle
		var payout: float = BatchDistributor.calculate_ship_payout(raw_cost, batch.current_quality, batch.amount_bottles, bar.price_multiplier) * b.stats.multiplier(PerkStats.DISTRIBUTION_INCOME) * batch.get_aged_price_multiplier()
		if not goal_open and payout < raw_cost * batch.amount_bottles:
			continue
		var demand: float = _expert_demand(b, batch.beer_style.style, in_stock)
		if demand < pick_demand:
			pick_demand = demand
			pick = batch
	if pick != null:
		GUISignals.ship_batch_to_bar_requested.emit(pick, bar)


## Value of a level-up card: each stat's change from neutral times what it is worth to a
## score built on reputation, customers and money. Stats the run already has count half
## again, so the bot leans into its spec.
const CARD_WEIGHTS: Dictionary = {
	&"reputation_gain_multiplier": 100.0, &"spawn_interval_multiplier": -120.0,
	&"group_event_interval_multiplier": -50.0, &"counter_price_multiplier": 40.0,
	&"tip_income_multiplier": 20.0, &"tip_double_chance": 30.0, &"quality_bonus": 50.0,
	&"ingredient_price_multiplier": -30.0, &"brew_yield_multiplier": 20.0,
	&"distribution_income_multiplier": 20.0, &"ingredient_refund_chance": 20.0,
	&"raid_threshold_multiplier": 40.0, &"extra_raid_strikes": 3.0, &"raid_hidden_batch_count": 2.0,
	&"raid_saved_bottle_share": 5.0, &"extra_counter_slots": 3.0, &"peak_speed_multiplier": -5.0,
	&"decline_rate_multiplier": -5.0, &"agentti_appearance_multiplier": -10.0,
	&"bar_fight_chance_multiplier": -10.0,
}

func _pick_card(b: Brewery, offered: Array[RunPerk]) -> int:
	var best: int = 0
	var best_value: float = -INF
	for i: int in offered.size():
		var value: float = 0.0
		for entry: Dictionary in PerkStats.definitions():
			var change: float = float(offered[i].get(entry.stat)) - PerkStats.neutral_value(entry.kind)
			if change == 0.0:
				continue
			var owned: float = b.stats.multiplier(entry.stat) - 1.0 if entry.kind == PerkStats.Kind.MULTIPLIER else b.stats.total(entry.stat)
			value += change * CARD_WEIGHTS.get(entry.stat, 0.0) * (1.5 if owned != 0.0 else 1.0)
		if value > best_value:
			best_value = value
			best = i
	return best


## Hill climb: adds or removes one unit of an ingredient while that raises the quality and
## the style still resolves the same.
func _tune_for_quality(b: Brewery, style: BeerStyle.Style, start: Dictionary) -> Dictionary:
	var ids: Array[int] = []
	for id: int in IngredientDatabase.database:
		var item: IngredientData = IngredientDatabase.database[id]
		if not (item is YeastData) and item.min_reputation <= b.reputation:
			ids.append(id)
	var best: Dictionary = start
	var best_quality: float = _quality_of(b, best, style)
	for step: int in 30:
		var candidate: Dictionary = {}
		var candidate_quality: float = best_quality + 0.001
		for id: int in ids:
			for delta: int in [1, -1]:
				var combo: Dictionary = best.duplicate()
				var amount: int = combo.get(id, 0) + delta
				if amount < 0:
					continue
				if amount == 0:
					combo.erase(id)
				else:
					combo[id] = amount
				if _missing_cost_of(b, combo) + _reserve(b) > b.money:
					continue
				var quality: float = _quality_of(b, combo, style)
				if quality > candidate_quality:
					candidate_quality = quality
					candidate = combo
		if candidate.is_empty():
			break
		best = candidate
		best_quality = candidate_quality
	return best


func _quality_of(b: Brewery, combo: Dictionary, style: BeerStyle.Style) -> float:
	# Checked first: the resolver logs an error for every unbrewable mix.
	if not BrewMixture.from_contents(combo, IngredientDatabase.database).is_brewable():
		return -1.0
	var result: BrewResult = b.resolver.resolve_brew_style(combo)
	if result == null or not result.is_matched or result.beer_style.style != style:
		return -1.0
	return result.original_quality


## Reputation the style earns from the customers who can show up, counting the ones a
## first brew of it would unlock (like the Hipster after an IPA). A customer whose
## favourite is already well stocked counts for little, so the bot covers every taste.
## Each sale's LVV risk counts too, more as the risk nears the raid line, so customers
## whose sales pay risk off (Zgen, Alfagen) are worth unlocking when risk runs high.
func _expert_demand(b: Brewery, style: BeerStyle.Style, in_stock: Dictionary) -> float:
	var risk_weight: float = RISK_POINT_WEIGHT * b.risk / maxf(1.0, b.get_effective_raid_threshold())
	var demand: float = 0.0
	for c: CustomerData in CustomerRegistry.customer_pool:
		var unlocks: bool = c.required_discovered_style == style and b.reputation >= c.min_reputation_to_appear
		if not CustomerRegistry.is_eligible(c) and not unlocks:
			continue
		var served: float = 0.2 if in_stock.get(c.primary_style, 0) >= 10 else 1.0
		var favourite_value: float = maxf(0.0, 2.0 + c.rep_primary_style - c.risk_primary_style * risk_weight)
		# Unlocking a customer is worth half their favourite's value, whatever they think
		# of the unlocking style (the old folks unlock with Vienna but want Sahti).
		if unlocks and not CustomerRegistry.is_eligible(c):
			demand += favourite_value * 0.5
		var preference: float = c.get_preference_score(style)
		if preference >= 1.0:
			demand += favourite_value * served
		elif preference >= 0.5:
			demand += maxf(0.0, 1.0 + c.rep_secondary_style - c.risk_secondary_style * risk_weight) * served * 0.5
	return demand


## What one point of sale risk costs in reputation points at the raid line.
const RISK_POINT_WEIGHT: float = 2.0


func _all_unlocked(b: Brewery, ingredients: Dictionary) -> bool:
	for id: int in ingredients:
		if IngredientDatabase.get_item_by_id(id).min_reputation > b.reputation:
			return false
	return true


## Bottles the counter keeps unheld before the bot cellars a young batch.
const CELLAR_COUNTER_FLOOR: int = 10

## The cheapest next upgrade level, keeping UPGRADE_RESERVE for ingredients.
const UPGRADE_RESERVE: float = 150.0

func _buy_upgrade(b: Brewery) -> void:
	var best: CellarUpgradeData = null
	var best_cost: int = 0
	for upgrade: CellarUpgradeData in CellarUpgrades.all():
		var level: int = b.cellar_upgrade_levels.get(upgrade.upgrade_id, 0)
		if CellarUpgradeRules.is_maxed(level, upgrade.max_level):
			continue
		var cost: int = upgrade.cost_for_next_level(level)
		if b.money - cost >= UPGRADE_RESERVE and (best == null or cost < best_cost):
			best = upgrade
			best_cost = cost
	if best != null:
		GUISignals.cellar_upgrade_requested.emit(best.upgrade_id)
		_inc("upgrades")
		_note("upgrade %s" % best.upgrade_id)


## Score points per euro of worth and per reputation point, from RunScore.
const WORTH_POINTS: float = RunScore.WORTH_POINTS_PER_EURO
const REP_POINTS: float = RunScore.REPUTATION_POINTS
## Reputation a counter bottle earns on average, for valuing bottles an event takes.
const REP_PER_BOTTLE: float = 0.5
## Day progress after which a last-day brew would not sell before the score is taken.
const LAST_BREW_PROGRESS: float = 0.5
## Day progress where the last day turns its stock and ingredients into money.
const CASH_OUT_PROGRESS: float = 0.92


## The day before DayRules.SURVIVAL_DAY_TARGET: the run is scored as that target day
## begins, so this is the last day whose sales count.
func _is_last_day(b: Brewery) -> bool:
	return b.current_day == DayRules.SURVIVAL_DAY_TARGET - 1


## The event's change to the run score: its money and reputation, minus what it takes
## (bottles, ingredients, cash, reputation) and the risk it adds.
func _event_points(b: Brewery, e: SpecialEventData) -> float:
	var risk_change: int = -b.risk if e.clears_risk else e.reward_risk
	var points: float = e.reward_money * WORTH_POINTS + e.reward_reputation * REP_POINTS - _risk_points(b, risk_change)
	if e is ReputationFavourEventData:
		points -= (e as ReputationFavourEventData).reputation_cost * REP_POINTS
	elif e is RiskBribeEventData:
		points -= (e as RiskBribeEventData).bribe_cost * WORTH_POINTS
	elif e is IngredientDonationEventData:
		var donation := e as IngredientDonationEventData
		points -= donation.required_ingredient_amount * IngredientDatabase.get_item_by_id(donation.required_ingredient_id).base_price * WORTH_POINTS
	else:
		var batch: BrewBatch = _event_batch(b, e)
		if batch == null:
			return 0.0
		points -= e.required_bottles * _bottle_points(b, batch)
	return points


## The batch a bottle-request or quality event would take, or null if none qualifies.
func _event_batch(b: Brewery, e: SpecialEventData) -> BrewBatch:
	for batch: BrewBatch in b.inventory.brew_batches:
		if batch.amount_bottles < e.required_bottles:
			continue
		if e is QualityChallengeEventData:
			if batch.current_quality >= (e as QualityChallengeEventData).required_min_quality:
				return batch
		elif batch.beer_style.style == e.required_style:
			return batch
	return null


## What a bottle would score sold at the counter instead: its price, the bottle point
## and some reputation.
func _bottle_points(b: Brewery, batch: BrewBatch) -> float:
	var price: float = b.resolver.get_price_breakdown(batch.beer_style).price_per_bottle * batch.get_aged_price_multiplier()
	return price * WORTH_POINTS + RunScore.BOTTLE_POINTS + REP_PER_BOTTLE * REP_POINTS


## Score cost of changing risk by `delta`: each point weighs more the nearer the raid
## line it ends, and crossing the line costs a raid. Negative for risk relief.
func _risk_points(b: Brewery, delta: int) -> float:
	var threshold: float = maxf(1.0, b.get_effective_raid_threshold())
	var after: int = maxi(0, b.risk + delta)
	if after >= threshold:
		return INF
	var weight: float = RISK_POINT_WEIGHT * REP_POINTS * (b.risk + after) * 0.5 / threshold
	return (after - b.risk) * weight


## Late on the last day, or as it closes early, turns everything the score would count
## as nothing into money: ships each batch to the best-paying bar the risk allows (a raid
## now would still cost reputation and cash), bulk sells the rest and sells every ingredient.
func _cash_out(b: Brewery, closing: bool = false) -> void:
	if not _is_last_day(b) or not closing and TimeManager.get_day_progress() < CASH_OUT_PROGRESS:
		return
	for batch: BrewBatch in b.inventory.brew_batches.duplicate():
		var raw_cost: float = b.resolver.get_price_breakdown(batch.beer_style).raw_cost_per_bottle
		var bar: BarContact = _richest_bar_below(b, b.get_effective_raid_threshold())
		var bulk: float = BatchDistributor.calculate_bulk_sell_payout(raw_cost, batch.current_quality, batch.amount_bottles)
		if bar != null and BatchDistributor.calculate_ship_payout(raw_cost, batch.current_quality, batch.amount_bottles, bar.price_multiplier) * batch.get_aged_price_multiplier() > bulk:
			GUISignals.ship_batch_to_bar_requested.emit(batch, bar)
			_inc("cash_out_ships")
		else:
			GUISignals.bulk_sell_batch_requested.emit(batch)
			_inc("cash_out_bulk")
	for kind: Variant in b.inventory.items:
		for id: int in b.inventory.items[kind].keys():
			var amount: int = b.inventory.items[kind][id].amount
			if amount > 0:
				GUISignals.sell_ingredient.emit(id, amount)
				_inc("cash_out_ingredients", amount)


## The best-paying unlocked bar whose shipment keeps risk below `limit`.
func _richest_bar_below(b: Brewery, limit: float) -> BarContact:
	var best: BarContact = null
	for bar: BarContact in CustomerRegistry.bar_contact_pool:
		if b.reputation < bar.required_reputation or b.risk + bar.risk_per_shipment >= limit:
			continue
		if best == null or bar.price_multiplier > best.price_multiplier:
			best = bar
	return best


## Cash kept back when buying a brew's ingredients. Only a euro while the cellar is empty:
## the day clock starts with the first batch and pricey ingredients leave little spare,
## but spending down to zero with no bottles is bankruptcy.
func _reserve(b: Brewery) -> int:
	return 1 if b.inventory.brew_batches.is_empty() else 10


func _missing_cost(b: Brewery, r: BrewRecipe) -> int:
	return _missing_cost_of(b, r.ingredient_amounts)


func _missing_cost_of(b: Brewery, ingredients: Dictionary) -> int:
	var cost: int = 0
	for id: int in ingredients:
		var missing: int = maxi(0, ingredients[id] - _owned(b, id))
		cost += IngredientDatabase.get_item_by_id(id).base_price * missing
	# Perks' price changes are folded into this stat, as the trader charges it.
	return roundi(cost * b.stats.multiplier(PerkStats.INGREDIENT_PRICE))


func _owned(b: Brewery, id: int) -> int:
	var item: InventoryItem = b.inventory.get_item_by_id(id)
	return item.amount if item != null else 0


## Every perk stat that differs from neutral at the end of the run.
func _stat_snapshot(b: Brewery) -> Dictionary:
	var snapshot: Dictionary = {}
	for entry: Dictionary in PerkStats.definitions():
		var value: float = b.stats.multiplier(entry.stat) if entry.kind == PerkStats.Kind.MULTIPLIER else b.stats.total(entry.stat)
		if not is_equal_approx(value, PerkStats.neutral_value(entry.kind)):
			snapshot[entry.stat] = snappedf(value, 0.001)
	return snapshot


func _finish(b: Brewery) -> void:
	_done = true
	var report: Dictionary = {
		"strategy": cfg.strategy, "profile": cfg.get("profile", ""), "ending": ending if ending != "" else "day_limit",
		"final": {"day": b.current_day, "rep": b.reputation, "money": snappedf(b.money, 0.1), "raids": b.raid_count, "level": b.run_level, "standing": b.customer_standing, "upgrades": b.cellar_upgrade_levels, "worth": RunScore.brewery_worth(b), "score": RunScore.entry_for(b, ending).score, "bottles": b.lifetime_bottles_sold},
		"days": days, "counts": counts, "notes": notes, "stats": _stat_snapshot(b), "perks": b.active_perks.size(),
	}
	var f := FileAccess.open(cfg.out, FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  "))
	f.close()
	get_tree().quit()
