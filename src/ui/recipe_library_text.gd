class_name RecipeLibraryText
extends RefCounted

## The style rows of the recipe library. A known style shows everything; a locked one
## deliberately withholds the exact EBC/IBU ranges (the "brew it to find out" part) but
## gives more to go on than the yeast alone: ABV is a fixed style property, so revealing it
## spoils nothing, and the malt weight is only a floor. The color and bitterness hints are
## coarse buckets, see BeerStyle.get_color_hint() and get_bitterness_hint().

## The name gets a line of its own so the list reads at a glance.
const KNOWN_ROW_FORMAT : String = "%s\n%.1f%% ABV, EBC %s-%s, IBU %s-%s, hiiva: %s"
const SAVED_RECIPES_HINT_FORMAT : String = "Tallennettuja reseptejä: %d"
const KNOWN_HEADER_FORMAT : String = "Löydetyt tyylit (%d/%d)"
const LOCKED_HEADER_FORMAT : String = "Löytämättömät tyylit (%d)"
const LOCKED_ROW_FORMAT : String = "??? (%.1f%% ABV) – vaatii: hiiva %s, vähintään %d kg mallasta"
## The hints below each go on their own line under the row.
const HOP_HINT_FORMAT : String = "Suosikkihumala: %s"
const MALT_HINT_FORMAT : String = "Vaadittu mallas: %s"
const REQUIRED_SPICE_HINT_FORMAT : String = "Vaatii myös: %s"
const PREFERRED_SPICES_HINT_FORMAT : String = "Sopivat mausteet: %s"
const PURITY_LAW_HINT : String = "Reinheitsgebot: ei mausteita"
const COLOR_HINT_FORMAT : String = "Väri: %s"
const BITTERNESS_HINT_FORMAT : String = "Katkeruus: %s"
const MALT_BLEND_HINT : String = "Vaatii mallasseoksen"
const NEW_CUSTOMER_HINT : String = "Houkuttelee uuden asiakkaan"


static func known_section_title(known_count : int, total_count : int) -> String:
	return UiText.of(KNOWN_HEADER_FORMAT) % [known_count, total_count]


static func locked_section_title(locked_count : int) -> String:
	return UiText.of(LOCKED_HEADER_FORMAT) % locked_count


static func known_row(beer_style : BeerStyle, yeast_name : String, required_malt_name : String, required_spice_name : String = "", preferred_spice_names : String = "", saved_recipe_count : int = 0) -> String:
	var text : String = UiText.of(KNOWN_ROW_FORMAT) % [
		UiText.of(beer_style.style_name), beer_style.abv,
		beer_style.min_ebc, beer_style.max_ebc, beer_style.min_ibu, beer_style.max_ibu,
		yeast_name,
	]
	text += _hop_and_malt_hints(beer_style, required_malt_name, required_spice_name)
	if beer_style.forbids_spices:
		text += "\n" + UiText.of(PURITY_LAW_HINT)
	if not preferred_spice_names.is_empty():
		text += "\n" + UiText.of(PREFERRED_SPICES_HINT_FORMAT) % preferred_spice_names
	if saved_recipe_count > 0:
		text += "\n" + UiText.of(SAVED_RECIPES_HINT_FORMAT) % saved_recipe_count
	return text


## `needs_malt_blend` only matters for a style with no single required malt.
## `attracts_new_customer`: discovering the style unlocks a customer for good.
static func locked_row(beer_style : BeerStyle, yeast_name : String, required_malt_name : String, needs_malt_blend : bool, required_spice_name : String = "", attracts_new_customer : bool = false) -> String:
	var text : String = UiText.of(LOCKED_ROW_FORMAT) % [beer_style.abv, yeast_name, beer_style.min_malt_weight]
	text += "\n" + UiText.of(COLOR_HINT_FORMAT) % BeerStyle.get_color_hint(beer_style.min_ebc, beer_style.max_ebc)
	text += "\n" + UiText.of(BITTERNESS_HINT_FORMAT) % BeerStyle.get_bitterness_hint(beer_style.min_ibu, beer_style.max_ibu)
	text += _hop_and_malt_hints(beer_style, required_malt_name, required_spice_name)
	if beer_style.required_malt_id == BrewMixture.NO_REQUIRED_MALT and needs_malt_blend:
		text += "\n" + UiText.of(MALT_BLEND_HINT)
	if attracts_new_customer:
		text += "\n" + UiText.of(NEW_CUSTOMER_HINT)
	return text


static func _hop_and_malt_hints(beer_style : BeerStyle, required_malt_name : String, required_spice_name : String) -> String:
	var text : String = ""
	if beer_style.preferred_hop_profile != HopData.FlavorProfile.NONE:
		text += "\n" + UiText.of(HOP_HINT_FORMAT) % HopData.get_flavor_profile_display_name(beer_style.preferred_hop_profile)
	if beer_style.required_malt_id != BrewMixture.NO_REQUIRED_MALT:
		text += "\n" + UiText.of(MALT_HINT_FORMAT) % required_malt_name
	if beer_style.required_spice_id != BrewMixture.NO_REQUIRED_SPICE:
		text += "\n" + UiText.of(REQUIRED_SPICE_HINT_FORMAT) % required_spice_name
	return text
