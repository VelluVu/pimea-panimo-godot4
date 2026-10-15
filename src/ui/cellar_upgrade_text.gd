class_name CellarUpgradeText
extends RefCounted

## Player-facing text for the cellar upgrades window.

const LEVEL_FORMAT : String = "%s  %d/%d"
const BUY_FORMAT : String = "Osta %d €"
const MAXED_TEXT : String = "Täysi"
const NOW_FORMAT : String = "Nyt: %s"
const NEXT_FORMAT : String = "Seuraava taso: %s"
const NONE_TEXT : String = "ei vielä"
## A machine owned from any season, see CellarMachines.
const MACHINE_ON_TEXT : String = "Päällä"
const MACHINE_OFF_TEXT : String = "Pois"
const MACHINE_OWNED_TEXT : String = "Omistat koneen, se pysyy kaikilla kausilla."
const MACHINE_NOT_OWNED_TEXT : String = "Ei vielä omistuksessa."
const MACHINE_SWITCH_TOOLTIP : String = "Kytke kone päälle tai pois. Valinta muistetaan myös seuraavilla kausilla."


static func title_line(upgrade : CellarUpgradeData, level : int) -> String:
	return UiText.of(LEVEL_FORMAT) % [UiText.of(upgrade.perk_name), level, upgrade.max_level]


static func machine_button_text(active : bool) -> String:
	return UiText.of(MACHINE_ON_TEXT if active else MACHINE_OFF_TEXT)


static func machine_line(owned : bool) -> String:
	return UiText.of(MACHINE_OWNED_TEXT if owned else MACHINE_NOT_OWNED_TEXT)


static func button_text(upgrade : CellarUpgradeData, level : int) -> String:
	if CellarUpgradeRules.is_maxed(level, upgrade.max_level):
		return UiText.of(MAXED_TEXT)
	return UiText.of(BUY_FORMAT) % upgrade.cost_for_next_level(level)


## The effect at the current level and, unless maxed, at the next one.
static func effect_lines(upgrade : CellarUpgradeData, level : int) -> String:
	var now : String = effect(upgrade, level) if level > 0 else UiText.of(NONE_TEXT)
	var lines : PackedStringArray = [UiText.of(NOW_FORMAT) % now]
	if not CellarUpgradeRules.is_maxed(level, upgrade.max_level):
		lines.append(UiText.of(NEXT_FORMAT) % effect(upgrade, level + 1))
	return "\n".join(lines)


## The upgrade's stat lines at `level`, joined on one line.
static func effect(upgrade : CellarUpgradeData, level : int) -> String:
	var perk : RunPerk = upgrade.scaled_copy(level)
	var parts : PackedStringArray = []
	for entry : Dictionary in PerkStats.definitions():
		var kind : PerkStats.Kind = entry.kind
		var value : float = perk.get(entry.stat)
		if value != PerkStats.neutral_value(kind):
			parts.append(UiText.of(entry.text) % PerkStats.value_text(kind, value, perk.stacks_additively))
	return ", ".join(parts)
