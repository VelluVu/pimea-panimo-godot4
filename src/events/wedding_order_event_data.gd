class_name WeddingOrderEventData
extends SpecialEventData

## A wedding wants a light beer (required_style) and an alcohol-free one, both rolled
## from the styles the player knows each time it shows up (prepared()). The amount
## does not matter: it takes the best batch on offer of each (_best_batch_of()),
## pays more than shipping them to the best bar would but less than the pub price,
## and grants a perk.
## intro_dialogue takes the two style names (%s, %s).

const DELIVERY_FORMAT: String = "Toimita %s ja %s, määrällä ei väliä.\nVarastossa: %d ja %d annosta"
const REQUIREMENT_FORMAT: String = "%s ja %s"

@export_group("Hääpyyntö")
## Light beer: stronger than alcohol-free, at most this strong.
@export var max_light_abv: float = 5.0
@export var max_alcohol_free_abv: float = 0.5
## Where the money lands between the best export payout (0) and the pub price (1).
@export var pub_share: float = 0.5
## Never less than this times the export payout, for a batch that exports above pub price.
@export var min_over_export: float = 1.1
## Given on each success, so a second wedding stacks it again. Kept out of the
## perks folder so it never shows up on a level-up card.
@export var granted_perk: RunPerk

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
	return UiText.of(DELIVERY_FORMAT) % [_style_name(required_style), _style_name(alcohol_free_style),
		_servings_of(inventory, required_style), _servings_of(inventory, alcohol_free_style)]


## One step per style that has a batch on offer.
func delivery_progress(inventory: Inventory) -> Vector2i:
	var have: int = int(_best_batch_of(inventory, required_style) != null) \
			+ int(_best_batch_of(inventory, alcohol_free_style) != null)
	return Vector2i(have, 2)


func try_fulfill(brewery: Brewery) -> bool:
	var light_batch: BrewBatch = _best_batch_of(brewery.inventory, required_style)
	var alcohol_free_batch: BrewBatch = _best_batch_of(brewery.inventory, alcohol_free_style)
	if light_batch == null or alcohol_free_batch == null:
		return false

	var payout: float = _payout(brewery, light_batch) + _payout(brewery, alcohol_free_batch)
	brewery.inventory.brew_batches.erase(light_batch)
	brewery.inventory.brew_batches.erase(alcohol_free_batch)
	brewery.change_money(snappedf(payout, 0.1), MoneyLedger.Source.EVENTS)
	_apply_rewards(brewery)
	if granted_perk != null:
		brewery.apply_perk(granted_perk)
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


## What the whole batch would bring shipped to the best bar, and in the pub, then the share between.
func _payout(brewery: Brewery, batch: BrewBatch) -> float:
	var breakdown: SaleBreakdown = brewery.resolver.get_price_breakdown(batch.beer_style)
	var export_payout: float = BatchDistributor.calculate_ship_payout(breakdown.raw_cost_per_bottle, batch.current_quality, batch.amount_bottles, export_price_multiplier) \
			* brewery.stats.multiplier(PerkStats.DISTRIBUTION_INCOME) * batch.get_aged_price_multiplier()
	return reward_between(export_payout, breakdown.price_per_bottle * batch.amount_bottles, pub_share, min_over_export)


## The batch of `style` on offer with the highest quality, then the most servings.
func _best_batch_of(inventory: Inventory, style: BeerStyle.Style) -> BrewBatch:
	var best: BrewBatch = null
	for batch: BrewBatch in inventory.brew_batches:
		if batch.beer_style.style != style or batch.held or batch.amount_bottles <= 0:
			continue
		if best == null or is_better(batch.current_quality, batch.amount_bottles, best.current_quality, best.amount_bottles):
			best = batch
	return best


func _servings_of(inventory: Inventory, style: BeerStyle.Style) -> int:
	var batch: BrewBatch = _best_batch_of(inventory, style)
	return batch.amount_bottles if batch != null else 0


func _style_name(style: BeerStyle.Style) -> String:
	return BeerStyle.get_style_string_from_style(style)
