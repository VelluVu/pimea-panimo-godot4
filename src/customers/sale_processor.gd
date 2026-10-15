class_name SaleProcessor
extends RefCounted

## Resolves one customer's purchase against a Brewery: picks the batch, works
## out income, tip and reputation, applies them, and reports through
## BrewerySignals. The batch choice and the money maths are static so they can
## be unit-tested without a live run.

const BOTTLES_SOLD_PER_TRANSACTION : int = 1
## A batch good enough for the customer always beats one that is not: below their bar
## they refuse it (_refuse_bad_quality), so the choice must not settle for it.
const QUALITY_BONUS_WEIGHT : float = 10.0
const REGULAR_RESPONSE_FORMAT : String = "Taas täällä! %s"
const KEY_REPUTATION_GAIN : String = "reputation_gain"
const KEY_BOTTLES_SOLD : String = "bottles_sold"


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
		if not _on_offer(batch, data):
			continue
		var score : float = data.get_batch_preference(batch)
		if batch.current_quality >= data.min_quality:
			score += QUALITY_BONUS_WEIGHT
		if score > best_score:
			best_score = score
			best_batch = batch
	return best_batch


## The batches the customer buys from: the best one, or for a picks_at_random customer up
## to `count` random batches of different styles that clear their bar. With none clearing
## it, the best batch comes back so the customer can refuse it.
static func pick_batches(batches : Array[BrewBatch], data : CustomerData, count : int = 1) -> Array[BrewBatch]:
	var picks : Array[BrewBatch] = []
	if data.picks_at_random:
		var candidates : Array[BrewBatch] = []
		for batch : BrewBatch in batches:
			if _on_offer(batch, data) and batch.current_quality >= data.min_quality:
				candidates.append(batch)
		candidates.shuffle()
		var styles_taken : Array[BeerStyle.Style] = []
		for batch : BrewBatch in candidates:
			if picks.size() >= count:
				break
			if styles_taken.has(batch.beer_style.style):
				continue
			styles_taken.append(batch.beer_style.style)
			picks.append(batch)
	if picks.is_empty():
		var best : BrewBatch = find_best_batch(batches, data)
		if best != null:
			picks.append(best)
	return picks


static func _on_offer(batch : BrewBatch, data : CustomerData) -> bool:
	return batch.amount_bottles > 0 and not batch.held and data.accepts_batch(batch)


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
		outcome.tip_doubled = true
	outcome.tip_income = tip

	outcome.net_income = snappedf(outcome.gross_income + tip, 0.1)
	outcome.reputation_gain = roundi(results[CustomerManager.KEY_REPUTATION] * reputation_multiplier)
	return outcome


## Public so a customer can preview its picks before the sale. Rolls how many styles this
## visit buys (see pick_batches()), so it is called once and the result handed to process().
func pick_batches_for(data : CustomerData) -> Array[BrewBatch]:
	if brewery == null:
		return []
	return pick_batches(brewery.inventory.brew_batches, data, randi_range(1, maxi(1, data.max_styles_per_visit)))


## Returns the customer's spoken response. `picks` are the batches the customer already
## previewed; any that sold out meanwhile are dropped, and none left means a fresh pick.
func process(data : CustomerData, picks : Array[BrewBatch] = []) -> String:
	if data.browses_only:
		return tr(data.dialogue_no_match)
	var is_regular : bool = RegularRules.is_regular(brewery.customer_standing.get(data.title, 0)) if brewery != null else false
	var wanted : int = randi_range(data.min_bottles_per_visit, data.max_bottles_per_visit)
	if is_regular:
		wanted += RegularRules.EXTRA_BOTTLES
	var batches : Array[BrewBatch] = []
	for batch : BrewBatch in picks:
		if brewery != null and brewery.inventory.brew_batches.has(batch) and _on_offer(batch, data):
			batches.append(batch)
	if batches.is_empty():
		batches = pick_batches_for(data)
	if batches.is_empty() or batches[0].amount_bottles < BOTTLES_SOLD_PER_TRANSACTION:
		return _turn_away(data, wanted)
	if refuses(batches[0].current_quality, data.min_quality):
		return _refuse_bad_quality(data, batches[0].current_quality)

	# The net reputation change, including any bar fight below, is reported as
	# one popup-friendly delta at the end.
	var reputation_before : int = brewery.reputation
	var response_text : String = ""
	var delighted : bool = false
	var reputation_gain : int = 0
	var bottles_sold : int = 0
	var last_batch : BrewBatch = null
	for batch : BrewBatch in batches:
		if refuses(batch.current_quality, data.min_quality):
			continue
		var results : Dictionary = _sell(data, batch, wanted, is_regular)
		if response_text.is_empty():
			response_text = results[CustomerManager.KEY_RESPONSE]
		delighted = delighted or results[CustomerManager.KEY_DELIGHTED]
		reputation_gain += results[KEY_REPUTATION_GAIN]
		bottles_sold += results[KEY_BOTTLES_SOLD]
		last_batch = batch

	if is_regular and delighted:
		response_text = tr(REGULAR_RESPONSE_FORMAT) % response_text

	if BarFightRules.breaks_out(data, wanted * batches.size(), bottles_sold, brewery.stats.multiplier(PerkStats.BAR_FIGHT_CHANCE), randf()):
		_trigger_bar_fight(data, last_batch)

	BrewerySignals.sale_reputation_gained.emit(brewery.reputation - reputation_before)
	BrewerySignals.brewery_state_changed.emit(brewery)
	_spread_word(data, delighted, reputation_gain)
	_update_standing(data, delighted, reputation_gain)
	BrewerySignals.customer_served.emit(data)
	return response_text


## Sells up to `wanted` bottles from one batch and applies money, reputation, risk and
## xp. Returns evaluate_brew_batch()'s results plus KEY_REPUTATION_GAIN and KEY_BOTTLES_SOLD.
func _sell(data : CustomerData, batch : BrewBatch, wanted : int, is_regular : bool) -> Dictionary:
	var breakdown : SaleBreakdown = brewery.resolver.get_price_breakdown(batch.beer_style)
	# The marketing perk marks up this sale's price only, never the shared breakdown.
	var counter_price : float = breakdown.price_per_bottle * brewery.stats.multiplier(PerkStats.COUNTER_PRICE) * batch.get_aged_price_multiplier() \
			* FirstBrewRules.price_multiplier(batch.novelty)
	var results : Dictionary = data.evaluate_brew_batch(batch, counter_price)

	var bottles_sold : int = mini(wanted, batch.amount_bottles)

	var outcome : SaleOutcome = calculate_sale(
		results,
		bottles_sold,
		brewery.stats.multiplier(PerkStats.TIP_INCOME) * (RegularRules.TIP_MULTIPLIER if is_regular else 1.0),
		brewery.stats.chance(PerkStats.TIP_DOUBLE_CHANCE),
		brewery.stats.multiplier(PerkStats.REPUTATION_GAIN))

	brewery.change_money(outcome.gross_income, MoneyLedger.Source.SALES)
	brewery.change_money(outcome.tip_income, MoneyLedger.Source.TIPS)
	brewery.change_reputation(outcome.reputation_gain, ReputationRules.Source.CUSTOMERS)
	if outcome.reputation_gain < 0:
		BrewerySignals.customer_unhappy.emit()
	var risk_multiplier : float = batch.get_aged_risk_multiplier() * brewery.stats.multiplier(PerkStats.SALE_RISK)
	brewery.add_risk(SaleEvaluation.discreet_risk(results[CustomerManager.KEY_RISK], risk_multiplier, randf()))
	var sale_xp : int = Brewery.XP_PER_BOTTLE_SOLD * bottles_sold
	brewery.add_xp(sale_xp)
	BrewerySignals.sale_xp_gained.emit(sale_xp)
	BrewerySignals.sale_tip_gained.emit(outcome.tip_income)
	BrewerySignals.sale_popup_tiers_rated.emit(PopupTierRules.tip_tier(outcome.tip_income, outcome.gross_income, outcome.tip_doubled), batch.current_quality)

	var receipt_entry := SaleReceiptEntry.new()
	receipt_entry.breakdown = breakdown
	receipt_entry.bottles_sold = bottles_sold
	receipt_entry.gross_income = outcome.gross_income
	receipt_entry.tip_income = outcome.tip_income
	receipt_entry.net_income = outcome.net_income
	receipt_entry.beer_ebc = batch.final_ebc
	receipt_entry.batch = batch
	receipt_entry.aged_price_multiplier = batch.get_aged_price_multiplier()
	brewery.today_sale_receipts.append(receipt_entry)
	BrewerySignals.beer_sale_breakdown.emit(receipt_entry)

	batch.amount_bottles -= bottles_sold
	if batch.amount_bottles <= 0:
		brewery.inventory.remove_batch(batch)

	brewery.lifetime_bottles_sold += bottles_sold
	BrewerySignals.bottles_sold.emit(bottles_sold)

	results[KEY_REPUTATION_GAIN] = outcome.reputation_gain
	results[KEY_BOTTLES_SOLD] = bottles_sold
	return results


## Below the customer's quality bar nothing is bought: their reject line says so.
static func refuses(quality : float, min_quality : float) -> bool:
	return quality < min_quality


## Nothing good enough on offer: no sale, the bad-quality reputation and risk, an unhappy
## customer. The beer stays in storage; the line tells how far the batch missed the bar.
func _refuse_bad_quality(data : CustomerData, quality : float) -> String:
	if brewery != null:
		var penalty : Vector2i = SaleEvaluation.refusal(data, quality)
		var reputation_before : int = brewery.reputation
		brewery.change_reputation(penalty.x, ReputationRules.Source.CUSTOMERS)
		brewery.add_risk(penalty.y)
		BrewerySignals.customer_unhappy.emit()
		BrewerySignals.sale_reputation_gained.emit(brewery.reputation - reputation_before)
		BrewerySignals.brewery_state_changed.emit(brewery)
		_spread_word(data, false, penalty.x)
		_update_standing(data, false, penalty.x)
	return tr(data.dialogue_reject) + QualityWishText.reject_suffix(quality, data.min_quality)


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
	return tr(data.dialogue_no_match)


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
			brewery.inventory.remove_batch(batch)

	BrewerySignals.bar_fight_triggered.emit(tr(data.dialogue_bar_fight) % broken_bottles)
	BrewerySignals.bar_fight_started.emit(broken_bottles)
