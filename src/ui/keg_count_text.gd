class_name KegCountText
extends RefCounted

## The keg line at the top of the warehouse's Tynnyrit tab.

const IN_USE_FORMAT : String = "Hanat %d, tynnyrit käytössä %d/%d"
const UNWASHED_FORMAT : String = ", likaisia %d"
const TOOLTIP_TEXT : String = "Jokainen erä vie oman tynnyrinsä. Hanoja on kaksi vähemmän kuin tynnyreitä: ylimääräiset täydet tynnyrit odottavat varalla ja menevät hanaan, kun hanan tynnyri tyhjenee. Tyhjentynyt tynnyri palaa likaisena kellarin nurkkaan pestäväksi. Lisää tynnyreitä ja hanoja saa kellariparannuksista."


static func line(taps : int, in_use : int, total : int, unwashed : int) -> String:
	var text : String = UiText.of(IN_USE_FORMAT) % [taps, in_use, total]
	if unwashed > 0:
		text += UiText.of(UNWASHED_FORMAT) % unwashed
	return text
