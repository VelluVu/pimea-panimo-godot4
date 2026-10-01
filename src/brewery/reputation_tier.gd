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
