class_name RecipeLibraryText
extends RefCounted

## The style rows of the recipe library. A known style shows everything; a locked one
## deliberately withholds the exact EBC/IBU ranges (the "brew it to find out" part) but
## gives more to go on than the yeast alone: ABV is a fixed style property, so revealing it
## spoils nothing, and the malt weight is only a floor. The color and bitterness hints are
## coarse buckets, see BeerStyle.get_color_hint() and get_bitterness_hint().

const KNOWN_ROW_FORMAT : String = "%s (%.1f%% ABV), EBC %s-%s, IBU %s-%s (hiiva: %s)"
const LOCKED_ROW_FORMAT : String = "??? (%.1f%% ABV) – vaatii: hiiva %s, vähintään %d kg mallasta"
const HOP_HINT_FORMAT : String = "\nSuosikkihumala: %s"
const MALT_HINT_FORMAT : String = "\nVaadittu mallas: %s"
const REQUIRED_SPICE_HINT_FORMAT : String = "\nVaatii myös: %s"
const PREFERRED_SPICES_HINT_FORMAT : String = "\nSopivat mausteet: %s"
const PURITY_LAW_HINT : String = "\nReinheitsgebot: ei mausteita"
const COLOR_HINT_FORMAT : String = "\nVäri: %s"
const BITTERNESS_HINT_FORMAT : String = "\nKatkeruus: %s"
const MALT_BLEND_HINT : String = "\nVaatii mallasseoksen"


static func known_row(beer_style : BeerStyle, yeast_name : String, required_malt_name : String, required_spice_name : String = "", preferred_spice_names : String = "") -> String:
	var text : String = UiText.of(KNOWN_ROW_FORMAT) % [
		UiText.of(beer_style.style_name), beer_style.abv,
		beer_style.min_ebc, beer_style.max_ebc, beer_style.min_ibu, beer_style.max_ibu,
		yeast_name,
	]
	text += _hop_and_malt_hints(beer_style, required_malt_name, required_spice_name)
	if beer_style.forbids_spices:
		text += UiText.of(PURITY_LAW_HINT)
	if not preferred_spice_names.is_empty():
		text += UiText.of(PREFERRED_SPICES_HINT_FORMAT) % preferred_spice_names
	return text


## `needs_malt_blend` only matters for a style with no single required malt.
static func locked_row(beer_style : BeerStyle, yeast_name : String, required_malt_name : String, needs_malt_blend : bool, required_spice_name : String = "") -> String:
	var text : String = UiText.of(LOCKED_ROW_FORMAT) % [beer_style.abv, yeast_name, beer_style.min_malt_weight]
	text += UiText.of(COLOR_HINT_FORMAT) % BeerStyle.get_color_hint(beer_style.min_ebc, beer_style.max_ebc)
	text += UiText.of(BITTERNESS_HINT_FORMAT) % BeerStyle.get_bitterness_hint(beer_style.min_ibu, beer_style.max_ibu)
	text += _hop_and_malt_hints(beer_style, required_malt_name, required_spice_name)
	if beer_style.required_malt_id == BrewMixture.NO_REQUIRED_MALT and needs_malt_blend:
		text += UiText.of(MALT_BLEND_HINT)
	return text


static func _hop_and_malt_hints(beer_style : BeerStyle, required_malt_name : String, required_spice_name : String) -> String:
	var text : String = ""
	if beer_style.preferred_hop_profile != HopData.FlavorProfile.NONE:
		text += UiText.of(HOP_HINT_FORMAT) % HopData.get_flavor_profile_display_name(beer_style.preferred_hop_profile)
	if beer_style.required_malt_id != BrewMixture.NO_REQUIRED_MALT:
		text += UiText.of(MALT_HINT_FORMAT) % required_malt_name
	if beer_style.required_spice_id != BrewMixture.NO_REQUIRED_SPICE:
		text += UiText.of(REQUIRED_SPICE_HINT_FORMAT) % required_spice_name
	return text
