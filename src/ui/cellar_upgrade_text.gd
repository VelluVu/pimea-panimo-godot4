class_name CellarUpgradeText
extends RefCounted

## Player-facing text for the cellar upgrades window.

const BUY_FORMAT : String = "Osta %d €"
const MAXED_TEXT : String = "Täysi"
const CHANGE_FORMAT : String = "%s → %s"
## Kegs are not a perk stat, see CellarUpgradeData.kegs_per_level.
const KEGS_FORMAT : String = "Tynnyreitä ja hanoja lisää: %s"
const PIP_OWNED : String = "■"
const PIP_OPEN : String = "□"
## A machine owned from any season, see CellarMachines.
const MACHINE_ON_TEXT : String = "Päällä"
const MACHINE_OFF_TEXT : String = "Pois"
const MACHINE_OWNED_TEXT : String = "Omistat koneen, se pysyy kaikilla kausilla."
const MACHINE_BUY_ONCE_TEXT : String = "Ostetaan kerran, jää kellariin kaikille kausille."
## A grey buy button says why on hover and on touch.
const SHORT_OF_MONEY_FORMAT : String = "Rahaa puuttuu %s."
const MAXED_TOOLTIP : String = "Parannus on jo täydellä tasolla."
const MACHINE_SWITCH_TOOLTIP : String = "Kytke kone päälle tai pois. Valinta muistetaan myös seuraavilla kausilla."


## One pip per level, owned ones filled.
static func level_pips(level : int, max_level : int) -> String:
	var owned : int = clampi(level, 0, max_level)
	return PIP_OWNED.repeat(owned) + PIP_OPEN.repeat(max_level - owned)


static func machine_button_text(active : bool) -> String:
	return UiText.of(MACHINE_ON_TEXT if active else MACHINE_OFF_TEXT)


## What the machine does, then whether it is owned or what buying it means.
static func machine_lines(upgrade : CellarUpgradeData, owned : bool) -> String:
	var status : String = UiText.of(MACHINE_OWNED_TEXT if owned else MACHINE_BUY_ONCE_TEXT)
	if upgrade.machine_effect.is_empty():
		return status
	return "%s
%s" % [UiText.of(upgrade.machine_effect), status]


static func button_text(upgrade : CellarUpgradeData, level : int) -> String:
	if CellarUpgradeRules.is_maxed(level, upgrade.max_level):
		return UiText.of(MAXED_TEXT)
	return UiText.of(BUY_FORMAT) % upgrade.cost_for_next_level(level)


## Why the buy button is grey; empty when it can be bought.
static func buy_tooltip(upgrade : CellarUpgradeData, level : int, money : float) -> String:
	if CellarUpgradeRules.is_maxed(level, upgrade.max_level):
		return UiText.of(MAXED_TOOLTIP)
	var cost : int = upgrade.cost_for_next_level(level)
	if money < cost:
		return UiText.of(SHORT_OF_MONEY_FORMAT) % NumberText.money(cost - money)
	return ""


## What the next level changes, "now → next", one line per stat; a maxed upgrade shows
## only its current effect.
static func effect_change(upgrade : CellarUpgradeData, level : int) -> String:
	var maxed : bool = CellarUpgradeRules.is_maxed(level, upgrade.max_level)
	var now : RunPerk = upgrade.scaled_copy(level)
	var next : RunPerk = upgrade.scaled_copy(level if maxed else level + 1)
	var parts : PackedStringArray = []
	for entry : Dictionary in PerkStats.definitions():
		var kind : PerkStats.Kind = entry.kind
		var next_value : float = next.get(entry.stat)
		if next_value == PerkStats.neutral_value(kind):
			continue
		var value : String = PerkStats.value_text(kind, next_value, upgrade.stacks_additively)
		if not maxed:
			var now_value : String = PerkStats.value_text(kind, now.get(entry.stat), upgrade.stacks_additively)
			value = CHANGE_FORMAT % [now_value, value]
		parts.append(UiText.of(entry.text) % value)
	if upgrade.kegs_per_level > 0:
		var kegs : String = str(upgrade.kegs_per_level * level)
		if not maxed:
			kegs = CHANGE_FORMAT % [kegs, upgrade.kegs_per_level * (level + 1)]
		parts.append(UiText.of(KEGS_FORMAT) % kegs)
	return "
".join(parts)
