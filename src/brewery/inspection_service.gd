class_name InspectionService
extends RefCounted

## LVV raids and the manual early-close penalty. Stateless: Brewery creates one per call.

const LVV_RAID_FINE_PERCENT : float = 0.3
## One raid never fines more than this. A share of money alone grew to 800+ EUR late
## in a run, which no other cost comes near.
const LVV_RAID_FINE_MAX : float = 200.0

## Each prior raid adds this multiple of the base fine and reputation penalty
## (raid 2 doubles it, raid 3 triples it).
const LVV_RAID_ESCALATION_PER_RAID : float = 1.0

## Caps the escalation at its raid-3 value. Uncapped, the 4th raid granted by an
## extra-strikes perk would fine 120% of money and force bankruptcy.
const LVV_RAID_MAX_ESCALATION : float = 3.0

## The raid that brings raid_count to this ends the run.
const BUSTED_RAID_COUNT : int = 3

## Base early-close costs, scaled by earliness (0 to 1) and by prior closes.
const EARLY_CLOSE_BASE_MONEY_COST : float = 5.0

const EARLY_CLOSE_BASE_REPUTATION_COST : int = 1

## Cost growth per prior manual close: the 2nd costs 1.5x, the 3rd 2.0x.
const EARLY_CLOSE_ESCALATION_PER_CLOSE : float = 0.5
## Caps the escalation, so closing early stays usable as an emergency brake. Uncapped, a
## player who closed early often paid more each time until the run spiralled down.
const EARLY_CLOSE_MAX_ESCALATION : float = 3.0

## Risk relief at earliness 1.0. Not escalated by repeat closes.
const EARLY_CLOSE_MAX_RISK_RELIEF : int = 10

var brewery : Brewery


func _init(owner : Brewery) -> void:
	brewery = owner


func check_for_raid() -> void:
	if brewery.risk < brewery.get_effective_raid_threshold():
		return

	# raid_hidden_batch_count spares that many random batches, picked fresh each raid.
	var spared_batches : Array[BrewBatch] = []
	var hidden_count : int = mini(int(brewery.stats.total(PerkStats.RAID_HIDDEN_BATCHES)), brewery.inventory.brew_batches.size())
	if hidden_count > 0:
		var shuffled : Array[BrewBatch] = brewery.inventory.brew_batches.duplicate()
		shuffled.shuffle()
		spared_batches = shuffled.slice(0, hidden_count)

	# raid_saved_bottle_share leaves part of every other batch behind.
	var share : float = brewery.stats.chance(PerkStats.RAID_SAVED_BOTTLE_SHARE)
	var kept_batches : Array[BrewBatch] = spared_batches.duplicate()
	var confiscated_bottles : int = 0
	for batch : BrewBatch in brewery.inventory.brew_batches:
		if spared_batches.has(batch):
			continue
		var saved : int = saved_bottles(batch.amount_bottles, share)
		confiscated_bottles += batch.amount_bottles - saved
		if saved > 0:
			batch.amount_bottles = saved
			kept_batches.append(batch)
	brewery.inventory.brew_batches = kept_batches

	# raid_count still counts prior raids, so this raid escalates from the earlier count.
	var escalation : float = raid_escalation(brewery.raid_count)
	var fine_amount : float = raid_fine(brewery.money, escalation)
	var reputation_penalty : int = ReputationRules.raid_penalty(brewery.reputation, escalation)

	brewery.money -= fine_amount
	brewery.change_reputation(-reputation_penalty, ReputationRules.Source.LVV)
	brewery.risk = 0
	brewery.raid_count += 1

	BrewerySignals.lvv_raid_triggered.emit(confiscated_bottles, fine_amount, reputation_penalty)
	BrewerySignals.brewery_state_changed.emit(brewery)

	if brewery.raid_count >= raid_limit(brewery):
		brewery.trigger_ending("busted")
		return

	brewery.check_bankruptcy()


## Bottles of a confiscated batch that a raid leaves behind, rounded down.
static func saved_bottles(amount : int, share : float) -> int:
	return floori(amount * clampf(share, 0.0, 1.0))


static func raid_escalation(prior_raids : int) -> float:
	return minf(LVV_RAID_MAX_ESCALATION, 1.0 + prior_raids * LVV_RAID_ESCALATION_PER_RAID)


## The raid that brings raid_count to this ends the run; extra_raid_strikes raises it.
static func raid_limit(owner : Brewery) -> int:
	return BUSTED_RAID_COUNT + int(owner.stats.total(PerkStats.EXTRA_RAID_STRIKES))


static func early_close_escalation(prior_closes : int) -> float:
	return minf(EARLY_CLOSE_MAX_ESCALATION, 1.0 + prior_closes * EARLY_CLOSE_ESCALATION_PER_CLOSE)


static func raid_fine(money : float, escalation : float) -> float:
	return minf(LVV_RAID_FINE_MAX, snappedf(maxf(0.0, money) * LVV_RAID_FINE_PERCENT * escalation, 0.1))


## `earliness` runs from 0 (closed as the timer would have ended anyway) to 1
## (closed at the start of the day). Trades sales time for lower risk, at a cost
## that grows with each manual close.
func apply_early_close_cost(earliness : float) -> void:
	earliness = clampf(earliness, 0.0, 1.0)
	var escalation : float = early_close_escalation(brewery.early_closes_count)

	var money_cost : float = snappedf(EARLY_CLOSE_BASE_MONEY_COST * escalation * earliness, 0.1)
	var reputation_cost : int = roundi(EARLY_CLOSE_BASE_REPUTATION_COST * escalation * earliness)
	var risk_relief : int = roundi(EARLY_CLOSE_MAX_RISK_RELIEF * earliness)

	brewery.money -= money_cost
	brewery.change_reputation(-reputation_cost, ReputationRules.Source.EARLY_CLOSE)
	brewery.risk = max(0, brewery.risk - risk_relief)
	brewery.early_closes_count += 1

	BrewerySignals.early_day_close_applied.emit(money_cost, reputation_cost, risk_relief, brewery.early_closes_count)
	BrewerySignals.brewery_state_changed.emit(brewery)
	brewery.check_bankruptcy()
