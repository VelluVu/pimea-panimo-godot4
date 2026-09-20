class_name InspectionService
extends RefCounted

## LVV raids and the manual early-close penalty. Stateless: Brewery creates one per call.

const LVV_RAID_FINE_PERCENT : float = 0.3

const LVV_RAID_REPUTATION_PENALTY_PERCENT : float = 0.25

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

	var confiscated_bottles : int = brewery.count_total_bottles()
	for spared : BrewBatch in spared_batches:
		confiscated_bottles -= spared.amount_bottles
	brewery.inventory.brew_batches = spared_batches

	# raid_count still counts prior raids, so this raid escalates from the earlier count.
	var escalation : float = minf(LVV_RAID_MAX_ESCALATION, 1.0 + brewery.raid_count * LVV_RAID_ESCALATION_PER_RAID)
	var fine_amount : float = snappedf(brewery.money * LVV_RAID_FINE_PERCENT * escalation, 0.1)
	var reputation_penalty : int = roundi(brewery.reputation * LVV_RAID_REPUTATION_PENALTY_PERCENT * escalation)

	brewery.money -= fine_amount
	brewery.reputation = max(0, brewery.reputation - reputation_penalty)
	brewery.risk = 0
	brewery.raid_count += 1

	BrewerySignals.lvv_raid_triggered.emit(confiscated_bottles, fine_amount, reputation_penalty)
	BrewerySignals.brewery_state_changed.emit(brewery)

	# extra_raid_strikes raises the bust threshold.
	if brewery.raid_count >= BUSTED_RAID_COUNT + int(brewery.stats.total(PerkStats.EXTRA_RAID_STRIKES)):
		brewery.trigger_ending("busted")
		return

	brewery.check_bankruptcy()


## `earliness` runs from 0 (closed as the timer would have ended anyway) to 1
## (closed at the start of the day). Trades sales time for lower risk, at a cost
## that grows with each manual close.
func apply_early_close_cost(earliness : float) -> void:
	earliness = clampf(earliness, 0.0, 1.0)
	var escalation : float = 1.0 + brewery.early_closes_count * EARLY_CLOSE_ESCALATION_PER_CLOSE

	var money_cost : float = snappedf(EARLY_CLOSE_BASE_MONEY_COST * escalation * earliness, 0.1)
	var reputation_cost : int = roundi(EARLY_CLOSE_BASE_REPUTATION_COST * escalation * earliness)
	var risk_relief : int = roundi(EARLY_CLOSE_MAX_RISK_RELIEF * earliness)

	brewery.money -= money_cost
	brewery.reputation = max(0, brewery.reputation - reputation_cost)
	brewery.risk = max(0, brewery.risk - risk_relief)
	brewery.early_closes_count += 1

	BrewerySignals.early_day_close_applied.emit(money_cost, reputation_cost, risk_relief, brewery.early_closes_count)
	BrewerySignals.brewery_state_changed.emit(brewery)
	brewery.check_bankruptcy()
