class_name BrewDayGuideText
extends RefCounted

## The guided brew day's hint line for each BrewDayGuideRules.Step, untranslated: the
## window's hint label shows the whole constant and translates itself.

const HEAT_WATER_TEXT : String = "Ensin vesi lämpimäksi. Pidä LÄMMITÄ pohjassa (tai välilyönti), kunnes ollaan sopivassa lämmössä."
const COOL_WATER_TEXT : String = "Liian kuumaa! Päästä irti, niin vesi jäähtyy takaisin vihreälle."
const POUR_MALTS_TEXT : String = "Säkissä lukee NYT: vedä maltaat kattilan suulle ja pidä siinä, kunnes säkki on tyhjä."
const BREAK_CLUMPS_TEXT : String = "Kun maltaat on lisätty, paakut täytyy rikkoa melalla, niin niistä saadaan kaikki sokerit irti."
const HOLD_MASH_TEXT : String = "Pidä lämpö tasaisena. Jos se nousee yli, päästä irti."
const TO_BOIL_TEXT : String = "Mäskäys on valmis. Paina KEITTOON."
const HEAT_BOIL_TEXT : String = "Nyt keitetään. Pidä LÄMMITÄ pohjassa, kunnes vierre kiehuu."
const KEEP_BOILING_TEXT : String = "Pidä vierre kiehumassa, mutta älä päästä neulaa oranssille. Siellä vaahto nousee tai kattila kiehuu yli."
const WATCH_FOAM_TEXT : String = "Vaahto nousee! Päästä irti, ennen kuin kattila kiehuu yli."
const ADD_HOPS_TEXT : String = "Heiluva säkki on vuorossa. Vedä se kattilan suulle tai paina sen numeroa."
const FINISH_TEXT : String = "Siinä se. Laatu näkyy ylhäällä. Paina VALMIS, niin olut pääsee käymään."


## Empty for Step.NONE.
static func of(step : BrewDayGuideRules.Step) -> String:
	match step:
		BrewDayGuideRules.Step.HEAT_WATER:
			return HEAT_WATER_TEXT
		BrewDayGuideRules.Step.COOL_WATER:
			return COOL_WATER_TEXT
		BrewDayGuideRules.Step.POUR_MALTS:
			return POUR_MALTS_TEXT
		BrewDayGuideRules.Step.BREAK_CLUMPS:
			return BREAK_CLUMPS_TEXT
		BrewDayGuideRules.Step.HOLD_MASH:
			return HOLD_MASH_TEXT
		BrewDayGuideRules.Step.TO_BOIL:
			return TO_BOIL_TEXT
		BrewDayGuideRules.Step.HEAT_BOIL:
			return HEAT_BOIL_TEXT
		BrewDayGuideRules.Step.KEEP_BOILING:
			return KEEP_BOILING_TEXT
		BrewDayGuideRules.Step.WATCH_FOAM:
			return WATCH_FOAM_TEXT
		BrewDayGuideRules.Step.ADD_HOPS:
			return ADD_HOPS_TEXT
		BrewDayGuideRules.Step.FINISH:
			return FINISH_TEXT
		_:
			return ""
