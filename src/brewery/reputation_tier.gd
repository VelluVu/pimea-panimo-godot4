class_name ReputationTier
extends Resource

## One named reputation tier. ReputationTiers loads them from
## res://src/resources/reputation_tiers/.

@export var tier_name: String = ""
## Reputation at which this tier starts.
@export var min_reputation: int = 0
@export_multiline var description: String = ""
