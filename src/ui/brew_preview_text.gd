class_name BrewPreviewText
extends RefCounted

## The brewing table's live preview: what pressing "Pane" would brew, from the same
## BrewResolver result a real brew uses, so players can tune a recipe before spending
## ingredients instead of finding out from a failed brew.

const EMPTY_TEXT : String = "Lisää ainesosia nähdäksesi arvion."
const NOT_ENOUGH_TEXT : String = "Tarvitset ainakin 3 kg mallasta ja hiivan."
const NO_MATCH_FORMAT : String = "Ei täsmää vielä mihinkään tyyliin. (EBC %d, IBU %d)"
## An undiscovered style keeps its name: the name is the reward for brewing it once.
const UNKNOWN_MATCH_FORMAT : String = "Arvio: tuntematon tyyli täsmää! (EBC %d, IBU %d)"
const KNOWN_MATCH_FORMAT : String = "Arvio: %s, EBC %d, IBU %d, laatu %d%%"


## `preview` is null when the table is not brewable yet; `style_known` only matters
## for a matched preview.
static func text(table_empty : bool, preview : BrewResult, style_known : bool) -> String:
	if table_empty:
		return UiText.of(EMPTY_TEXT)
	if preview == null:
		return UiText.of(NOT_ENOUGH_TEXT)
	if not preview.is_matched:
		return UiText.of(NO_MATCH_FORMAT) % [preview.final_ebc, preview.final_ibu]
	if not style_known:
		return UiText.of(UNKNOWN_MATCH_FORMAT) % [preview.final_ebc, preview.final_ibu]
	return UiText.of(KNOWN_MATCH_FORMAT) % [UiText.of(preview.beer_style.style_name), preview.final_ebc, preview.final_ibu, roundi(preview.original_quality * 100)] \
			+ SpicePreviewText.line(preview.spice_bonus)
