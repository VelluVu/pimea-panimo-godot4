class_name InspectionService
extends RefCounted

## LVV raids and the manual early-close penalty: the two ways the run's risk
## and reputation get spent. Stateless apart from the Brewery it acts on, so
## Brewery creates one per call instead of holding it.

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
## check_for_raid().
const LVV_RAID_ESCALATION_PER_RAID : float = 1.0

## Clamp on the escalation above — matches its value at raid 3
## (BUSTED_RAID_COUNT), the highest raid the formula was ever tuned to
## reach in a normal run. Without this, a RunPerk.extra_raid_strikes perk
## (e.g. MetaUnlockData's "Piilokätkö") that grants a 4th+ raid past the
## normal bust point runs into an escalation that keeps climbing past
## 3.0 — at raid 4 the fine alone hits 120% of current money (0.3 * 4.0),
## which guarantees bankruptcy on its own regardless of how much the
## player recovered beforehand, silently defeating the whole point of
## surviving that extra raid. Capping here means a 4th+ raid still hurts
## exactly as much as the 3rd (the worst the game was ever designed to
## throw at once), not more.
const LVV_RAID_MAX_ESCALATION : float = 3.0

## Three strikes: the raid that pushes raid_count to this becomes
## permanent instead of just another costly setback — see
## check_for_raid() and BrewerySignals.game_ended.
const BUSTED_RAID_COUNT : int = 3

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

var brewery : Brewery


func _init(owner : Brewery) -> void:
	brewery = owner


func check_for_raid() -> void:
	if brewery.risk < brewery.get_effective_raid_threshold():
		return

	# A "Piilokätkö"-style perk (RunPerk.raid_hidden_batch_count) spares up
	# to that many random batches from confiscation entirely — picked fresh
	# per raid via shuffle(), not always the same batches, so this can't be
	# gamed by always keeping the same one style safe.
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

	# raid_count still reflects prior raids only — incremented below, after
	# this raid's own escalation is locked in, same ordering
	# apply_early_close_cost() uses for early_closes_count.
	var escalation : float = minf(LVV_RAID_MAX_ESCALATION, 1.0 + brewery.raid_count * LVV_RAID_ESCALATION_PER_RAID)
	var fine_amount : float = snappedf(brewery.money * LVV_RAID_FINE_PERCENT * escalation, 0.1)
	var reputation_penalty : int = roundi(brewery.reputation * LVV_RAID_REPUTATION_PENALTY_PERCENT * escalation)

	brewery.money -= fine_amount
	brewery.reputation = max(0, brewery.reputation - reputation_penalty)
	brewery.risk = 0
	brewery.raid_count += 1

	BrewerySignals.lvv_raid_triggered.emit(confiscated_bottles, fine_amount, reputation_penalty)
	BrewerySignals.brewery_state_changed.emit(brewery)

	# A "Piilokätkö"-style perk (RunPerk.extra_raid_strikes) raises this
	# threshold above the base three strikes — see PerkStats.EXTRA_RAID_STRIKES.
	if brewery.raid_count >= BUSTED_RAID_COUNT + int(brewery.stats.total(PerkStats.EXTRA_RAID_STRIKES)):
		brewery.trigger_ending("busted")
		return

	brewery.check_bankruptcy()


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
