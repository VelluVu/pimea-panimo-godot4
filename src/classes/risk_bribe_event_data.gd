class_name RiskBribeEventData
extends SpecialEventData

## The one direct, player-initiated way to bring AVI risk down: pay a bribe
## instead of handing over beer. Costs money (and typically a little
## reputation, via reward_reputation — bribery isn't exactly good PR) rather
## than requiring any bottles.

@export var bribe_cost: int = 40

## How many times as likely this event is to be rolled once risk has
## reached the effective raid threshold, versus at risk 0 (where it's
## exactly as likely as any other special event) — see get_weight().
const MAX_WEIGHT_MULTIPLIER: float = 5.0


## Scales linearly from 1.0 (no risk) up to MAX_WEIGHT_MULTIPLIER as risk
## approaches brewery.get_effective_raid_threshold() — still capped there
## rather than growing further past it, and still never guaranteed (a
## weighted roll, not a forced pick), so a player under pressure sees the
## bribe offer meaningfully more often without it becoming a sure thing.
func get_weight(brewery: Brewery) -> float:
	var threshold: int = brewery.get_effective_raid_threshold()
	if threshold <= 0:
		return MAX_WEIGHT_MULTIPLIER

	var risk_fraction: float = clampf(float(brewery.risk) / float(threshold), 0.0, 1.0)
	return 1.0 + risk_fraction * (MAX_WEIGHT_MULTIPLIER - 1.0)


func try_fulfill(brewery: Brewery) -> bool:
	if brewery.money < bribe_cost:
		return false

	brewery.money -= bribe_cost
	_apply_rewards(brewery)
	return true
