class_name UiText
extends RefCounted

## A Finnish text in the active language, for static helpers that have no tr(). The
## Finnish text is its own translation key (dev/tools/i18n.py), so a text with no
## translation, or Finnish selected, comes back unchanged.


static func of(text : String) -> String:
	return String(TranslationServer.translate(text))
