class_name UiText
extends RefCounted

## A Finnish text in the active language, for static helpers without tr(). The Finnish is
## its own key, so untranslated text comes back unchanged.


static func of(text : String) -> String:
	return String(TranslationServer.translate(text))
