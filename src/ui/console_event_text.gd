class_name ConsoleEventText
extends RefCounted

## Console event log lines that need more than a filled-in format: one line per sale
## with everything the popups showed, so a missed popup can be read back later.

const SALE_FORMAT : String = "Myynti: %s osti %d × %s, +%.1f €"
const TIP_PART_FORMAT : String = "tippi +%.1f €"
const BIG_TIP_SUFFIX : String = " (iso)"
const CRITICAL_TIP_SUFFIX : String = " (kriittinen!)"
const REPUTATION_PART_FORMAT : String = "mainetta %+d"
const XP_PART_FORMAT : String = "XP +%d"
const TURNED_AWAY_FORMAT : String = "%s lähti tyhjin käsin, mainetta %+d"
const NAMED_LIST_FORMAT : String = "%s: %s"


static func sale(customer : String, bottles : int, style : String, income : float, tip : float, tip_tier : PopupTierRules.Tier, reputation : int, xp : int) -> String:
	var parts : PackedStringArray = [UiText.of(SALE_FORMAT) % [UiText.of(customer), bottles, UiText.of(style), income]]
	if tip > 0.0:
		var tip_text : String = UiText.of(TIP_PART_FORMAT) % tip
		if tip_tier == PopupTierRules.Tier.CRITICAL:
			tip_text += UiText.of(CRITICAL_TIP_SUFFIX)
		elif tip_tier == PopupTierRules.Tier.BIG:
			tip_text += UiText.of(BIG_TIP_SUFFIX)
		parts.append(tip_text)
	if reputation != 0:
		parts.append(UiText.of(REPUTATION_PART_FORMAT) % reputation)
	if xp > 0:
		parts.append(UiText.of(XP_PART_FORMAT) % xp)
	return ", ".join(parts)


static func turned_away(customer : String, reputation : int) -> String:
	return UiText.of(TURNED_AWAY_FORMAT) % [UiText.of(customer), reputation]


## "Uusia aineksia: Cascade-humala, Citra-humala": the console has room for every name.
static func named_list(format : String, names : Array[String]) -> String:
	var translated : PackedStringArray = []
	for name : String in names:
		translated.append(UiText.of(name))
	return UiText.of(format) % ", ".join(translated)
