class_name NextStepText
extends RefCounted

## The goals panel's "next step" line for each NextStepRules.Step. Returned untranslated:
## the label shows the whole constant and translates itself.

const OPEN_RECIPES_TEXT : String = "Seuraavaksi: avaa reseptikirja hyllyltä."
const PICK_RECIPE_TEXT : String = "Seuraavaksi: katso Kotikaljan resepti."
const LOAD_RECIPE_TEXT : String = "Seuraavaksi: lataa resepti tai sulje kirja."
const GO_TO_SHOP_TEXT : String = "Seuraavaksi: avaa kauppa tiskin oikeasta päästä."
const BUY_MISSING_TEXT : String = "Seuraavaksi: osta reseptin raaka-aineet."
const CLOSE_SHOP_TEXT : String = "Seuraavaksi: sulje kauppa ja avaa panimo."
const OPEN_BREWERY_TEXT : String = "Seuraavaksi: avaa panimo vasemmalta holvista."
const ADD_INGREDIENTS_TEXT : String = "Seuraavaksi: täytä resepti tai lisää raaka-aineet pöydälle."
const START_BREW_TEXT : String = "Seuraavaksi: pane olut."
const BREW_MORE_TEXT : String = "Hanat ovat tyhjät. Pane uusi olut panimossa."
const WAIT_FERMENT_TEXT : String = "Olut käy. Pane sillä välin seuraava erä."


## Empty for Step.NONE.
static func of(step : NextStepRules.Step) -> String:
	match step:
		NextStepRules.Step.OPEN_RECIPES:
			return OPEN_RECIPES_TEXT
		NextStepRules.Step.PICK_RECIPE:
			return PICK_RECIPE_TEXT
		NextStepRules.Step.LOAD_RECIPE:
			return LOAD_RECIPE_TEXT
		NextStepRules.Step.GO_TO_SHOP:
			return GO_TO_SHOP_TEXT
		NextStepRules.Step.BUY_MISSING:
			return BUY_MISSING_TEXT
		NextStepRules.Step.CLOSE_SHOP:
			return CLOSE_SHOP_TEXT
		NextStepRules.Step.OPEN_BREWERY:
			return OPEN_BREWERY_TEXT
		NextStepRules.Step.ADD_INGREDIENTS:
			return ADD_INGREDIENTS_TEXT
		NextStepRules.Step.START_BREW:
			return START_BREW_TEXT
		NextStepRules.Step.BREW_MORE:
			return BREW_MORE_TEXT
		NextStepRules.Step.WAIT_FERMENT:
			return WAIT_FERMENT_TEXT
		_:
			return ""
