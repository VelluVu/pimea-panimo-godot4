class_name BrewBatch
extends Resource


@export var beer_style: BeerStyle

@export var final_ebc: int = 0
@export var final_ibu: int = 0

@export var original_quality: float = 1.0
@export var current_quality : float = 1.0
@export var amount_bottles: int = 40
@export var age_in_days: int = 0


func get_style_name() -> String:
	return BeerStyle.get_style_string_from_style(beer_style.style)


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
				
	current_quality = clampf(current_quality, 0.1, 2.5)
