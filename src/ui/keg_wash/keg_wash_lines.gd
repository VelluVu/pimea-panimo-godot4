class_name KegWashLines
extends RefCounted

## The keg wash's humour popups. The wording is the developer's own; change it only on
## their word.

const FINISHED_TEXT : String = "Noniin nyt on valmis"
const MISTAKE_TEXTS : Dictionary = {
	KegWashSession.Mistake.WASTED_WATER: "Vesilasku kasvaa, mutta lika ei lähde.",
	KegWashSession.Mistake.POLISHING: "Meni jo kiillottamiseksi tuo hankaaminen.",
	KegWashSession.Mistake.GERMS_DEAD: "Eiköhän ne pöpöt jo kuollu.",
}
## The same mistake's line again only after this many seconds.
const MISTAKE_COOLDOWN : float = 4.0


static func mistake_text(kind : KegWashSession.Mistake) -> String:
	return MISTAKE_TEXTS.get(kind, "")
