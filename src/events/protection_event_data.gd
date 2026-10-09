class_name ProtectionEventData
extends PerkOfferEventData

## The Don's protection: paying keeps the Agentti away for agent_free_days (today, by
## default) on top of the offered perk; letting the call pass makes Mafioso walk-ins
## rarer (mafioso_cut) for mafioso_cut_days, as the Don's men stay away.

@export var agent_free_days: int = 1
@export var mafioso_cut_days: int = 2
@export var mafioso_cut: float = 0.5


func try_fulfill(brewery: Brewery) -> bool:
	if not super(brewery):
		return false
	brewery.agentti_free_until_day = brewery.current_day + agent_free_days
	return true


func on_rejected(brewery: Brewery) -> void:
	brewery.mafioso_cut_until_day = brewery.current_day + mafioso_cut_days
	brewery.mafioso_cut_multiplier = mafioso_cut
