class_name BrewDayLines
extends RefCounted

## The brew day's humour popups, grouped by the moment they belong to. The wording is
## the developer's own and final; change it only on their word.

const WATER_HEATING : Array[String] = [
	"Vesi lämpenee. Hitaasti mutta varmasti.",
	"Lämpömittarihan on kalibroitu, kai?",
]
const MALTS_IN_TEXT : String = "Mallasta sisään, ja möykyt sileeks."
const MALT_AROMA_TEXT : String = "Mäskin leipämäinen tuoksu täyttää kellarin."
const IN_BAND : Array[String] = [
	"Entsyymit tekevät töitä. Sinä et.",
	"Tärkkelys muuttuu sokeriksi.",
]
const STEP_DONE_TEXT : String = "Askel valmis! Seuraavaan lämpöön."
const MASH_DONE_TEXT : String = "Mäskäys valmis. Mallas antoi kaikkensa."
const FAR_TOO_HOT : Array[String] = [
	"Entsyymit kuolivat sankarikuolemaan.",
	"Kuumempi ei ole parempi. Paitsi saunassa.",
]
const TOO_COLD_TEXT : String = "Mäski jäähtyy. Kuten intosi."
const TOO_HOT_TEXT : String = "Liian kuumaa! Odota, odota..."
const CLUMP_TEXT : String = "Paakku! Pistä se sileeks!"
const CLUMP_BROKEN_TEXT : String = "Paakku eliminoitu!"
const CLUMPS_LEFT_TEXT : String = "Paakut jäivät, tehokkuus kärsi."
const BOILING_TEXT : String = "KIEHUU!"
const FOAM_WARNING_TEXT : String = "YLI TULEE! Älä nosta lämpöä enää!"
const BOILED_OVER : Array[String] = [
	"Kellarin lattia on nyt tahmea... pysyvästi.",
	"Naapuri haistaa tämän.",
	"Ylikiehuminen, lattia lainehtii sokerilientä.",
]
const BOIL_STOPPED_TEXT : String = "Kiehuminen loppuu, lisää lämpöä!"
const BITTERING_IN_TEXT : String = "Katkerot kattilaan!"
const HOP_HIT : Array[String] = [
	"Humalaloitsu onnistui!",
	"Tästä tulee katkeraa.",
]
const AROMA_HIT_TEXT : String = "Aromit poreilevat kuin taikajuoma."
const BIG_HOP_TEXT : String = "Humalapommi!"
const SMALL_HOP_TEXT : String = "Säästeliäs panimo."
const STRAY_POUR_TEXT : String = "Humalat lensivät kuin konfetti."
const MISSED_MARK_TEXT : String = "Humalat jäivät pussiin."
const WRONG_SACK_TEXT : String = "Väärät humalat, mutta hyvät tuoksut."
const SPICES_IN_TEXT : String = "Mausteet sisään, tuoksuupa joululle."
const JUNIPER_IN_TEXT : String = "Katajaa! Esi-isät olisivat ylpeitä."
const FLAMEOUT_TEXT : String = "Liekit pois, niin aromit jää."
## A bittering hop poured at a flavour or aroma mark; %s is the hop's name.
const NOT_AROMA_HOP_TEXT : String = "%s ei ole aromihumala."
const RESULT_PERFECT_TEXT : String = "Täydellinen keittopäivä!"
const RESULT_GOOD_TEXT : String = "Kelpo erä."
const RESULT_LOW_TEXT : String = "No, juotavaa se on."

const JUNIPER_ID : int = 212
## A mark this heavy (or light) in grams gets its own line.
const BIG_HOP_GRAMS : int = 60
const SMALL_HOP_GRAMS : int = 10


static func pick(lines : Array[String]) -> String:
	return lines[randi() % lines.size()]


static func result_line(multiplier : float) -> String:
	if multiplier >= BrewDayRules.PERFECT_MULTIPLIER:
		return RESULT_PERFECT_TEXT
	if multiplier >= BrewDayRules.NORMAL_MULTIPLIER:
		return RESULT_GOOD_TEXT
	return RESULT_LOW_TEXT


## The line for a judged mark, or "" when it needs none.
static func mark_line(mark : BoilMark) -> String:
	match mark.result:
		BoilMark.Result.MISS:
			return MISSED_MARK_TEXT
		BoilMark.Result.HALF:
			return WRONG_SACK_TEXT
		BoilMark.Result.FULL:
			if mark.kind == HopAddition.Kind.SPICE:
				return JUNIPER_IN_TEXT if mark.ingredient_id == JUNIPER_ID else SPICES_IN_TEXT
			if mark.grams >= BIG_HOP_GRAMS:
				return BIG_HOP_TEXT
			if mark.grams <= SMALL_HOP_GRAMS:
				return SMALL_HOP_TEXT
			if mark.kind == HopAddition.Kind.BITTERING:
				return BITTERING_IN_TEXT
			if mark.kind == HopAddition.Kind.AROMA:
				return AROMA_HIT_TEXT
			return pick(HOP_HIT)
	return ""
