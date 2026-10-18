class_name BrewPreviewText
extends RefCounted

## The brewing table's preview from the same BrewResolver result a real brew uses, so a
## recipe can be tuned before spending ingredients.

const EMPTY_TEXT : String = "Lisää raaka-aineita nähdäksesi arvion."
const NOT_ENOUGH_TEXT : String = "Tarvitset ainakin 3 kg mallasta ja hiivan."
const NO_MATCH_FORMAT : String = "Ei täsmää vielä mihinkään tyyliin. (EBC %d, IBU %d, %.1f %% ABV)"
## An undiscovered style keeps its name: the name is the reward for brewing it once.
const UNKNOWN_MATCH_FORMAT : String = "Arvio: tuntematon tyyli täsmää! (EBC %d, IBU %d, %.1f %% ABV)"
const MALT_FORMAT : String = "Tyylin maltaat: +%d %%"
const KNOWN_MATCH_FORMAT : String = "Arvio: %s, EBC %d, IBU %d, %.1f %% ABV, laatu %d%%"


## `preview` is null when the table is not brewable yet; `style_known` only matters
## for a matched preview.
static func text(table_empty : bool, preview : BrewResult, style_known : bool) -> String:
	if table_empty:
		return UiText.of(EMPTY_TEXT)
	if preview == null:
		return UiText.of(NOT_ENOUGH_TEXT)
	if not preview.is_matched:
		return UiText.of(NO_MATCH_FORMAT) % [preview.final_ebc, preview.final_ibu, preview.abv]
	if not style_known:
		return UiText.of(UNKNOWN_MATCH_FORMAT) % [preview.final_ebc, preview.final_ibu, preview.abv]
	return UiText.of(KNOWN_MATCH_FORMAT) % [UiText.of(preview.beer_style.style_name), preview.final_ebc, preview.final_ibu, preview.abv, roundi(preview.original_quality * 100)] \
			+ SpicePreviewText.line(preview.spice_bonus, preview.unsuited_spice_penalty) + _malt_line(preview.malt_bonus)


static func _malt_line(malt_bonus : float) -> String:
	var percent : int = roundi(malt_bonus * 100.0)
	return "\n" + UiText.of(MALT_FORMAT) % percent if percent > 0 else ""
