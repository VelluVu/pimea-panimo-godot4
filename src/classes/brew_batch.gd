class_name BrewBatch
extends Resource


@export var beer_style: BeerStyle

@export var final_ebc: int = 0
@export var final_ibu: int = 0

@export var original_quality: float = 1.0
@export var current_quality : float = 1.0
@export var amount_bottles: int = 40
@export var age_in_days: int = 0

@export var precision_score : float = 1.0
@export var hop_diversity_count : int = 0
@export var hop_balance_bonus : float = 0.0
@export var flavor_matched : bool = false


func get_style_name() -> String:
	return BeerStyle.get_style_string_from_style(beer_style.style)


func get_quality_tier_string() -> String:
	if current_quality < 0.7:
		return StringContainer.QUALITY_TIER_POOR
	elif current_quality < 0.9:
		return StringContainer.QUALITY_TIER_MEDIOCRE
	elif current_quality < 1.1:
		return StringContainer.QUALITY_TIER_GOOD
	elif current_quality < 1.3:
		return StringContainer.QUALITY_TIER_EXCELLENT
	else:
		return StringContainer.QUALITY_TIER_MASTERFUL


func get_quality_breakdown_tooltip() -> String:
	var flavor_matched_string : String = StringContainer.YES_STRING if flavor_matched else StringContainer.NO_STRING

	return StringContainer.BREW_QUALITY_BREAKDOWN_TOOLTIP % [
		roundi(precision_score * 100),
		hop_diversity_count,
		roundi(hop_balance_bonus * 100),
		flavor_matched_string
	]


const FULL_INFO_TOOLTIP_HEADER_FORMAT : String = "Laatu: %s%% (%s)\nEBC: %s | IBU: %s\n"

## Combines the header stats (quality/EBC/IBU) that used to sit in the
## batch row's visible text with the existing breakdown tooltip, so the
## row itself can stay to a single compact line.
func get_full_info_tooltip() -> String:
	return FULL_INFO_TOOLTIP_HEADER_FORMAT % [
		roundi(current_quality * 100),
		get_quality_tier_string(),
		final_ebc,
		final_ibu
	] + get_quality_breakdown_tooltip()


func age_one_day() -> void:
	age_in_days += 1
	_calculate_current_quality()


func _calculate_current_quality() -> void:
	if age_in_days <= beer_style.peak_days:
		if beer_style.peak_days > 0:
			var progress = float(age_in_days) / float(beer_style.peak_days)
			current_quality = original_quality + (beer_style.aging_factor * progress)
	else:
		var days_past_peak = age_in_days - beer_style.peak_days
		if days_past_peak > beer_style.shelf_life_days:
			var spoilage_days = days_past_peak - beer_style.shelf_life_days
			if beer_style.aging_factor < 0:
				current_quality = original_quality + (beer_style.aging_factor * spoilage_days)
			else:
				current_quality = original_quality - (0.02 * spoilage_days)
				
	current_quality = snappedf(clampf(current_quality, 0.1, 2.5), 0.01)
