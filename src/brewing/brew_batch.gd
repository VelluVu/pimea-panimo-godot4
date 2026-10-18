class_name BrewBatch
extends Resource


@export var beer_style: BeerStyle

@export var final_ebc: int = 0
@export var final_ibu: int = 0

@export var original_quality: float = 1.0
@export var current_quality : float = 1.0
## Schema default only; a real batch gets Brewer's effective yield (BrewResult.bottle_yield).
@export var amount_bottles: int = 45
## Kept in the cellar: customers skip it until the player releases it, so it can age.
@export var held: bool = false
## Cleanliness of the keg the batch was brewed into, see KegRules.
@export var keg_cleanliness : float = 1.0
## Fermentation time left; a batch in Inventory.fermenting has no keg yet. See FermentationRules.
@export var ferment_seconds_left : float = 0.0
## Soured in a dirty keg, see sour().
@export var infected : bool = false
## Share of quality the souring took; 0 on a save from before souring had strengths.
@export var sour_loss : float = 0.0
@export var age_in_days: int = 0
## The season's first batch of its style, see FirstBrewRules.
@export var novelty: bool = false
## The batch's own ABV; STYLE_ABV (and saves from before this field) use the style's.
@export var abv: float = STYLE_ABV

@export var precision_score : float = 1.0
@export var hop_diversity_count : int = 0
## Old saves only: the retired alpha/beta balance bonus.
@export var hop_balance_bonus : float = 0.0
## Hop layers filled well, out of the style's hop marks.
@export var hop_layers : int = 0
@export var hop_layer_slots : int = 0
@export var flavor_matched : bool = false
@export var spice_bonus : float = 0.0
@export var unsuited_spice_penalty : float = 0.0
## Quality from the style's character malts; 0 on older saves.
@export var malt_bonus : float = 0.0
## What went into the batch (BatchTraits); none on older saves. True when a spice that
## suits the style went in.
@export var spiced : bool = false
@export var malt_ids : Array[int] = []
@export var late_hop_profiles : Array[HopData.FlavorProfile] = []
@export var hop_profiles : Array[HopData.FlavorProfile] = []

## Taken from the perks at brewing, so later perks do not change it. 1.0 = normal aging,
## also for old saves.
@export var peak_days_multiplier : float = 1.0
@export var decline_rate_multiplier : float = 1.0


## Quality lost per aging tick once the shelf life is over, for styles that age well.
const SPOILAGE_PER_TICK : float = 0.02
## Ticks over which the aged price bonus fades once the batch starts to spoil (a day).
const AGED_BONUS_FADE_TICKS : float = 10.0
## Share of a sale's LVV risk an aged batch saves at its peak: an aging cellar draws less
## attention than one pouring volume.
const AGED_RISK_DISCOUNT : float = 0.5


## The price multiplier this batch earns from aging, see BeerStyle.aged_price_bonus.
func get_aged_price_multiplier() -> float:
	return aged_price_multiplier(beer_style.aged_price_bonus, age_in_days, get_effective_peak_days(), beer_style.shelf_life_days)


## A fresh batch of what the brew resolved to: its style, colour, strength and the quality
## breakdown its tooltip shows. `quality` is the final one, after perks and the brew day.
static func from_result(result : BrewResult, bottles : int, quality : float) -> BrewBatch:
	var batch := BrewBatch.new()
	batch.beer_style = result.beer_style
	batch.amount_bottles = bottles
	batch.original_quality = quality
	batch.current_quality = quality
	batch.final_ebc = result.final_ebc
	batch.final_ibu = result.final_ibu
	batch.abv = result.abv
	batch.precision_score = result.precision_score
	batch.hop_diversity_count = result.hop_diversity_count
	batch.hop_layers = result.hop_layers
	batch.hop_layer_slots = result.hop_layer_slots
	batch.flavor_matched = result.flavor_matched
	batch.spice_bonus = result.spice_bonus
	batch.unsuited_spice_penalty = result.unsuited_spice_penalty
	batch.malt_bonus = result.malt_bonus
	return batch


## Grows linearly to 1 + bonus at the peak, holds through the shelf life and fades
## over AGED_BONUS_FADE_TICKS once the batch starts to spoil.
static func aged_price_multiplier(bonus : float, age : int, peak : int, shelf_life : int) -> float:
	return 1.0 + bonus * aging_progress(bonus, age, peak, shelf_life)


## The multiplier on a sale's LVV risk from this batch's aging, see AGED_RISK_DISCOUNT.
func get_aged_risk_multiplier() -> float:
	return 1.0 - AGED_RISK_DISCOUNT * aging_progress(beer_style.aged_price_bonus, age_in_days, get_effective_peak_days(), beer_style.shelf_life_days)


## 0 to 1: how far an aging style (aged_price_bonus > 0) has come toward its peak, fading
## over AGED_BONUS_FADE_TICKS once it starts to spoil. 0 for styles that do not age.
static func aging_progress(bonus : float, age : int, peak : int, shelf_life : int) -> float:
	if bonus <= 0.0 or peak <= 0:
		return 0.0
	var spoiled_ticks : int = age - peak - shelf_life
	var fade : float = 1.0 - clampf(spoiled_ticks / AGED_BONUS_FADE_TICKS, 0.0, 1.0)
	return clampf(float(age) / peak, 0.0, 1.0) * fade


const STYLE_ABV : float = -1.0


func get_abv() -> float:
	return beer_style.abv if abv < 0.0 else abv


func is_alcohol_free() -> bool:
	return get_abv() <= BeerStyle.ALCOHOL_FREE_MAX_ABV


## Days to peak for this batch; the quality and the trend arrow both use it.
func get_effective_peak_days() -> int:
	return roundi(beer_style.peak_days * peak_days_multiplier)


func get_style_name() -> String:
	return BeerStyle.get_style_string_from_style(beer_style.style)


const AGING_TREND_RISING : String = "▲"
const AGING_TREND_PLATEAU : String = "▶"
const AGING_TREND_DECLINING : String = "▼"

## Rising toward the peak, holding or declining, so BeerBatchPanel can say hold or sell.
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

## The words for get_aging_trend_icon(), for the tooltip.
func get_aging_trend_label() -> String:
	match get_aging_trend_icon():
		AGING_TREND_RISING:
			return tr(AGING_TREND_RISING_LABEL)
		AGING_TREND_DECLINING:
			return tr(AGING_TREND_DECLINING_LABEL)
		_:
			return tr(AGING_TREND_PLATEAU_LABEL)


func get_quality_tier_string() -> String:
	if current_quality < 0.7:
		return tr(StringContainer.QUALITY_TIER_POOR)
	elif current_quality < 0.9:
		return tr(StringContainer.QUALITY_TIER_MEDIOCRE)
	elif current_quality < 1.1:
		return tr(StringContainer.QUALITY_TIER_GOOD)
	elif current_quality < 1.3:
		return tr(StringContainer.QUALITY_TIER_EXCELLENT)
	else:
		return tr(StringContainer.QUALITY_TIER_MASTERFUL)


func get_quality_breakdown_tooltip() -> String:
	var flavor_matched_string : String = StringContainer.YES_STRING if flavor_matched else StringContainer.NO_STRING

	return tr(StringContainer.BREW_QUALITY_BREAKDOWN_TOOLTIP) % [
		roundi(precision_score * 100),
		hop_layers,
		hop_layer_slots,
		flavor_matched_string,
		roundi((spice_bonus - unsuited_spice_penalty) * 100),
		roundi(malt_bonus * 100),
	]


const AGED_PRICE_FORMAT : String = "Kypsytyslisä hintaan: +%d %% (enintään +%d %%)"
const FULL_INFO_TOOLTIP_HEADER_FORMAT : String = "Laatu: %s%% (%s %s, %s)\nEBC: %s | IBU: %s | ABV: %.1f%%"

## The header stats and the quality breakdown in one tooltip, so the row stays one line.
func get_full_info_tooltip() -> String:
	return tr(FULL_INFO_TOOLTIP_HEADER_FORMAT) % [
		roundi(current_quality * 100),
		get_quality_tier_string(),
		get_aging_trend_icon(),
		get_aging_trend_label(),
		final_ebc,
		final_ibu,
		get_abv()
	] + "\n" + get_quality_breakdown_tooltip() + _aged_price_line()


func _aged_price_line() -> String:
	if beer_style.aged_price_bonus <= 0.0:
		return ""
	return "\n" + tr(AGED_PRICE_FORMAT) % [roundi((get_aged_price_multiplier() - 1.0) * 100.0), roundi(beer_style.aged_price_bonus * 100.0)]


## A dirty keg soured the batch: `loss` is the share of quality it takes, see
## FermentationRules.sour_loss().
func sour(loss : float) -> void:
	infected = true
	sour_loss = loss
	original_quality = snappedf(original_quality * (1.0 - loss), BrewResolver.QUALITY_PRECISION)
	current_quality = original_quality
	_calculate_current_quality()


## An old save's soured batch has no recorded loss; it lost 30 %, a clear sour.
func get_sour_level() -> FermentationRules.SourLevel:
	if not infected:
		return FermentationRules.SourLevel.NONE
	if sour_loss <= 0.0:
		return FermentationRules.SourLevel.CLEAR
	return FermentationRules.sour_level(sour_loss)


## Called on every TimeManager aging tick, not once a day (see BeerStyle.peak_days).
func age_one_day() -> void:
	age_in_days += 1
	_calculate_current_quality()


func _calculate_current_quality() -> void:
	var effective_peak_days : int = get_effective_peak_days()

	if age_in_days <= effective_peak_days:
		if effective_peak_days > 0:
			var progress : float = float(age_in_days) / float(effective_peak_days)
			current_quality = original_quality + (beer_style.aging_factor * progress)
	else:
		var days_past_peak : int = age_in_days - effective_peak_days
		if days_past_peak > beer_style.shelf_life_days:
			var spoilage_days : int = days_past_peak - beer_style.shelf_life_days
			# Declines from the aged peak, so the aging bonus fades instead of vanishing in one tick.
			var peak_quality : float = original_quality + (beer_style.aging_factor if effective_peak_days > 0 else 0.0)
			var decline_per_tick : float = -beer_style.aging_factor if beer_style.aging_factor < 0 else SPOILAGE_PER_TICK
			current_quality = peak_quality - decline_per_tick * spoilage_days * decline_rate_multiplier

	current_quality = snappedf(clampf(current_quality, 0.1, 2.5), 0.01)
