class_name SpicePreviewText
extends RefCounted

## The brewing preview's spice line: the bonus from suitable spices, or the
## Reinheitsgebot penalty, and the cost of spices the style does not like. Empty when
## the spices change nothing.

const BONUS_FORMAT : String = "Mausteet: +%d %%"
const PURITY_LAW_FORMAT : String = "Reinheitsgebot rikottu: -%d %%"
const UNSUITED_FORMAT : String = "Sopimaton mauste: -%d %%"


static func line(spice_bonus : float, unsuited_penalty : float = 0.0) -> String:
	var result : String = ""
	var percent : int = roundi(absf(spice_bonus) * 100.0)
	if percent > 0:
		result += "\n" + UiText.of(BONUS_FORMAT if spice_bonus > 0.0 else PURITY_LAW_FORMAT) % percent
	var unsuited_percent : int = roundi(unsuited_penalty * 100.0)
	if unsuited_percent > 0:
		result += "\n" + UiText.of(UNSUITED_FORMAT) % unsuited_percent
	return result
