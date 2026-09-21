class_name OlutoppiText
extends RefCounted

## The words on an Olutoppi node: the short bonus shown on its square and its tooltip.
## Pure formatting over a MetaUnlockData; the window supplies the purchase state.

const BONUS_NEUTRAL_TEXT : String = "-"
const TOOLTIP_CURRENT_FORMAT : String = "Nyt:\n%s"
const TOOLTIP_NEXT_LEVEL_EFFECT_FORMAT : String = "Tason %d jälkeen:\n%s"
const TOOLTIP_NEXT_LEVEL_FORMAT : String = "Seuraava taso: %d maine"
const TOOLTIP_MAXED_TEXT : String = "Taso enimmillään"
const TOOLTIP_LOCKED_FORMAT : String = "Vaatii ensin: %s"
const TOOLTIP_PREREQ_ALL_SEPARATOR : String = ", "
const TOOLTIP_PREREQ_ANY_SEPARATOR : String = " tai "


## The first non-neutral stat of the scaled perk, as a short number for the square. A
## node that sets several stats shows only the first; the tooltip has every line.
static func short_bonus(unlock : MetaUnlockData, level : int) -> String:
	if level <= 0:
		return BONUS_NEUTRAL_TEXT

	var scaled : RunPerk = unlock.get_scaled_perk(level)
	for entry : Dictionary in PerkStats.definitions():
		var kind : PerkStats.Kind = entry.kind
		var value : float = scaled.get(entry.stat)
		if value == PerkStats.neutral_value(kind):
			continue
		var number : int = PerkStats.display_number(kind, value)
		match kind:
			PerkStats.Kind.MULTIPLIER:
				return "%+d%%" % number
			PerkStats.Kind.PERCENT_ADD:
				return "%d%%" % number
			_:
				return "+%d" % number
	return BONUS_NEUTRAL_TEXT


## A locked node only says what it needs. `unmet_prerequisite_names` lists the
## prerequisites not yet invested in.
static func locked_tooltip(unlock : MetaUnlockData, unmet_prerequisite_names : PackedStringArray) -> String:
	# An any-mode capstone only shows locked while none of its branches are met, so the
	# list is every branch: "tai" reads as any one of them, "," would read as all.
	var separator : String = TOOLTIP_PREREQ_ANY_SEPARATOR if unlock.requires_any_prerequisite else TOOLTIP_PREREQ_ALL_SEPARATOR
	var lines : PackedStringArray = _header_lines(unlock)
	lines.append(TOOLTIP_LOCKED_FORMAT % separator.join(unmet_prerequisite_names))
	return "\n".join(lines)


## The current effect, then a preview of the next purchase (also at level 0, where it is
## the only hint of what a first purchase does).
static func tooltip(unlock : MetaUnlockData, level : int, maxed : bool) -> String:
	var lines : PackedStringArray = _header_lines(unlock)

	if level > 0:
		var current_summary : String = unlock.get_scaled_perk(level).get_stat_summary()
		if not current_summary.is_empty():
			lines.append(TOOLTIP_CURRENT_FORMAT % current_summary)

	if maxed:
		lines.append(TOOLTIP_MAXED_TEXT)
	else:
		var next_summary : String = unlock.get_scaled_perk(level + 1).get_stat_summary()
		if not next_summary.is_empty():
			lines.append(TOOLTIP_NEXT_LEVEL_EFFECT_FORMAT % [level + 1, next_summary])
		lines.append(TOOLTIP_NEXT_LEVEL_FORMAT % unlock.renown_cost_per_level)
	return "\n".join(lines)


static func _header_lines(unlock : MetaUnlockData) -> PackedStringArray:
	return PackedStringArray([unlock.perk_name, unlock.description])

