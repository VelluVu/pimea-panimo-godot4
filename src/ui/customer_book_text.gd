class_name CustomerBookText
extends RefCounted

## What the Asiakaskirja says about one customer type. A met customer shows their
## tastes and limits; one not served yet only says how to learn them.

const NOT_MET_TEXT : String = "Ei vielä tavattu. Palvele kerran, niin opit hänen makunsa."
const FAVOURITE_FORMAT : String = "Suosikki: %s"
const SECOND_FORMAT : String = "Käy myös: %s"
const VARYING_FAVOURITE_TEXT : String = "Suosikki: vaihtelee joka käynnillä"
const ACCEPTED_FORMAT : String = "Juo vain: %s"
const QUALITY_FORMAT : String = "Laatutoive: vähintään %d %%"
const MIN_ABV_FORMAT : String = "Vähintään %.1f %% alkoholia"
const MAX_ABV_FORMAT : String = "Enintään %.1f %% alkoholia"
const MAX_PRICE_FORMAT : String = "Enintään %.2f € pullolta"
const LOCKED_FORMAT : String = "%d asiakastyyppiä vielä tuntematta."
const LIST_SEPARATOR : String = ", "


## `style_names` maps BeerStyle.Style to the style's display name.
static func lines(data : CustomerData, met : bool, style_names : Dictionary) -> PackedStringArray:
	var result : PackedStringArray = []
	if not met:
		result.append(NOT_MET_TEXT)
		return result

	if data.randomizes_preference:
		result.append(VARYING_FAVOURITE_TEXT)
	else:
		result.append(UiText.of(FAVOURITE_FORMAT) % style_names.get(data.primary_style, ""))
		result.append(UiText.of(SECOND_FORMAT) % style_names.get(data.secondary_style, ""))
	if not data.accepted_styles.is_empty():
		var accepted : PackedStringArray = []
		for style : BeerStyle.Style in data.accepted_styles:
			accepted.append(style_names.get(style, ""))
		result.append(UiText.of(ACCEPTED_FORMAT) % LIST_SEPARATOR.join(accepted))

	result.append(UiText.of(QUALITY_FORMAT) % roundi(data.min_quality * 100.0))
	if data.min_required_abv >= 0.0:
		result.append(UiText.of(MIN_ABV_FORMAT) % data.min_required_abv)
	if data.max_required_abv >= 0.0:
		result.append(UiText.of(MAX_ABV_FORMAT) % data.max_required_abv)
	if data.max_required_price >= 0.0:
		result.append(UiText.of(MAX_PRICE_FORMAT) % data.max_required_price)
	return result


static func locked_line(locked_count : int) -> String:
	return UiText.of(LOCKED_FORMAT) % locked_count if locked_count > 0 else ""


## One customer per title (gendered variants share one), in `customers` order.
static func unique_by_title(customers : Array[CustomerData]) -> Array[CustomerData]:
	var seen : Dictionary = {}
	var result : Array[CustomerData] = []
	for customer : CustomerData in customers:
		if seen.has(customer.title):
			continue
		seen[customer.title] = true
		result.append(customer)
	return result
