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

var cfg: Dictionary = {}
var days: Array = []
var notes: Array = []
var counts: Dictionary = {}
var ending: String = ""
var _tick: float = 0.0
var _brew_cooldown: float = 0.0
var _done: bool = false
var _pending_recap: String = ""


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
	BrewerySignals.bottles_sold.connect(func(n: int) -> void: _inc("bottles", n))
	BrewerySignals.bar_fight_triggered.connect(func(_m: String) -> void: _inc("bar_fights"))
	BrewerySignals.game_ended.connect(func(t: String) -> void: ending = t)
	CustomerRegistry.customer_unlocked.connect(func(t: String) -> void: _note("unlocked %s" % t))
	TimeManager.day_changed.connect(_on_day_changed)


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
			w._on_card_pressed(randi() % 3)
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
	if cfg.strategy in ["careful", "expert"] and not TimeManager.day_timer.is_stopped() and b.risk >= 0.8 * b.get_effective_raid_threshold():
		_inc("early_closes")
		TimeManager.force_advance_day()
		return
	if _brew_cooldown <= 0.0 and _needs_brew(b):
		_brew(b)
	if cfg.strategy == "expert":
		_buy_upgrade(b)


func _wants_event(b: Brewery, e: SpecialEventData) -> bool:
	var threshold: int = b.get_effective_raid_threshold()
	match cfg.strategy:
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
	if cfg.strategy == "expert":
		return b.inventory.count_bottles() < 40 or b.inventory.brew_batches.size() < 3
	if cfg.strategy in ["variety", "careful"]:
		return b.inventory.count_bottles() < 30 or b.inventory.brew_batches.size() < 2
	return b.inventory.count_bottles() < 15


func _brew(b: Brewery) -> void:
	if cfg.strategy == "expert":
		_brew_recipe(b, _expert_recipe(b))
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
		if cost + 10 > b.money:
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
	GUISignals.load_recipe_requested.emit(recipe)
	GUISignals.start_brewing.emit()
	_inc("brews")
	_inc("brew:" + BeerStyle.get_style_string_from_style(recipe.beer_style))
	_brew_cooldown = 3.0


## The best style to brew next, from every style the unlocked ingredients can make.
func _expert_recipe(b: Brewery) -> BrewRecipe:
	var in_stock: Dictionary = {}
	for batch: BrewBatch in b.inventory.brew_batches:
		in_stock[batch.beer_style.style] = in_stock.get(batch.beer_style.style, 0) + batch.amount_bottles

	var best: BrewRecipe = null
	var best_score: float = -INF
	for style: BeerStyle in b.resolver.active_styles:
		var ingredients: Dictionary = b.resolver.compute_minimum_ingredients(style)
		if ingredients.is_empty() or not _all_unlocked(b, ingredients):
			continue
		var cost: int = _missing_cost_of(b, ingredients)
		if cost + 10 > b.money:
			continue
		var score: float = _expert_demand(b, style.style, in_stock)
		if score <= 0.0:
			continue
		if not b.brewed_styles.has(style.style):
			score += maxi(0, style.reputation_change)
		score += b.resolver.get_style_base_price(style) - b.resolver.get_style_cost_per_bottle(style)
		if score > best_score:
			best_score = score
			var recipe := BrewRecipe.new()
			recipe.beer_style = style.style
			recipe.ingredient_amounts = ingredients
			best = recipe
	return best


## Reputation the style earns from the customers who can show up, counting the ones a
## first brew of it would unlock (like the Hipster after an IPA). A customer whose
## favourite is already well stocked counts for little, so the bot covers every taste.
func _expert_demand(b: Brewery, style: BeerStyle.Style, in_stock: Dictionary) -> float:
	var demand: float = 0.0
	for c: CustomerData in CustomerRegistry.customer_pool:
		var unlocks: bool = c.required_discovered_style == style and b.reputation >= c.min_reputation_to_appear
		if not CustomerRegistry.is_eligible(c) and not unlocks:
			continue
		var served: float = 0.2 if in_stock.get(c.primary_style, 0) >= 10 else 1.0
		var preference: float = c.get_preference_score(style)
		if preference >= 1.0:
			demand += (2.0 + c.rep_primary_style) * served
		elif preference >= 0.5:
			demand += (1.0 + c.rep_secondary_style) * served * 0.5
	return demand


func _all_unlocked(b: Brewery, ingredients: Dictionary) -> bool:
	for id: int in ingredients:
		if IngredientDatabase.get_item_by_id(id).min_reputation > b.reputation:
			return false
	return true


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


func _missing_cost(b: Brewery, r: BrewRecipe) -> int:
	return _missing_cost_of(b, r.ingredient_amounts)


func _missing_cost_of(b: Brewery, ingredients: Dictionary) -> int:
	var cost: int = 0
	for id: int in ingredients:
		var missing: int = maxi(0, ingredients[id] - _owned(b, id))
		cost += IngredientDatabase.get_item_by_id(id).base_price * missing
	return cost


func _owned(b: Brewery, id: int) -> int:
	var item: InventoryItem = b.inventory.get_item_by_id(id)
	return item.amount if item != null else 0


func _finish(b: Brewery) -> void:
	_done = true
	var report: Dictionary = {
		"strategy": cfg.strategy, "profile": cfg.get("profile", ""), "ending": ending if ending != "" else "day_limit",
		"final": {"day": b.current_day, "rep": b.reputation, "money": snappedf(b.money, 0.1), "raids": b.raid_count, "level": b.run_level, "standing": b.customer_standing, "upgrades": b.cellar_upgrade_levels, "worth": RunScore.brewery_worth(b)},
		"days": days, "counts": counts, "notes": notes,
	}
	var f := FileAccess.open(cfg.out, FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  "))
	f.close()
	get_tree().quit()
