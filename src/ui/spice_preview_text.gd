class_name SpicePreviewText
extends RefCounted

## The brewing preview's spice line: the bonus from suitable spices, or the
## Reinheitsgebot penalty. Empty when the spices change nothing.

const BONUS_FORMAT : String = "Mausteet: +%d %%"
const PURITY_LAW_FORMAT : String = "Reinheitsgebot rikottu: -%d %%"


static func line(spice_bonus : float) -> String:
	var percent : int = roundi(absf(spice_bonus) * 100.0)
	if percent == 0:
		return ""
	return "\n" + UiText.of(BONUS_FORMAT if spice_bonus > 0.0 else PURITY_LAW_FORMAT) % percent
