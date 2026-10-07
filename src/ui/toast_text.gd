class_name ToastText
extends RefCounted

## The toasts GuiAnnouncer shows that need a decision, not just a filled-in format.
## An empty string means no toast.

const GOAL_REWARD_FORMAT : String = "%s saavutettu: +%d € / +%d maine / +%d XP!"
const GOAL_FAILED_FORMAT : String = "%s epäonnistui: %d maine / +%d LVV-riski"
## A special-event goal that triggered but couldn't be filled fails penalty-free, so it
## gets its own toast instead of a confusing "0 maine / +0 LVV-riski".
const GOAL_FAILED_NO_PENALTY_FORMAT : String = "%s epäonnistui: ei seurauksia"
const EARLY_CLOSE_FORMAT : String = "Ovet suljettu aikaisin: -%.1f €, mainetta -%d, LVV-riski -%d"
const INGREDIENT_UNLOCKED_FORMAT : String = "Uusi aines: %s"
const INGREDIENTS_UNLOCKED_FORMAT : String = "Uusia aineksia: %s"
## The shop popup stays small: a few names, then how many more.
const MAX_LISTED_INGREDIENTS : int = 2
const MORE_INGREDIENTS_FORMAT : String = "%s +%d"
## Dropped from hop names in the merged toast, which lists them next to spices.
const HOP_NAME_SUFFIX : String = "-humala"
const PURITY_LAW_FORMAT : String = "Reinheitsgebot rikottu! Baijerin herttua kääntyy haudassaan. %s: laatu -%d %%"


## One toast for several unlocks that land together: `single_format` for one name,
## `many_format` for a comma-joined list. Names are translated here.
static func unlocked(single_format : String, many_format : String, names : Array[String]) -> String:
	if names.is_empty():
		return ""
	var translated : PackedStringArray = []
	for name : String in names:
		translated.append(UiText.of(name))
	return UiText.of(single_format if names.size() == 1 else many_format) % ", ".join(translated)


static func goal_resolved(goal_name : String, succeeded : bool, money : int, reputation : int, xp : int, risk : int) -> String:
	var name : String = UiText.of(goal_name)
	if succeeded:
		return UiText.of(GOAL_REWARD_FORMAT) % [name, money, reputation, xp]
	if reputation == 0 and risk == 0:
		return UiText.of(GOAL_FAILED_NO_PENALTY_FORMAT) % name
	return UiText.of(GOAL_FAILED_FORMAT) % [name, reputation, risk]


## Empty when all three numbers rounded to zero (a very late close).
static func early_close(money_cost : float, reputation_cost : int, risk_relief : int) -> String:
	if money_cost <= 0.0 and reputation_cost <= 0 and risk_relief <= 0:
		return ""
	return UiText.of(EARLY_CLOSE_FORMAT) % [money_cost, reputation_cost, risk_relief]


## One short line per reputation jump for the shop entrance's popup, however many
## ingredients it unlocked.
static func ingredients_unlocked(unlocked : Array[IngredientData]) -> String:
	if unlocked.is_empty():
		return ""
	if unlocked.size() == 1:
		return UiText.of(INGREDIENT_UNLOCKED_FORMAT) % UiText.of(unlocked[0].name)
	var names : PackedStringArray = []
	for ingredient : IngredientData in unlocked.slice(0, MAX_LISTED_INGREDIENTS):
		names.append(UiText.of(ingredient.name.trim_suffix(HOP_NAME_SUFFIX)))
	var listed : String = ", ".join(names)
	if unlocked.size() > MAX_LISTED_INGREDIENTS:
		listed = MORE_INGREDIENTS_FORMAT % [listed, unlocked.size() - MAX_LISTED_INGREDIENTS]
	return UiText.of(INGREDIENTS_UNLOCKED_FORMAT) % listed


## Only a broken Reinheitsgebot gets a toast; a spice bonus shows in the batch tooltip.
static func spiced_brew(style_name : String, spice_bonus : float) -> String:
	if spice_bonus >= 0.0:
		return ""
	return UiText.of(PURITY_LAW_FORMAT) % [UiText.of(style_name), roundi(-spice_bonus * 100.0)]
