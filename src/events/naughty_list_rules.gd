class_name NaughtyListRules
extends RefCounted

## The kiltti/tuhma list's maths: tontut mark each visit, Joulupukki settles the marks on his
## own visit and the account starts over.

enum Verdict { NONE, GIFT, FAVOUR, PUNISHMENT }

## Tonttu visits marked since his last settling before Joulupukki comes again; tontut come
## about three times a day, so he comes about every other day with a list worth reading.
const JOULUPUKKI_MIN_MARKS : int = 6
## Kiltti marks needed, with his Pukkibock served, for the three wrapped gifts.
const GIFT_MIN_KILTTI : int = 2
const GIFT_COUNT : int = 3
## He "knows people at LVV".
const FAVOUR_RISK_RELIEF : int = 10
## The tontut tipped off LVV.
const PUNISHMENT_RISK : int = 10
const KOIVURISU_ID : int = 414
const KOIVURISU_AMOUNT : int = 1
## A sip from a keg takes 1 to this many bottles.
const SIP_MAX_BOTTLES : int = 3
## A hidden ingredient: this share of what is owned, at least one unit.
const HIDE_SHARE : float = 0.34

enum Mischief { FOOTPRINTS, HIDE_INGREDIENT, SIP_KEG }


static func joulupukki_due(kiltti : int, tuhma : int) -> bool:
	return kiltti + tuhma >= JOULUPUKKI_MIN_MARKS


static func verdict(kiltti : int, tuhma : int, got_favourite : bool) -> Verdict:
	if tuhma > kiltti:
		return Verdict.PUNISHMENT
	if kiltti > tuhma:
		return Verdict.GIFT if got_favourite and kiltti >= GIFT_MIN_KILTTI else Verdict.FAVOUR
	return Verdict.NONE


## A missed tonttu's revenge, from what the cellar has to lose; `roll` in [0, 1).
static func mischief(has_ingredients : bool, has_beer : bool, roll : float) -> Mischief:
	var options : Array[Mischief] = []
	if has_ingredients:
		options.append(Mischief.HIDE_INGREDIENT)
	if has_beer:
		options.append(Mischief.SIP_KEG)
	if options.is_empty():
		return Mischief.FOOTPRINTS
	return options[mini(int(roll * options.size()), options.size() - 1)]


static func hidden_amount(owned : int) -> int:
	return clampi(ceili(owned * HIDE_SHARE), 1, owned) if owned > 0 else 0
