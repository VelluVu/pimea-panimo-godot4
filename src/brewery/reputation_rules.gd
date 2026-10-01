class_name ReputationRules
extends RefCounted

## Gains shrink as reputation grows, so the higher tiers take sustained play.
## Losses always apply in full.

## Reputation at which a gain is halved; gains keep shrinking past it, ever slower.
const GAIN_SOFT_CAP: float = 100.0
const RAID_PENALTY_PERCENT: float = 0.25
## One raid never takes more than this, so a late raid cannot wipe out days of unlocks.
const RAID_PENALTY_MAX: int = 30


## A positive `amount` scaled down by the current reputation, never below 1.
static func scaled_gain(amount: int, reputation: int) -> int:
	if amount <= 0:
		return amount
	return maxi(1, roundi(amount * GAIN_SOFT_CAP / (GAIN_SOFT_CAP + maxi(0, reputation))))


## The reputation after `amount` is applied, floored at 0.
static func apply(reputation: int, amount: int) -> int:
	return maxi(0, reputation + scaled_gain(amount, reputation))


static func raid_penalty(reputation: int, escalation: float) -> int:
	return mini(RAID_PENALTY_MAX, roundi(reputation * RAID_PENALTY_PERCENT * escalation))


## `threshold` lowered by the tier's fame penalty, never below 1. `tier` may be null.
static func raid_threshold(threshold: int, tier: ReputationTier) -> int:
	if tier == null:
		return threshold
	return maxi(1, threshold - tier.raid_threshold_penalty)


## Reputation lost at a day change. `tier` may be null.
static func daily_decay(reputation: int, tier: ReputationTier) -> int:
	if tier == null:
		return 0
	return roundi(reputation * tier.daily_decay_percent)
