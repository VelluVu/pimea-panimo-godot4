class_name ReputationTierText
extends RefCounted

## The top bar's reputation tooltip: the exact value, the tier's description, the next
## tier, and what fame costs at this tier.

const VALUE_FORMAT : String = "Maine: %d"
const NEXT_TIER_FORMAT : String = "Seuraava: %s (%d mainetta)"
const TOP_TIER_TEXT : String = "Korkein maine saavutettu."
const FAME_RAID_FORMAT : String = "Kuuluisuus houkuttelee tarkastajia: ratsiakynnys -%d"
const FAME_DECAY_FORMAT : String = "Maine hiipuu %d %% joka yö"


## `next` is null at the top tier.
static func tooltip(reputation : int, tier : ReputationTier, next : ReputationTier) -> String:
	var next_text : String = UiText.of(TOP_TIER_TEXT) if next == null \
			else UiText.of(NEXT_TIER_FORMAT) % [UiText.of(next.tier_name), next.min_reputation]
	var text : String = "%s\n%s\n%s" % [UiText.of(VALUE_FORMAT) % reputation, UiText.of(tier.description), next_text]
	if tier.raid_threshold_penalty > 0:
		text += "\n" + UiText.of(FAME_RAID_FORMAT) % tier.raid_threshold_penalty
	if tier.daily_decay_percent > 0.0:
		text += "\n" + UiText.of(FAME_DECAY_FORMAT) % roundi(tier.daily_decay_percent * 100.0)
	return text
