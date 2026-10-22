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
## The grade after the brew day, since the quality percentage alone does not say it.
const NORMAL_DAY_FORMAT : String = "Normaali keitto: %s"
const AUTO_KETTLE_FORMAT : String = "Automaattikattila: %s"


## `preview` is null when the table is not brewable yet; `style_known` only matters
## for a matched preview. `quality_bonus` is the perks' flat bonus, as Brewer adds it.
static func text(table_empty : bool, preview : BrewResult, style_known : bool, auto_kettle : bool = false, quality_bonus : float = 0.0) -> String:
	if table_empty:
		return UiText.of(EMPTY_TEXT)
	if preview == null:
		return UiText.of(NOT_ENOUGH_TEXT)
	if not preview.is_matched:
		return UiText.of(NO_MATCH_FORMAT) % [preview.final_ebc, preview.final_ibu, preview.abv]
	if not style_known:
		return UiText.of(UNKNOWN_MATCH_FORMAT) % [preview.final_ebc, preview.final_ibu, preview.abv]
	return UiText.of(KNOWN_MATCH_FORMAT) % [UiText.of(preview.beer_style.style_name), preview.final_ebc, preview.final_ibu, preview.abv, roundi(preview.original_quality * 100)] \
			+ _grade_line(preview.original_quality + quality_bonus, auto_kettle) \
			+ SpicePreviewText.line(preview.spice_bonus, preview.unsuited_spice_penalty) + _malt_line(preview.malt_bonus) \
			+ BrewAimText.lines(preview)


static func _grade_line(quality : float, auto_kettle : bool) -> String:
	var multiplier : float = BrewDayRules.AUTO_KETTLE_MULTIPLIER if auto_kettle else BrewDayRules.NORMAL_MULTIPLIER
	var brewed : float = snappedf(quality * multiplier, BrewResolver.QUALITY_PRECISION)
	return "\n" + UiText.of(AUTO_KETTLE_FORMAT if auto_kettle else NORMAL_DAY_FORMAT) % QualityTier.label(brewed)


static func _malt_line(malt_bonus : float) -> String:
	var percent : int = roundi(malt_bonus * 100.0)
	return "\n" + UiText.of(MALT_FORMAT) % percent if percent > 0 else ""
