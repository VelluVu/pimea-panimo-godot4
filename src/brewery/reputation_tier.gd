class_name ReputationTier
extends Resource

## One named reputation tier. ReputationTiers loads them from
## res://src/resources/reputation_tiers/.

@export var tier_name: String = ""
## Reputation at which this tier starts.
@export var min_reputation: int = 0
@export_multiline var description: String = ""
## Fame draws inspectors: subtracted from the LVV raid threshold while in this tier.
@export var raid_threshold_penalty: int = 0
## Share of reputation lost at each day change, so a high tier needs upkeep.
@export_range(0.0, 1.0, 0.01) var daily_decay_percent: float = 0.0
## Fame also pays: counter prices rise by this share (0.1 = +10 %) while in this tier.
@export_range(0.0, 1.0, 0.01) var counter_price_bonus: float = 0.0
## Customers arrive this much more often (0.1 = gaps 10 % shorter) while in this tier.
@export_range(0.0, 0.9, 0.01) var spawn_speed_bonus: float = 0.0
