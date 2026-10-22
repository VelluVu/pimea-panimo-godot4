class_name BrewAimText
extends RefCounted

## The preview's hint for a known style: where its EBC, IBU and ABV windows centre when
## the recipe sits far from it, and the missing style flavour. A first brew of a style is
## rarely good; this shows what the next one should change.

const AIM_FORMAT : String = "Tyylin keskikohta: %s"
const EBC_FORMAT : String = "EBC %d"
const IBU_FORMAT : String = "IBU %d"
const ABV_FORMAT : String = "%.1f %% ABV"
const NO_FLAVOR_FORMAT : String = "Tyylin humala tai mauste puuttuu: -%d %%"
## Below this precision a value is worth moving; the reference recipes sit above it.
const AIM_BELOW : float = 0.8


static func lines(preview : BrewResult) -> String:
	var beer_style : BeerStyle = preview.beer_style
	var parts : Array[String] = []
	if BrewQuality.range_precision(preview.final_ebc, beer_style.min_ebc, beer_style.max_ebc) < AIM_BELOW:
		parts.append(UiText.of(EBC_FORMAT) % roundi(_centre(beer_style.min_ebc, beer_style.max_ebc)))
	if BrewQuality.ibu_precision(preview.final_ibu, beer_style.min_ibu, beer_style.max_ibu) < AIM_BELOW:
		parts.append(UiText.of(IBU_FORMAT) % roundi(_centre(beer_style.min_ibu, beer_style.max_ibu)))
	if BrewQuality.range_precision(preview.abv, beer_style.min_abv, beer_style.max_abv) < AIM_BELOW:
		parts.append(UiText.of(ABV_FORMAT) % _centre(beer_style.min_abv, beer_style.max_abv))
	var result : String = ""
	if not parts.is_empty():
		result += "\n" + UiText.of(AIM_FORMAT) % ", ".join(parts)
	if not preview.flavor_matched and _has_flavor(beer_style):
		result += "\n" + UiText.of(NO_FLAVOR_FORMAT) % roundi(BrewQuality.FLAVOR_MATCH_BONUS * 100.0)
	return result


static func _centre(min_v : float, max_v : float) -> float:
	return (min_v + max_v) / 2.0


## Styles with neither a preferred hop nor a required spice can never match a flavour.
static func _has_flavor(beer_style : BeerStyle) -> bool:
	return not beer_style.preferred_hop_profiles.is_empty() or not beer_style.required_spice_ids.is_empty()
