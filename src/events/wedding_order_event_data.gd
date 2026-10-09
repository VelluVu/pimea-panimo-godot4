class_name WeddingOrderEventData
extends SpecialEventData

## A wedding wants a light beer (required_style) and an alcohol-free one, both rolled
## from the styles the player knows each time it shows up (prepared()). It pays more
## than shipping the bottles to the best bar would, but less than the pub price.
## intro_dialogue takes the two style names (%s, %s).

const DELIVERY_FORMAT: String = "Toimita %d × %s ja %d × %s.\nVarastossa: %d / %d ja %d / %d"
const REQUIREMENT_FORMAT: String = "%s ja %s"

@export_group("Hääpyyntö")
## Light beer: stronger than alcohol-free, at most this strong.
@export var max_light_abv: float = 5.0
@export var max_alcohol_free_abv: float = 0.5
@export var alcohol_free_bottles: int = 10
## Where the money lands between the best export payout (0) and the pub price (1).
@export var pub_share: float = 0.5
## Never less than this times the export payout, for a batch that exports above pub price.
@export var min_over_export: float = 1.1

## Rolled by prepared() and saved with an open window.
@export var alcohol_free_style: BeerStyle.Style = BeerStyle.Style.ALKOHOLITON_LAGER
@export var export_price_multiplier: float = 1.0


## Never rolled before the player knows a style of each kind.
func get_weight(brewery: Brewery) -> float:
	if _known_styles(brewery, max_alcohol_free_abv, max_light_abv).is_empty():
		return 0.0
	if _known_styles(brewery, -1.0, max_alcohol_free_abv).is_empty():
		return 0.0
	return super(brewery)


func prepared(brewery: Brewery, bars: Array[BarContact]) -> SpecialEventData:
	var light: Array[BeerStyle.Style] = _known_styles(brewery, max_alcohol_free_abv, max_light_abv)
	var alcohol_free: Array[BeerStyle.Style] = _known_styles(brewery, -1.0, max_alcohol_free_abv)
	if light.is_empty() or alcohol_free.is_empty():
		return self
	var rolled := duplicate() as WeddingOrderEventData
	rolled.required_style = light.pick_random()
	rolled.alcohol_free_style = alcohol_free.pick_random()
	rolled.export_price_multiplier = best_export_multiplier(bars, brewery.reputation)
	return rolled


func intro_text() -> String:
	return tr(intro_dialogue) % [_style_name(required_style), _style_name(alcohol_free_style)]


func requirement_name() -> String:
	return UiText.of(REQUIREMENT_FORMAT) % [_style_name(required_style), _style_name(alcohol_free_style)]


func delivery_text(inventory: Inventory) -> String:
	var light: int = _bottles_of(inventory, required_style)
	var alcohol_free: int = _bottles_of(inventory, alcohol_free_style)
	return UiText.of(DELIVERY_FORMAT) % [
		required_bottles, _style_name(required_style), alcohol_free_bottles, _style_name(alcohol_free_style),
		mini(light, required_bottles), required_bottles, mini(alcohol_free, alcohol_free_bottles), alcohol_free_bottles]


## Each style counts up to what is asked of it, so a full cellar of one does not cover the other.
func delivery_progress(inventory: Inventory) -> Vector2i:
	var have: int = mini(_bottles_of(inventory, required_style), required_bottles) \
			+ mini(_bottles_of(inventory, alcohol_free_style), alcohol_free_bottles)
	return Vector2i(have, required_bottles + alcohol_free_bottles)


func try_fulfill(brewery: Brewery) -> bool:
	var light_batch: BrewBatch = _find_batch_by_style(brewery.inventory, required_style)
	var alcohol_free_batch: BrewBatch = _find_batch_by_style(brewery.inventory, alcohol_free_style)
	if light_batch == null or light_batch.amount_bottles < required_bottles:
		return false
	if alcohol_free_batch == null or alcohol_free_batch.amount_bottles < alcohol_free_bottles:
		return false

	var payout: float = _payout(brewery, light_batch, required_bottles) + _payout(brewery, alcohol_free_batch, alcohol_free_bottles)
	_take(brewery.inventory, light_batch, required_bottles)
	_take(brewery.inventory, alcohol_free_batch, alcohol_free_bottles)
	brewery.change_money(snappedf(payout, 0.1), MoneyLedger.Source.EVENTS)
	_apply_rewards(brewery)
	return true


## Between the export payout and the pub income of the same bottles, see pub_share.
static func reward_between(export_payout: float, pub_income: float, share: float, floor_multiplier: float) -> float:
	return maxf(lerpf(export_payout, pub_income, share), export_payout * floor_multiplier)


## The best price the player could ship to; a bar not yet unlocked does not count.
static func best_export_multiplier(bars: Array[BarContact], reputation: int) -> float:
	var best: float = 0.0
	for bar: BarContact in bars:
		if reputation >= bar.required_reputation:
			best = maxf(best, bar.price_multiplier)
	return best if best > 0.0 else 1.0


## Styles stronger than `above_abv` and at most `up_to_abv`.
static func styles_between(styles: Array[BeerStyle], above_abv: float, up_to_abv: float) -> Array[BeerStyle.Style]:
	var found: Array[BeerStyle.Style] = []
	for beer_style: BeerStyle in styles:
		if beer_style.abv > above_abv and beer_style.abv <= up_to_abv:
			found.append(beer_style.style)
	return found


func _known_styles(brewery: Brewery, above_abv: float, up_to_abv: float) -> Array[BeerStyle.Style]:
	var known: Array[BeerStyle.Style] = []
	for style: BeerStyle.Style in styles_between(brewery.resolver.active_styles, above_abv, up_to_abv):
		if brewery.is_style_known(style):
			known.append(style)
	return known


## What these bottles would bring shipped to the best bar, and in the pub, then the share between.
func _payout(brewery: Brewery, batch: BrewBatch, bottles: int) -> float:
	var breakdown: SaleBreakdown = brewery.resolver.get_price_breakdown(batch.beer_style)
	var export_payout: float = BatchDistributor.calculate_ship_payout(breakdown.raw_cost_per_bottle, batch.current_quality, bottles, export_price_multiplier) \
			* brewery.stats.multiplier(PerkStats.DISTRIBUTION_INCOME) * batch.get_aged_price_multiplier()
	return reward_between(export_payout, breakdown.price_per_bottle * bottles, pub_share, min_over_export)


func _take(inventory: Inventory, batch: BrewBatch, bottles: int) -> void:
	batch.amount_bottles -= bottles
	if batch.amount_bottles <= 0:
		inventory.brew_batches.erase(batch)


func _bottles_of(inventory: Inventory, style: BeerStyle.Style) -> int:
	var batch: BrewBatch = _find_batch_by_style(inventory, style)
	return batch.amount_bottles if batch != null else 0


func _style_name(style: BeerStyle.Style) -> String:
	return BeerStyle.get_style_string_from_style(style)
