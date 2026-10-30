class_name CellarGuideText
extends RefCounted

## What Aatu says in the cellar: a line for each first-brew step of NextStepRules, the talk
## after the first brew day, and his goodbye when the tutorial is switched off mid-way.
## Untranslated: the speech box translates the whole constant.

enum Talk { GOALS, RECIPES, UPGRADES, BREWERY_BOOK, GOODBYE }

const OPEN_RECIPES_TEXT : String = "Jaahas, meinaat alkaa pyörittämään pimeää panimoa? Minä olen Aatu, ja neuvon hieman alkuun. Ovet pysyvät kiinni, kunnes ensimmäinen olut on pantu. Avaa reseptikirja, niin nähdään, mitä tiedät."
const PICK_RECIPE_TEXT : String = "Kotikaljallahan kaikki aloittelee. Avaapa se resepti."
const LOAD_RECIPE_TEXT : String = "Täältä näkee vähän, mitä halutaan. Resepti voidaan laittaa kohteeksi lataamalla se reseptinäkymään, niin ei tarvitse arpoa raaka-aineiden kanssa."
const GO_TO_SHOP_TEXT : String = "Maltaat ja hiiva ostetaan kaupasta. Kauppa on tiskin oikeassa päässä."
const BUY_MISSING_TEXT : String = "Valitsemalla osta puuttuvat ostaa kaikki tarvittavat valittuun reseptiin minkä jo tiedät. Yksitellen voit ostaa valitsemalla raaka-aine määrä ja osta-napilla."
const CLOSE_SHOP_TEXT : String = "Nyt on tavarat. Voit tarkistaa ostamasi raaka-aineet varasto näkymästä. Sitten sulje kauppa ja mennään panimoon."
const OPEN_BREWERY_TEXT : String = "Panimo on vasemmalla holvin takana. Siellä tapahtuu taika."
const ADD_INGREDIENTS_TEXT : String = "Valitsemalla täytä resepti nostaa kaiken reseptiin vaaditut raaka-aineet pöydälle kerralla. Jos haluat kokeilla löytää uusia oluttyylejä täytyy kokeilla valitsemalla raaka-aine, määrä ja lisää."
const START_BREW_TEXT : String = "Kaikki on pöydällä. Paina Pane, niin päästään keittämään."

const GOALS_TALK_TEXT : String = "Hyvin meni. Oikealla ylhäällä ovat päivän tavoitteet. Täytä ne, niin saat rahaa, mainetta ja kokemusta."
const RECIPES_TALK_TEXT : String = "Kirjassa on tyylejä, joita et vielä osaa. Vihjeet kertovat, mitä ne kaipaavat. Kokeile, niin uusi resepti kirjautuu kirjaan."
const UPGRADES_TALK_TEXT : String = "Kun rahaa kertyy, katso jakoavaimen takaa kellarin parannukset. Hyvä kellari tekee hyvää kaljaa."
const BREWERY_BOOK_TALK_TEXT : String = "Tiskillä on Panimokirja. Sen Ohjeet-sivuilta voit lukea kaiken, mitä tänään opit, ja vähän enemmänkin."
const GOODBYE_TALK_TEXT : String = "Minä painun nurkkaani. Tulen joskus käymään, jos kaipaat salaisuuksia. Ne eivät ole ilmaisia."

const FORGETFUL_TEXT : String = "Jaaha, olenkin jo neuvonut aiemmin. Muisti alkaa jo pätkiä."


## Empty for the steps after the first brew, which the goals panel's line covers.
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
		_:
			return ""


static func talk(line : Talk) -> String:
	match line:
		Talk.GOALS:
			return GOALS_TALK_TEXT
		Talk.RECIPES:
			return RECIPES_TALK_TEXT
		Talk.UPGRADES:
			return UPGRADES_TALK_TEXT
		Talk.BREWERY_BOOK:
			return BREWERY_BOOK_TALK_TEXT
		_:
			return GOODBYE_TALK_TEXT
