class_name KegCountText
extends RefCounted

## The keg line at the top of the warehouse's Tynnyrit tab.

const IN_USE_FORMAT : String = "Tynnyrit käytössä %d/%d"
const UNWASHED_FORMAT : String = ", likaisia %d"
const TOOLTIP_TEXT : String = "Jokainen erä vie oman tynnyrinsä. Tyhjentynyt tynnyri palaa likaisena kellarin nurkkaan pestäväksi. Lisää tynnyreitä saa kellariparannuksista."


static func line(in_use : int, total : int, unwashed : int) -> String:
	var text : String = UiText.of(IN_USE_FORMAT) % [in_use, total]
	if unwashed > 0:
		text += UiText.of(UNWASHED_FORMAT) % unwashed
	return text
