class_name RiskText
extends RefCounted

## The top bar's LVV risk: label, red warning and tooltip, at the run's own threshold.

const LABEL_FORMAT : String = "LVV-riski: %d/%d"
## The label turns red this close to the threshold.
const WARNING_MARGIN : int = 25

const VALUE_FORMAT : String = "Riski %d, ratsiakynnys %d"
const MARGIN_FORMAT : String = "%d riskiä ennen ratsiaa"
const THRESHOLD_BASE_FORMAT : String = "Peruskynnys %d"
const THRESHOLD_PERKS_FORMAT : String = "edut %+d"
const THRESHOLD_FAME_FORMAT : String = "maine -%d"
const DECAY_FORMAT : String = "Laskee %d joka yö"
const RAIDS_FORMAT : String = "Ratsiat: %d/%d, viimeinen lopettaa kauden"
const NEXT_RAID_FORMAT : String = "Seuraava ratsia: sakko %s, mainetta -%d ja oluet takavarikoidaan"
const LAST_RAID_TEXT : String = "Seuraava ratsia lopettaa kauden!"


static func label(risk : int, threshold : int) -> String:
	return UiText.of(LABEL_FORMAT) % [risk, threshold]


static func is_warning(risk : int, threshold : int) -> bool:
	return risk >= threshold - WARNING_MARGIN


## `perk_change` and `fame_penalty` moved the threshold from `base`; the breakdown shows
## only when one did.
static func tooltip(risk : int, threshold : int, base : int, perk_change : int, fame_penalty : int,
		raid_count : int, raid_limit : int, next_fine : float, next_reputation_penalty : int) -> String:
	var lines : PackedStringArray = [
		UiText.of(VALUE_FORMAT) % [risk, threshold],
		UiText.of(MARGIN_FORMAT) % maxi(0, threshold - risk),
	]
	if perk_change != 0 or fame_penalty != 0:
		var parts : PackedStringArray = [UiText.of(THRESHOLD_BASE_FORMAT) % base]
		if perk_change != 0:
			parts.append(UiText.of(THRESHOLD_PERKS_FORMAT) % perk_change)
		if fame_penalty != 0:
			parts.append(UiText.of(THRESHOLD_FAME_FORMAT) % fame_penalty)
		lines.append(", ".join(parts))
	lines.append(UiText.of(DECAY_FORMAT) % DayRules.NIGHTLY_RISK_DECAY)
	lines.append(UiText.of(RAIDS_FORMAT) % [raid_count, raid_limit])
	if raid_count + 1 >= raid_limit:
		lines.append(UiText.of(LAST_RAID_TEXT))
	else:
		lines.append(UiText.of(NEXT_RAID_FORMAT) % [NumberText.money(next_fine), next_reputation_penalty])
	return "\n".join(lines)
