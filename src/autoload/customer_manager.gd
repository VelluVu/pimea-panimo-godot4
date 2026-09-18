#CustomerManager (Autoload)
extends Node


const KEY_INCOME = "income"
const KEY_TIP = "tip"
const KEY_REPUTATION = "reputation"
const KEY_RISK = "risk"
const KEY_RESPONSE = "response"

const BOTTLES_SOLD_PER_TRANSACTION = 1
const QUALITY_BONUS_WEIGHT = 0.2

## Small cost for turning a customer away with nothing to sell them at all
## (see process_auto_sale()'s no-match branch) — they complain loudly on
## the way out, so it's not the fully free non-event it used to be, just
## much smaller than an actual bad-quality or wrong-style sale.
const NO_MATCH_REPUTATION_PENALTY : int = 1
const NO_MATCH_RISK_PENALTY : int = 1

const DELAY_AUTO_SALE_SECONDS = 2.0
const DELAY_CLEAR_REFS_SECONDS = 3.5

const WARNING_TIME_MANAGER_NOT_FOUND = "CustomerManager: TimeManager Autoload not found!"
const WARNING_DIALOG_VIEW_NOT_FOUND = "CustomerManager: DialogView not found for positioning!"

var occupied_slots: Array[bool] = [false, false, false, false, false]
var slot_occupant_counts: Array[int] = [0, 0, 0, 0, 0]
var active_customers: Dictionary = {}
var active_spawner: CustomerSpawner = null


func _ready() -> void:

	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)
	BrewerySignals.beer_brewed.connect(_on_beer_brewed)


## A matching brew just finished — reward the player with an immediate
## walk-in who specifically wants that style, instead of waiting on the
## ambient spawn timer to eventually roll one who happens to want it.
func _on_beer_brewed(style: int) -> void:
	spawn_normal_customer(CustomerRegistry.get_customer_for_style(style))


func register_spawner(spawner: CustomerSpawner) -> void:
	active_spawner = spawner

	# A fresh CustomerSpawner means a fresh main.tscn — any customer nodes
	# from a previous session are already gone (freed with the old scene),
	# so slots they never got to vacate (e.g. the player left mid-visit via
	# the main menu) must not stay marked occupied forever.
	occupied_slots = [false, false, false, false, false]
	slot_occupant_counts = [0, 0, 0, 0, 0]
	active_customers.clear()

	if BrewEngine.current_brewery and not BrewEngine.current_brewery.inventory.brew_batches.is_empty():
		active_spawner.start_spawning()


## Used to warn before closing the day — a customer who's walked in but
## hasn't finished their interaction yet would otherwise lose their sale
## with no feedback when the day advances out from under them.
func has_active_customers() -> bool:
	return not active_customers.is_empty()


## Called by TimeManager.force_advance_day() when the day is force-closed
## anyway (the player confirmed CloseDayConfirmWindow's warning, or the dev
## console's "day" cheat) — anyone still being served gets thrown out
## instead of finishing their purchase. queue_free() alone is what actually
## cancels a solo customer's in-progress sale: their whole
## intro/preview/sale/leave sequence is a chain of
## get_tree().create_timer(...).timeout.connect(self.method) calls (see
## Customer.gd), and a SceneTreeTimer whose target has been freed simply
## never fires — no separate "cancel" flag needed. Their walk/leave Tween
## is bound to the node the same way and dies with it. A group visit's
## shared order is the one exception (it runs as a single coroutine on
## CustomerSpawner, not a per-member timer chain) — see
## CustomerSpawner._run_shared_group_order()'s own member-validity guard
## for how that path is cancelled instead.
func evict_active_customers() -> void:
	if active_customers.is_empty():
		return

	for slot : int in active_customers.keys():
		var customer : Node2D = active_customers[slot]
		if is_instance_valid(customer):
			BrewerySignals.customer_evicted.emit(customer.dialogue_slot)
			customer.queue_free()

	occupied_slots = [false, false, false, false, false]
	slot_occupant_counts = [0, 0, 0, 0, 0]
	active_customers.clear()


func get_free_slot_index() -> int:
	for i in range(occupied_slots.size()):
		if not occupied_slots[i]:
			return i
	return -1


func get_random_customer_data() -> CustomerData:
	return CustomerRegistry.get_random_customer_data()


## A slot's occupant count is normally 1 (one customer). A group visit
## registers every member of the crowd against the same shared slot, so
## the count can exceed 1 while several of them are standing there at
## once — free_slot_index() only truly frees it once the last one leaves.
func register_active_customer(slot: int, node: Node2D) -> void:
	occupied_slots[slot] = true
	slot_occupant_counts[slot] += 1
	active_customers[slot] = node


func free_slot_index(slot: int) -> void:
	slot_occupant_counts[slot] = maxi(0, slot_occupant_counts[slot] - 1)
	if slot_occupant_counts[slot] > 0:
		return

	if active_customers.has(slot):
		active_customers.erase(slot)
	occupied_slots[slot] = false


func _on_brewery_state_changed(brewery: Brewery) -> void:
	if active_spawner and not brewery.inventory.brew_batches.is_empty():
		active_spawner.start_spawning()
	

## Public so a customer can preview what it's about to pick (shown as a
## dialogue beat) before process_auto_sale() actually resolves the sale —
## the decision itself stays entirely the customer's, this just makes it
## visible instead of an invisible dice roll.
func find_best_batch_for(data: CustomerData) -> BrewBatch:
	if BrewEngine.current_brewery == null:
		return null
	return _find_best_batch(BrewEngine.current_brewery.inventory.brew_batches, data)


func process_auto_sale(data: CustomerData) -> String:
	var best_batch = find_best_batch_for(data)

	# Nothing in stock at all, or nothing that clears this customer's
	# strict requirements (see CustomerData.meets_strict_requirements,
	# including the requires_preference_match gate) — either way they leave
	# without buying. Penalty is per-customer (see CustomerData.
	# no_match_reputation_penalty/no_match_risk_penalty, defaulting to the
	# constants below): most customers still cost a little for being turned
	# away empty-handed, but one who was never actually offered anything
	# (e.g. Agentti's cover story not matching what's on tap) can be given
	# zero.
	if best_batch == null or best_batch.amount_bottles < BOTTLES_SOLD_PER_TRANSACTION:
		var no_match_brewery := BrewEngine.current_brewery
		if no_match_brewery != null:
			no_match_brewery.reputation = max(0, no_match_brewery.reputation - data.no_match_reputation_penalty)
			no_match_brewery.add_risk(data.no_match_risk_penalty)
			BrewerySignals.sale_reputation_gained.emit(-data.no_match_reputation_penalty)
			BrewerySignals.customer_unhappy.emit()
			BrewerySignals.brewery_state_changed.emit(no_match_brewery)
		return data.dialogue_no_match

	var brewery = BrewEngine.current_brewery
	# Snapshot so the net reputation change (including any bar-fight
	# penalty further down) can be reported as a single popup-friendly
	# delta at the end, instead of the mid-function reputation_gain alone.
	var reputation_before : int = brewery.reputation

	var breakdown : SaleBreakdown = brewery.resolver.get_price_breakdown(best_batch.beer_style)
	# Marketing's counter_price_multiplier marks up the listed price for THIS
	# sale only (breakdown itself stays untouched — it's the shared style's
	# structural cost-basis object, not this transaction's own data) before
	# income/tip is derived from it below.
	var counter_price : float = breakdown.price_per_bottle * brewery.get_counter_price_multiplier()
	var results: Dictionary = data.evaluate_brew_batch(best_batch, counter_price)

	var bottles_sold : int = randi_range(data.min_bottles_per_visit, data.max_bottles_per_visit)
	bottles_sold = min(bottles_sold, best_batch.amount_bottles)

	# snappedf re-flattens the float drift that repeated multiplication/
	# addition can introduce (e.g. 0.1 * 3 != 0.3 in IEEE 754) so money
	# stays on a clean one-decimal grid instead of accumulating noise.
	var gross_income : float = snappedf(results[KEY_INCOME] * bottles_sold, 0.1)
	# No tax deduction — nothing gets remitted to the state here. Gross
	# income (the fixed, style-based price) plus any tip is exactly what
	# lands in the till. tip_income_multiplier is a RunPerk bonus (see
	# Brewery.get_tip_income_multiplier()), neutral 1.0 until one's picked.
	var tip_income : float = snappedf(results[KEY_TIP] * bottles_sold * brewery.get_tip_income_multiplier(), 0.1)
	# Rolled after tip_income_multiplier already applied, not instead of it —
	# a doubled tip still respects every other tip bonus already stacked in.
	if tip_income > 0.0 and randf() < brewery.get_tip_double_chance():
		tip_income = snappedf(tip_income * 2.0, 0.1)
	var net_income : float = snappedf(gross_income + tip_income, 0.1)

	brewery.money += net_income
	# reputation_gain_multiplier is the same RunPerk-driven bonus applied
	# to reputation instead of tip — see Brewery.get_reputation_gain_multiplier().
	var reputation_gain : int = roundi(results[KEY_REPUTATION] * brewery.get_reputation_gain_multiplier())
	brewery.reputation = max(0, brewery.reputation + reputation_gain)
	if reputation_gain < 0:
		BrewerySignals.customer_unhappy.emit()
	brewery.add_risk(results[KEY_RISK])
	var sale_xp : int = Brewery.XP_PER_BOTTLE_SOLD * bottles_sold
	brewery.add_xp(sale_xp)
	BrewerySignals.sale_xp_gained.emit(sale_xp)
	BrewerySignals.sale_tip_gained.emit(tip_income)

	var receipt_entry := SaleReceiptEntry.new()
	receipt_entry.breakdown = breakdown
	receipt_entry.bottles_sold = bottles_sold
	receipt_entry.gross_income = gross_income
	receipt_entry.tip_income = tip_income
	receipt_entry.net_income = net_income
	brewery.today_sale_receipts.append(receipt_entry)

	BrewerySignals.beer_sale_breakdown.emit(receipt_entry)

	best_batch.amount_bottles -= bottles_sold
	if best_batch.amount_bottles <= 0:
		brewery.inventory.brew_batches.erase(best_batch)

	brewery.lifetime_bottles_sold += bottles_sold
	BrewerySignals.bottles_sold.emit(bottles_sold)

	var response_text : String = results[KEY_RESPONSE]

	var effective_bar_fight_chance : float = data.bar_fight_chance * brewery.get_bar_fight_chance_multiplier()
	if effective_bar_fight_chance > 0.0 and randf() < effective_bar_fight_chance:
		_trigger_bar_fight(brewery, data, best_batch)

	BrewerySignals.sale_reputation_gained.emit(brewery.reputation - reputation_before)
	BrewerySignals.brewery_state_changed.emit(brewery)
	return response_text


## The incident itself (reputation/risk penalty, broken bottles) is
## reported via BrewerySignals.bar_fight_triggered as its own stacked toast
## — see that signal's own docstring for why this moved off the customer's
## spoken dialogue bubble (process_auto_sale()'s response_text).
func _trigger_bar_fight(brewery: Brewery, data: CustomerData, batch: BrewBatch) -> void:
	brewery.reputation = max(0, brewery.reputation - data.bar_fight_reputation_penalty)
	brewery.add_risk(data.bar_fight_risk_penalty)

	var broken_bottles : int = 0
	if data.bar_fight_max_bottles_broken > 0 and brewery.inventory.brew_batches.has(batch):
		broken_bottles = randi_range(1, data.bar_fight_max_bottles_broken)
		batch.amount_bottles = max(0, batch.amount_bottles - broken_bottles)

		if batch.amount_bottles <= 0:
			brewery.inventory.brew_batches.erase(batch)

	BrewerySignals.bar_fight_triggered.emit(data.dialogue_bar_fight % broken_bottles)


func _find_best_batch(batches: Array[BrewBatch], data: CustomerData) -> BrewBatch:
	var best_batch: BrewBatch = null
	var best_score: float = -1.0

	for batch in batches:
		if batch.amount_bottles <= 0: continue
		# A strict requirement (e.g. Barbaari's minimum ABV, Zgen's
		# alcohol-free-only) makes an out-of-range batch invisible to this
		# customer — not just a worse option, never a candidate at all.
		if not data.meets_strict_requirements(batch.beer_style): continue
		var score = data.get_preference_score(batch.beer_style.style)
		if batch.current_quality >= data.min_quality:
			score += QUALITY_BONUS_WEIGHT
		if score > best_score:
			best_score = score
			best_batch = batch
	return best_batch


func spawn_normal_customer(forced_data: CustomerData = null) -> void:
	if active_spawner == null:
		return
	active_spawner._on_walk_in_timer_timeout(forced_data)


func spawn_group_event(forced_event_data: GroupVisitEventData = null) -> void:
	if active_spawner == null:
		return
	active_spawner._on_group_event_timer_timeout(forced_event_data)


## See CustomerSpawner.pause_spawning()/start_spawning() — used by
## LvvRaidSpawner around a raid squad's walk-in/seize/walk-out sequence.
func pause_spawning() -> void:
	if active_spawner:
		active_spawner.pause_spawning()


func resume_spawning() -> void:
	if active_spawner:
		active_spawner.start_spawning()
