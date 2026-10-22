class_name QualityTier
extends RefCounted

## The grade a quality multiplier shows as, from "Heikko" to "Mestarillinen". The bars
## are shared by batches, the brew preview and the sale popups.

const MEDIOCRE_FROM : float = 0.7
const GOOD_FROM : float = 0.9
const EXCELLENT_FROM : float = 1.1
const MASTERFUL_FROM : float = 1.3

const POOR_TEXT : String = "Heikko"
const MEDIOCRE_TEXT : String = "Tyydyttävä"
const GOOD_TEXT : String = "Hyvä"
const EXCELLENT_TEXT : String = "Erinomainen"
const MASTERFUL_TEXT : String = "Mestarillinen"


## The grade in the active language.
static func label(quality : float) -> String:
	return UiText.of(text(quality))


## The Finnish grade, which is also its translation key.
static func text(quality : float) -> String:
	if quality >= MASTERFUL_FROM:
		return MASTERFUL_TEXT
	if quality >= EXCELLENT_FROM:
		return EXCELLENT_TEXT
	if quality >= GOOD_FROM:
		return GOOD_TEXT
	if quality >= MEDIOCRE_FROM:
		return MEDIOCRE_TEXT
	return POOR_TEXT
