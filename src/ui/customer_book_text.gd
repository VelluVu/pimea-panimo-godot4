class_name CustomerBookText
extends RefCounted

## What the Asiakaskirja says about one customer type. A met customer shows their
## tastes and limits; one not served yet only says how to learn them.

const NOT_MET_TEXT : String = "Ei vielä tavattu. Palvele kerran, niin opit hänen makunsa."
const FAVOURITE_FORMAT : String = "Suosikki: %s"
const SECOND_FORMAT : String = "Käy myös: %s"
const VARYING_FAVOURITE_TEXT : String = "Suosikki: vaihtelee joka käynnillä"
const ANY_STYLE_TEXT : String = "Ei suosikkia: ottaa mitä tahansa hyllystä löytyy"
const ACCEPTED_FORMAT : String = "Juo vain: %s"
const ROLLED_FAVOURITE_FORMAT : String = "Suosikki vaihtelee joka käynnillä: %s"
const SAME_GROUP_TEXT : String = "muut samasta joukosta"
const LAST_RESORT_FORMAT : String = "Hätävaralla: %s"
const NOTHING_ELSE_TEXT : String = "Muuta ei juo."
const QUALITY_FORMAT : String = "Laatutoive: vähintään %d %%"
const MIN_ABV_FORMAT : String = "Vähintään %s %% alkoholia"
const MAX_ABV_FORMAT : String = "Enintään %s %% alkoholia"
const MAX_PRICE_FORMAT : String = "Enintään %s annokselta"
const LOWERS_RISK_TEXT : String = "Suosikki laskee LVV-riskiä"
const LOCKED_FORMAT : String = "%d asiakastyyppiä vielä tuntematta."
const LIST_SEPARATOR : String = ", "


## `style_names` maps BeerStyle.Style to the style's display name.
static func lines(data : CustomerData, met : bool, style_names : Dictionary) -> PackedStringArray:
	var result : PackedStringArray = []
	if not met:
		result.append(NOT_MET_TEXT)
		return result

	if data.uses_taste_tiers():
		result.append_array(tier_lines(data))
	elif data.picks_at_random:
		result.append(ANY_STYLE_TEXT)
	elif data.randomizes_preference:
		result.append(VARYING_FAVOURITE_TEXT)
	else:
		result.append(UiText.of(FAVOURITE_FORMAT) % style_names.get(data.primary_style, ""))
		var seconds : PackedStringArray = [style_names.get(data.secondary_style, "")]
		for style : BeerStyle.Style in data.also_likes:
			seconds.append(style_names.get(style, ""))
		result.append(UiText.of(SECOND_FORMAT) % LIST_SEPARATOR.join(seconds))
	if not data.accepted_styles.is_empty():
		var accepted : PackedStringArray = []
		for style : BeerStyle.Style in data.accepted_styles:
			accepted.append(style_names.get(style, ""))
		result.append(UiText.of(ACCEPTED_FORMAT) % LIST_SEPARATOR.join(accepted))

	result.append(UiText.of(QUALITY_FORMAT) % roundi(data.min_quality * 100.0))
	if data.min_required_abv >= 0.0:
		result.append(UiText.of(MIN_ABV_FORMAT) % NumberText.decimal(data.min_required_abv, 1))
	if data.max_required_abv >= 0.0:
		result.append(UiText.of(MAX_ABV_FORMAT) % NumberText.decimal(data.max_required_abv, 1))
	if data.max_required_price >= 0.0:
		result.append(UiText.of(MAX_PRICE_FORMAT) % NumberText.money(data.max_required_price))
	# The only sales that pay off risk; without this line players never learn it.
	if data.risk_primary_style < 0 and not data.randomizes_preference and not data.picks_at_random:
		result.append(UiText.of(LOWERS_RISK_TEXT))
	return result


## Favourite, second and last resort tiers by their TasteRule labels.
static func tier_lines(data : CustomerData) -> PackedStringArray:
	var result : PackedStringArray = []
	var favourites : String = _labels(data.favourite_rules)
	if data.rolls_favourite:
		result.append(UiText.of(ROLLED_FAVOURITE_FORMAT) % favourites)
	else:
		result.append(UiText.of(FAVOURITE_FORMAT) % favourites)
	var seconds : PackedStringArray = []
	if data.rolls_favourite:
		seconds.append(UiText.of(SAME_GROUP_TEXT))
	if not data.second_rules.is_empty():
		seconds.append(_labels(data.second_rules))
	if not seconds.is_empty():
		result.append(UiText.of(SECOND_FORMAT) % LIST_SEPARATOR.join(seconds))
	if not data.last_resort_rules.is_empty():
		result.append(UiText.of(LAST_RESORT_FORMAT) % _labels(data.last_resort_rules))
	result.append(UiText.of(NOTHING_ELSE_TEXT))
	return result


static func _labels(rules : Array[TasteRule]) -> String:
	var labels : PackedStringArray = []
	for rule : TasteRule in rules:
		labels.append(rule.label)
	return LIST_SEPARATOR.join(labels)


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
