class_name BrewBatch
extends Resource


@export var beer_style: BeerStyle

@export var final_ebc: int = 0
@export var final_ibu: int = 0

@export var original_quality: float = 1.0
@export var current_quality : float = 1.0
## Schema default only — a real batch's value always comes from Brewery.
## start_brew()'s effective_yield (see BrewResult.bottle_yield's docstring
## for the 20L-keg/0.44L-serving math behind 45).
@export var amount_bottles: int = 45
@export var age_in_days: int = 0

@export var precision_score : float = 1.0
@export var hop_diversity_count : int = 0
@export var hop_balance_bonus : float = 0.0
@export var flavor_matched : bool = false

## Snapshotted once from Brewery.get_peak_speed_multiplier()/
## get_decline_rate_multiplier() when this batch is brewed (see
## RunPerk.peak_speed_multiplier's docstring for why these are captured
## here instead of read from active_perks continuously) — neutral 1.0
## defaults mean an untouched batch (or a save from before this field
## existed) ages exactly as it always did.
@export var peak_days_multiplier : float = 1.0
@export var decline_rate_multiplier : float = 1.0


## BeerStyle.peak_days scaled by this batch's own peak_days_multiplier —
## the actual number of days this specific batch takes to reach peak
## quality, used by both _calculate_current_quality() and
## get_aging_trend_icon() so the visible trend arrow always agrees with
## the quality number actually being shown.
func get_effective_peak_days() -> int:
	return roundi(beer_style.peak_days * peak_days_multiplier)


func get_style_name() -> String:
	return BeerStyle.get_style_string_from_style(beer_style.style)


const AGING_TREND_RISING : String = "↑"
const AGING_TREND_PLATEAU : String = "→"
const AGING_TREND_DECLINING : String = "↓"

## Whether quality is still rising toward peak, holding at its plateau, or
## has moved into post-shelf-life decline — mirrors the three phases in
## _calculate_current_quality() below. Purely presentational: lets
## BeerBatchPanel show players "hold this" vs. "sell this now" at a glance
## instead of the trend only being inferable by watching the quality
## number change over several aging ticks.
func get_aging_trend_icon() -> String:
	var effective_peak_days : int = get_effective_peak_days()
	if age_in_days < effective_peak_days:
		return AGING_TREND_RISING

	var days_past_peak : int = age_in_days - effective_peak_days
	if days_past_peak > beer_style.shelf_life_days:
		return AGING_TREND_DECLINING

	return AGING_TREND_PLATEAU


const AGING_TREND_RISING_LABEL : String = "kypsyy vielä"
const AGING_TREND_PLATEAU_LABEL : String = "parhaimmillaan"
const AGING_TREND_DECLINING_LABEL : String = "heikkenee"

## Plain-language counterpart to get_aging_trend_icon() for the tooltip —
## the row itself only has room for the bare arrow.
func get_aging_trend_label() -> String:
	match get_aging_trend_icon():
		AGING_TREND_RISING:
			return AGING_TREND_RISING_LABEL
		AGING_TREND_DECLINING:
			return AGING_TREND_DECLINING_LABEL
		_:
			return AGING_TREND_PLATEAU_LABEL


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


const FULL_INFO_TOOLTIP_HEADER_FORMAT : String = "Laatu: %s%% (%s %s, %s)\nEBC: %s | IBU: %s | ABV: %.1f%%\n"

## Combines the header stats (quality/EBC/IBU/ABV) that used to sit in the
## batch row's visible text with the existing breakdown tooltip, so the
## row itself can stay to a single compact line. Spells out the aging
## trend arrow in words here since the row has no room to.
func get_full_info_tooltip() -> String:
	return FULL_INFO_TOOLTIP_HEADER_FORMAT % [
		roundi(current_quality * 100),
		get_quality_tier_string(),
		get_aging_trend_icon(),
		get_aging_trend_label(),
		final_ebc,
		final_ibu,
		beer_style.abv
	] + get_quality_breakdown_tooltip()


## Called once per TimeManager aging tick (TimeManager.AGING_TICK_SECONDS,
## currently every 30s of real time) rather than once per in-game day — see
## BeerStyle.peak_days' docstring for why the "_days" naming stuck around
## anyway.
func age_one_day() -> void:
	age_in_days += 1
	_calculate_current_quality()


func _calculate_current_quality() -> void:
	var effective_peak_days : int = get_effective_peak_days()

	if age_in_days <= effective_peak_days:
		if effective_peak_days > 0:
			var progress = float(age_in_days) / float(effective_peak_days)
			current_quality = original_quality + (beer_style.aging_factor * progress)
	else:
		var days_past_peak = age_in_days - effective_peak_days
		if days_past_peak > beer_style.shelf_life_days:
			var spoilage_days = days_past_peak - beer_style.shelf_life_days
			if beer_style.aging_factor < 0:
				current_quality = original_quality + (beer_style.aging_factor * spoilage_days * decline_rate_multiplier)
			else:
				current_quality = original_quality - (0.02 * spoilage_days * decline_rate_multiplier)

	current_quality = snappedf(clampf(current_quality, 0.1, 2.5), 0.01)
