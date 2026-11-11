class_name OlutoppiText
extends RefCounted

## The words in an Olutoppi node's tooltip; the square itself only shows the level.
## Pure formatting over a MetaUnlockData; the window supplies the purchase state.

const TOOLTIP_CURRENT_FORMAT : String = "Nyt:\n%s"
const TOOLTIP_NEXT_LEVEL_EFFECT_FORMAT : String = "Tason %d jälkeen:\n%s"
const TOOLTIP_NEXT_LEVEL_FORMAT : String = "Seuraava taso: %d mainetta"
## Why a node that is open but grey cannot be bought yet.
const TOOLTIP_RENOWN_SHORT_FORMAT : String = "Mainetta puuttuu %d."
const TOOLTIP_MAXED_TEXT : String = "Taso enimmillään"
const TOOLTIP_LOCKED_FORMAT : String = "Vaatii ensin: %s"
const TOOLTIP_PREREQ_ALL_SEPARATOR : String = ", "
const TOOLTIP_PREREQ_OR_TEXT : String = "tai"


## A locked node only says what it needs. `unmet_prerequisite_names` lists the
## prerequisites not yet invested in.
static func locked_tooltip(unlock : MetaUnlockData, unmet_prerequisite_names : PackedStringArray) -> String:
	# An any-mode capstone lists every branch with "tai"; "," would read as all of them.
	var separator : String = " %s " % UiText.of(TOOLTIP_PREREQ_OR_TEXT) if unlock.requires_any_prerequisite else TOOLTIP_PREREQ_ALL_SEPARATOR
	var lines : PackedStringArray = _header_lines(unlock)
	lines.append(UiText.of(TOOLTIP_LOCKED_FORMAT) % separator.join(unmet_prerequisite_names))
	return "\n".join(lines)


## The current effect, then a preview of the next level (the only hint at level 0).
## `renown` above -1 adds how much is missing when the next level costs more.
static func tooltip(unlock : MetaUnlockData, level : int, maxed : bool, renown : int = -1) -> String:
	var lines : PackedStringArray = _header_lines(unlock)

	if level > 0:
		var current_summary : String = unlock.get_scaled_perk(level).get_stat_summary()
		if not current_summary.is_empty():
			lines.append(UiText.of(TOOLTIP_CURRENT_FORMAT) % current_summary)

	if maxed:
		lines.append(TOOLTIP_MAXED_TEXT)
	else:
		var next_summary : String = unlock.get_scaled_perk(level + 1).get_stat_summary()
		if not next_summary.is_empty():
			lines.append(UiText.of(TOOLTIP_NEXT_LEVEL_EFFECT_FORMAT) % [level + 1, next_summary])
		lines.append(UiText.of(TOOLTIP_NEXT_LEVEL_FORMAT) % unlock.renown_cost_per_level)
		if renown >= 0 and renown < unlock.renown_cost_per_level:
			lines.append(UiText.of(TOOLTIP_RENOWN_SHORT_FORMAT) % (unlock.renown_cost_per_level - renown))
	return "\n".join(lines)


static func _header_lines(unlock : MetaUnlockData) -> PackedStringArray:
	return PackedStringArray([UiText.of(unlock.perk_name), unlock.get_description()])

