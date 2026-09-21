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
const COLOR_HINT_FORMAT : String = "\nVäri: %s"
const BITTERNESS_HINT_FORMAT : String = "\nKatkeruus: %s"
const MALT_BLEND_HINT : String = "\nVaatii mallasseoksen"


static func known_row(beer_style : BeerStyle, yeast_name : String, required_malt_name : String) -> String:
	var text : String = KNOWN_ROW_FORMAT % [
		beer_style.style_name, beer_style.abv,
		beer_style.min_ebc, beer_style.max_ebc, beer_style.min_ibu, beer_style.max_ibu,
		yeast_name,
	]
	return text + _hop_and_malt_hints(beer_style, required_malt_name)


## `needs_malt_blend` only matters for a style with no single required malt.
static func locked_row(beer_style : BeerStyle, yeast_name : String, required_malt_name : String, needs_malt_blend : bool) -> String:
	var text : String = LOCKED_ROW_FORMAT % [beer_style.abv, yeast_name, beer_style.min_malt_weight]
	text += COLOR_HINT_FORMAT % BeerStyle.get_color_hint(beer_style.min_ebc, beer_style.max_ebc)
	text += BITTERNESS_HINT_FORMAT % BeerStyle.get_bitterness_hint(beer_style.min_ibu, beer_style.max_ibu)
	text += _hop_and_malt_hints(beer_style, required_malt_name)
	if beer_style.required_malt_id == BrewMixture.NO_REQUIRED_MALT and needs_malt_blend:
		text += MALT_BLEND_HINT
	return text


static func _hop_and_malt_hints(beer_style : BeerStyle, required_malt_name : String) -> String:
	var text : String = ""
	if beer_style.preferred_hop_profile != HopData.FlavorProfile.NONE:
		text += HOP_HINT_FORMAT % HopData.get_flavor_profile_display_name(beer_style.preferred_hop_profile)
	if beer_style.required_malt_id != BrewMixture.NO_REQUIRED_MALT:
		text += MALT_HINT_FORMAT % required_malt_name
	return text
