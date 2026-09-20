class_name Brewer
extends RefCounted

## Turns the ingredients on the brewing table into a bottled batch.


## Share of the consumed ingredients returned on a successful refund roll.
## Perk levels raise the odds, not this amount.
const INGREDIENT_REFUND_FRACTION : float = 0.5


var brewery : Brewery


func _init(owner : Brewery) -> void:
	brewery = owner


func connect_signals() -> void:
	GUISignals.start_brewing.connect(start_brew)


func disconnect_signals() -> void:
	GUISignals.start_brewing.disconnect(start_brew)


## Bottling always costs something: part of the raw yield is lost
## (BOTTLE_LOSS_RATE) and every bottle needs a label. Shared with the dev
## console's batch cheats so both charge the same.
func apply_bottling_costs(raw_yield : int) -> Dictionary:
	var effective_yield : int = BrewResolver.get_effective_bottle_yield(raw_yield)
	var bottles_lost : int = raw_yield - effective_yield
	var label_cost : float = snappedf(raw_yield * BrewResolver.LABEL_ART_COST_PER_BOTTLE, 0.1)
	brewery.money -= label_cost

	return {
		"effective_yield": effective_yield,
		"bottles_lost": bottles_lost,
		"label_cost": label_cost,
	}


func start_brew() -> void:
	if brewery.brew_preparation.selected_contents.is_empty():
		print(StringContainer.TABLE_EMPTY_ERROR)
		return
	
	var brew_report : BrewResult = brewery.resolver.resolve_brew_style(brewery.brew_preparation.selected_contents)

	if brew_report == null:
		brewery.brew_preparation.clear_preparation()
		BrewerySignals.brewery_state_changed.emit(brewery)
		return

	# The yield perk multiplies the raw yield, before bottling loss.
	var raw_yield : int = roundi(brew_report.bottle_yield * brewery.stats.multiplier(PerkStats.BREW_YIELD))
	var bottling : Dictionary = apply_bottling_costs(raw_yield)
	var effective_yield : int = bottling.effective_yield
	var bottles_lost : int = bottling.bottles_lost
	var label_cost : float = bottling.label_cost

	var new_batch := BrewBatch.new()
	new_batch.beer_style = brew_report.beer_style
	new_batch.amount_bottles = effective_yield
	new_batch.original_quality = brew_report.original_quality + brewery.stats.total(PerkStats.QUALITY_BONUS)
	new_batch.current_quality = new_batch.original_quality
	new_batch.final_ebc = brew_report.final_ebc
	new_batch.final_ibu = brew_report.final_ibu
	new_batch.precision_score = brew_report.precision_score
	new_batch.hop_diversity_count = brew_report.hop_diversity_count
	new_batch.hop_balance_bonus = brew_report.hop_balance_bonus
	new_batch.flavor_matched = brew_report.flavor_matched
	new_batch.peak_days_multiplier = brewery.stats.multiplier(PerkStats.PEAK_SPEED)
	new_batch.decline_rate_multiplier = brewery.stats.multiplier(PerkStats.DECLINE_RATE)

	brewery.inventory.brew_batches.append(new_batch)

	if brew_report.is_matched:
		var is_new_discovery : bool = not brewery.discovered_styles.has(brew_report.beer_style.style)
		StyleDiscovery.new(brewery).discover_style(brew_report.beer_style.style)
		if is_new_discovery:
			RecipeBook.new(brewery).save_recipe(brew_report.beer_style, brewery.brew_preparation.selected_contents.duplicate())
		if brew_report.beer_style.style == BeerStyle.Style.KOTIKALJA:
			brewery.tutorial_brewed_kotikalja = true
		BrewerySignals.beer_brewed.emit(brew_report.beer_style.style)

		var brew_xp : int = Brewery.XP_PER_SUCCESSFUL_BREW
		if is_new_discovery:
			brew_xp += Brewery.XP_PER_NEW_STYLE_DISCOVERY_BONUS
		brewery.add_xp(brew_xp)
		BrewerySignals.brew_xp_gained.emit(brew_xp)

	_roll_ingredient_refund()
	brewery.brew_preparation.clear_preparation()
	print(StringContainer.SUCCESFULL_BREW_MESSAGE, BeerStyle.get_style_string_from_style(brew_report.beer_style.style))
	BrewerySignals.batch_bottled.emit(bottles_lost, label_cost, brew_report.beer_style.style_name)
	BrewerySignals.brewery_state_changed.emit(brewery)


## Must run before clear_preparation() empties the table it reads.
func _roll_ingredient_refund() -> void:
	var chance : float = brewery.stats.chance(PerkStats.INGREDIENT_REFUND_CHANCE)
	if chance <= 0.0 or randf() >= chance:
		return

	var refunded_any : bool = false
	for ingredient_id : int in brewery.brew_preparation.selected_contents:
		var used_amount : int = brewery.brew_preparation.selected_contents[ingredient_id]
		var refund_amount : int = roundi(used_amount * INGREDIENT_REFUND_FRACTION)
		if refund_amount <= 0:
			continue
		brewery.inventory.add_amount_by_id(ingredient_id, refund_amount)
		refunded_any = true

	if refunded_any:
		BrewerySignals.ingredients_refunded.emit()
