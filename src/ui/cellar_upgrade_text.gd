class_name CellarUpgradeText
extends RefCounted

## Player-facing text for the cellar upgrades window.

const LEVEL_FORMAT : String = "%s  %d/%d"
const BUY_FORMAT : String = "Osta %d €"
const MAXED_TEXT : String = "Täysi"
const NOW_FORMAT : String = "Nyt: %s"
const NEXT_FORMAT : String = "Seuraava taso: %s"
const NONE_TEXT : String = "ei vielä"


static func title_line(upgrade : CellarUpgradeData, level : int) -> String:
	return LEVEL_FORMAT % [upgrade.perk_name, level, upgrade.max_level]


static func button_text(upgrade : CellarUpgradeData, level : int) -> String:
	if CellarUpgradeRules.is_maxed(level, upgrade.max_level):
		return MAXED_TEXT
	return BUY_FORMAT % upgrade.cost_for_next_level(level)


## The effect at the current level and, unless maxed, at the next one.
static func effect_lines(upgrade : CellarUpgradeData, level : int) -> String:
	var now : String = effect(upgrade, level) if level > 0 else NONE_TEXT
	var lines : PackedStringArray = [NOW_FORMAT % now]
	if not CellarUpgradeRules.is_maxed(level, upgrade.max_level):
		lines.append(NEXT_FORMAT % effect(upgrade, level + 1))
	return "\n".join(lines)


## The upgrade's stat lines at `level`, joined on one line.
static func effect(upgrade : CellarUpgradeData, level : int) -> String:
	var perk : RunPerk = upgrade.scaled_copy(level)
	var parts : PackedStringArray = []
	for entry : Dictionary in PerkStats.definitions():
		var kind : PerkStats.Kind = entry.kind
		var value : float = perk.get(entry.stat)
		if value != PerkStats.neutral_value(kind):
			parts.append(entry.text % PerkStats.display_number(kind, value))
	return ", ".join(parts)
