class_name SaleProcessor
extends RefCounted

## Resolves one customer's purchase against a Brewery: picks the batch, works
## out income, tip and reputation, applies them, and reports through
## BrewerySignals. The batch choice and the money maths are static so they can
## be unit-tested without a live run.

const BOTTLES_SOLD_PER_TRANSACTION : int = 1
const QUALITY_BONUS_WEIGHT : float = 0.2
const REGULAR_RESPONSE_FORMAT : String = "Taas täällä! %s"


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
		if batch.amount_bottles <= 0 or batch.held:
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
static func calculate_sale(results : Dictionary, bottles_sold : int, tip_multiplier : float, tip_double_chance : float, reputation_multiplier : float) -> SaleOutcome:
	var outcome := SaleOutcome.new()
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
	var is_regular : bool = RegularRules.is_regular(brewery.customer_standing.get(data.title, 0)) if brewery != null else false
	var wanted : int = randi_range(data.min_bottles_per_visit, data.max_bottles_per_visit)
	if is_regular:
		wanted += RegularRules.EXTRA_BOTTLES
	var best_batch : BrewBatch = find_best_batch_for(data)
	if best_batch == null or best_batch.amount_bottles < BOTTLES_SOLD_PER_TRANSACTION:
		return _turn_away(data, wanted)

	# The net reputation change, including any bar fight below, is reported as
	# one popup-friendly delta at the end.
	var reputation_before : int = brewery.reputation

	var breakdown : SaleBreakdown = brewery.resolver.get_price_breakdown(best_batch.beer_style)
	# The marketing perk marks up this sale's price only, never the shared breakdown.
	var counter_price : float = breakdown.price_per_bottle * brewery.stats.multiplier(PerkStats.COUNTER_PRICE) * best_batch.get_aged_price_multiplier()
	var results : Dictionary = data.evaluate_brew_batch(best_batch, counter_price)

	var bottles_sold : int = mini(wanted, best_batch.amount_bottles)

	var outcome : SaleOutcome = calculate_sale(
		results,
		bottles_sold,
		brewery.stats.multiplier(PerkStats.TIP_INCOME) * (RegularRules.TIP_MULTIPLIER if is_regular else 1.0),
		brewery.stats.chance(PerkStats.TIP_DOUBLE_CHANCE),
		brewery.stats.multiplier(PerkStats.REPUTATION_GAIN))

	brewery.money += outcome.net_income
	brewery.change_reputation(outcome.reputation_gain, ReputationRules.Source.CUSTOMERS)
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
	receipt_entry.beer_ebc = best_batch.final_ebc
	brewery.today_sale_receipts.append(receipt_entry)
	BrewerySignals.beer_sale_breakdown.emit(receipt_entry)

	best_batch.amount_bottles -= bottles_sold
	if best_batch.amount_bottles <= 0:
		brewery.inventory.brew_batches.erase(best_batch)

	brewery.lifetime_bottles_sold += bottles_sold
	BrewerySignals.bottles_sold.emit(bottles_sold)

	var response_text : String = results[CustomerManager.KEY_RESPONSE]
	if is_regular and results[CustomerManager.KEY_DELIGHTED]:
		response_text = tr(REGULAR_RESPONSE_FORMAT) % response_text
	response_text += QualityWishText.reject_suffix(best_batch.current_quality, data.min_quality)

	if BarFightRules.breaks_out(data, wanted, bottles_sold, brewery.stats.multiplier(PerkStats.BAR_FIGHT_CHANCE), randf()):
		_trigger_bar_fight(data, best_batch)

	BrewerySignals.sale_reputation_gained.emit(brewery.reputation - reputation_before)
	BrewerySignals.brewery_state_changed.emit(brewery)
	_spread_word(data, results[CustomerManager.KEY_DELIGHTED], outcome.reputation_gain)
	_update_standing(data, results[CustomerManager.KEY_DELIGHTED], outcome.reputation_gain)
	BrewerySignals.customer_served.emit(data)
	return response_text


## Nothing in stock, or nothing that clears the customer's strict requirements:
## they leave without buying. The penalty is per customer, and can be zero for
## one who was never offered anything, like an Agentti whose cover story did not
## match what is on tap.
func _turn_away(data : CustomerData, wanted : int) -> String:
	if brewery != null:
		var reputation_before : int = brewery.reputation
		brewery.change_reputation(-data.no_match_reputation_penalty, ReputationRules.Source.CUSTOMERS)
		brewery.add_risk(data.no_match_risk_penalty)
		BrewerySignals.customer_unhappy.emit()
		# A customer who fights over missing beer does it right here, before leaving.
		if BarFightRules.breaks_out(data, wanted, 0, brewery.stats.multiplier(PerkStats.BAR_FIGHT_CHANCE), randf()):
			_trigger_bar_fight(data, null)
		BrewerySignals.sale_reputation_gained.emit(brewery.reputation - reputation_before)
		BrewerySignals.brewery_state_changed.emit(brewery)
		_spread_word(data, false, -data.no_match_reputation_penalty)
		_update_standing(data, false, -data.no_match_reputation_penalty)
	return data.dialogue_no_match


func _update_standing(data : CustomerData, delighted : bool, reputation_gain : int) -> void:
	if data.title.is_empty():
		return
	var before : int = brewery.customer_standing.get(data.title, 0)
	var after : int = RegularRules.next_standing(before, delighted, reputation_gain)
	brewery.customer_standing[data.title] = after
	if RegularRules.is_regular(after) != RegularRules.is_regular(before):
		BrewerySignals.regular_status_changed.emit(data.title, RegularRules.is_regular(after))


func _spread_word(data : CustomerData, delighted : bool, reputation_gain : int) -> void:
	match WordOfMouthRules.outcome(delighted, reputation_gain, randf()):
		WordOfMouthRules.Outcome.FRIEND:
			BrewerySignals.friend_recommended.emit(data)
		WordOfMouthRules.Outcome.BAD_REVIEW:
			BrewerySignals.bad_review_spread.emit()


## Reported through bar_fight_triggered as its own toast, not the customer's spoken
## line. `batch` is the one just sold from, or null when the customer was turned away;
## then the broken bottles come from a random batch in the cellar, if there is any.
func _trigger_bar_fight(data : CustomerData, batch : BrewBatch) -> void:
	brewery.change_reputation(-data.bar_fight_reputation_penalty, ReputationRules.Source.CUSTOMERS)
	brewery.add_risk(data.bar_fight_risk_penalty)
	if batch == null and not brewery.inventory.brew_batches.is_empty():
		batch = brewery.inventory.brew_batches.pick_random()

	var broken_bottles : int = 0
	if data.bar_fight_max_bottles_broken > 0 and brewery.inventory.brew_batches.has(batch):
		broken_bottles = mini(randi_range(1, data.bar_fight_max_bottles_broken), batch.amount_bottles)
		batch.amount_bottles = max(0, batch.amount_bottles - broken_bottles)

		if batch.amount_bottles <= 0:
			brewery.inventory.brew_batches.erase(batch)

	BrewerySignals.bar_fight_triggered.emit(data.dialogue_bar_fight % broken_bottles)
	BrewerySignals.bar_fight_started.emit(broken_bottles)
