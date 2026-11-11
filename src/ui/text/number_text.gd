class_name NumberText
extends RefCounted

## Numbers as the player reads them: Finnish puts a comma before the decimals, English a
## point. Money always shows cents, so prices read the same wherever they appear.

const MONEY_FORMAT : String = "%s €"
const FINNISH_SEPARATOR : String = ","
const ENGLISH_SEPARATOR : String = "."


## `separator` empty follows the active language.
static func decimal(value : float, decimals : int, separator : String = "") -> String:
	var text : String = ("%." + str(decimals) + "f") % value
	if separator.is_empty():
		separator = FINNISH_SEPARATOR if TranslationServer.get_locale().begins_with("fi") else ENGLISH_SEPARATOR
	return text.replace(ENGLISH_SEPARATOR, separator)


static func money(value : float, separator : String = "") -> String:
	return MONEY_FORMAT % decimal(value, 2, separator)


## A change in money with its sign: "+8,00 €" or "-8,00 €".
static func signed_money(value : float, separator : String = "") -> String:
	return ("-" if value < 0.0 else "+") + money(absf(value), separator)
