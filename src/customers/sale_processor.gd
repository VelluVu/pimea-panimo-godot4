class_name SaleProcessor
extends RefCounted

## Resolves one customer's purchase against a Brewery: picks the batch, works
## out income, tip and reputation, applies them, and reports through
## BrewerySignals. The batch choice and the money maths are static so they can
## be unit-tested without a live run.

const BOTTLES_SOLD_PER_TRANSACTION : int = 1
const QUALITY_BONUS_WEIGHT : float = 0.2


## What a sale is worth, before it is applied to the Brewery.
class Outcome:
	var gross_income : float = 0.0
	var tip_income : float = 0.0
	var net_income : float = 0.0
	var reputation_gain : int = 0


var brewery : Brewery


## `owner` may be null when no run is active: nothing is in stock then.
func _init(owner : Brewery) -> void:
	brewery = owner


## The batch the customer would buy from, or null. A strict requirement makes a
## batch invisible to the customer, not just a worse option.
static func find_best_batch(batches : Array[BrewBatch], data : CustomerData) -> BrewBatch:
	var best_batch : BrewBatch = null
	var best_score : float = -1.0

	for batch : BrewBatch in batches:
		if batch.amount_bottles <= 0:
			continue
		if not data.meets_strict_requirements(batch.beer_style):
			continue
		var score : float = data.get_preference_score(batch.beer_style.style)
		if batch.current_quality >= data.min_quality:
			score += QUALITY_BONUS_WEIGHT
		if score > best_score:
			best_score = score
			best_batch = batch
	return best_batch


## Income, tip and reputation for `bottles_sold` bottles. `results` is
## CustomerData.evaluate_brew_batch()'s per-bottle answer. Amounts are snapped
## to 0.1 so repeated float maths cannot leave noise in the till. There is no
## tax: the fixed price plus any tip is exactly what lands in the till. A
## doubled tip is rolled after the tip multiplier, so it keeps every other bonus.
static func calculate_sale(results : Dictionary, bottles_sold : int, tip_multiplier : float, tip_double_chance : float, reputation_multiplier : float) -> Outcome:
	var outcome := Outcome.new()
	outcome.gross_income = snappedf(results[CustomerManager.KEY_INCOME] * bottles_sold, 0.1)

	var tip : float = snappedf(results[CustomerManager.KEY_TIP] * bottles_sold * tip_multiplier, 0.1)
	if tip > 0.0 and randf() < tip_double_chance:
		tip = snappedf(tip * 2.0, 0.1)
	outcome.tip_income = tip

	outcome.net_income = snappedf(outcome.gross_income + tip, 0.1)
	outcome.reputation_gain = roundi(results[CustomerManager.KEY_REPUTATION] * reputation_multiplier)
	return outcome


## Public so a customer can preview its pick as a dialogue beat before the sale
## resolves; the decision itself stays with the customer.
func find_best_batch_for(data : CustomerData) -> BrewBatch:
	if brewery == null:
		return null
	return find_best_batch(brewery.inventory.brew_batches, data)


## Returns the customer's spoken response.
func process(data : CustomerData) -> String:
	var best_batch : BrewBatch = find_best_batch_for(data)
	if best_batch == null or best_batch.amount_bottles < BOTTLES_SOLD_PER_TRANSACTION:
		return _turn_away(data)

	# The net reputation change, including any bar fight below, is reported as
	# one popup-friendly delta at the end.
	var reputation_before : int = brewery.reputation

	var breakdown : SaleBreakdown = brewery.resolver.get_price_breakdown(best_batch.beer_style)
	# The marketing perk marks up this sale's price only, never the shared breakdown.
	var counter_price : float = breakdown.price_per_bottle * brewery.stats.multiplier(PerkStats.COUNTER_PRICE)
	var results : Dictionary = data.evaluate_brew_batch(best_batch, counter_price)

	var bottles_sold : int = randi_range(data.min_bottles_per_visit, data.max_bottles_per_visit)
	bottles_sold = mini(bottles_sold, best_batch.amount_bottles)

	var outcome : Outcome = calculate_sale(
		results,
		bottles_sold,
		brewery.stats.multiplier(PerkStats.TIP_INCOME),
		brewery.stats.chance(PerkStats.TIP_DOUBLE_CHANCE),
		brewery.stats.multiplier(PerkStats.REPUTATION_GAIN))

	brewery.money += outcome.net_income
	brewery.reputation = max(0, brewery.reputation + outcome.reputation_gain)
	if outcome.reputation_gain < 0:
		BrewerySignals.customer_unhappy.emit()
	brewery.add_risk(results[CustomerManager.KEY_RISK])
	var sale_xp : int = Brewery.XP_PER_BOTTLE_SOLD * bottles_sold
	brewery.add_xp(sale_xp)
	BrewerySignals.sale_xp_gained.emit(sale_xp)
	BrewerySignals.sale_tip_gained.emit(outcome.tip_income)

	var receipt_entry := SaleReceiptEntry.new()
	receipt_entry.breakdown = breakdown
	receipt_entry.bottles_sold = bottles_sold
	receipt_entry.gross_income = outcome.gross_income
	receipt_entry.tip_income = outcome.tip_income
	receipt_entry.net_income = outcome.net_income
	brewery.today_sale_receipts.append(receipt_entry)
	BrewerySignals.beer_sale_breakdown.emit(receipt_entry)

	best_batch.amount_bottles -= bottles_sold
	if best_batch.amount_bottles <= 0:
		brewery.inventory.brew_batches.erase(best_batch)

	brewery.lifetime_bottles_sold += bottles_sold
	BrewerySignals.bottles_sold.emit(bottles_sold)

	var response_text : String = results[CustomerManager.KEY_RESPONSE]

	var bar_fight_chance : float = data.bar_fight_chance * brewery.stats.multiplier(PerkStats.BAR_FIGHT_CHANCE)
	if bar_fight_chance > 0.0 and randf() < bar_fight_chance:
		_trigger_bar_fight(data, best_batch)

	BrewerySignals.sale_reputation_gained.emit(brewery.reputation - reputation_before)
	BrewerySignals.brewery_state_changed.emit(brewery)
	return response_text


## Nothing in stock, or nothing that clears the customer's strict requirements:
## they leave without buying. The penalty is per customer, and can be zero for
## one who was never offered anything, like an Agentti whose cover story did not
## match what is on tap.
func _turn_away(data : CustomerData) -> String:
	if brewery != null:
		brewery.reputation = max(0, brewery.reputation - data.no_match_reputation_penalty)
		brewery.add_risk(data.no_match_risk_penalty)
		BrewerySignals.sale_reputation_gained.emit(-data.no_match_reputation_penalty)
		BrewerySignals.customer_unhappy.emit()
		BrewerySignals.brewery_state_changed.emit(brewery)
	return data.dialogue_no_match


## Reported through bar_fight_triggered as its own toast, not the customer's
## spoken line.
func _trigger_bar_fight(data : CustomerData, batch : BrewBatch) -> void:
	brewery.reputation = max(0, brewery.reputation - data.bar_fight_reputation_penalty)
	brewery.add_risk(data.bar_fight_risk_penalty)

	var broken_bottles : int = 0
	if data.bar_fight_max_bottles_broken > 0 and brewery.inventory.brew_batches.has(batch):
		broken_bottles = randi_range(1, data.bar_fight_max_bottles_broken)
		batch.amount_bottles = max(0, batch.amount_bottles - broken_bottles)

		if batch.amount_bottles <= 0:
			brewery.inventory.brew_batches.erase(batch)

	BrewerySignals.bar_fight_triggered.emit(data.dialogue_bar_fight % broken_bottles)
