class_name Brewer
extends RefCounted

## Turns the ingredients on the brewing table into a bottled batch.


## Share of the consumed ingredients returned on a successful refund roll.
## Perk levels raise the odds, not this amount.
const INGREDIENT_REFUND_FRACTION : float = 0.5
const LOG_BREWED : String = "Successful brew batch: "
const LOG_NO_FREE_KEG : String = "No empty keg for a new batch."
const LOG_MASH_TUN_FULL : String = "The mash tun cannot hold this much malt."

var brewery : Brewery


func _init(owner : Brewery) -> void:
	brewery = owner


func connect_signals() -> void:
	GUISignals.start_brewing.connect(start_brew)
	GUISignals.brew_day_finished.connect(start_brew)


func disconnect_signals() -> void:
	GUISignals.start_brewing.disconnect(start_brew)
	GUISignals.brew_day_finished.disconnect(start_brew)


## Bottling always costs something: part of the raw yield is lost
## (BOTTLE_LOSS_RATE) and every bottle needs a label. Shared with the dev
## console's batch cheats so both charge the same.
func apply_bottling_costs(raw_yield : int) -> Dictionary:
	var effective_yield : int = StylePricing.get_effective_bottle_yield(raw_yield)
	var bottles_lost : int = raw_yield - effective_yield
	var label_cost : float = snappedf(raw_yield * StylePricing.LABEL_ART_COST_PER_BOTTLE, 0.1)
	brewery.change_money(-label_cost, MoneyLedger.Source.BREWING)

	return {
		"effective_yield": effective_yield,
		"bottles_lost": bottles_lost,
		"label_cost": label_cost,
	}


## `quality_multiplier` is what the brew day earned, see BrewDayRules.
func start_brew(quality_multiplier : float = BrewDayRules.NORMAL_MULTIPLIER) -> void:
	if brewery.brew_preparation.selected_contents.is_empty():
		print(StringContainer.TABLE_EMPTY_ERROR)
		return
	if not brewery.inventory.has_free_keg():
		print(LOG_NO_FREE_KEG)
		return
	
	var brew_report : BrewResult = brewery.resolver.resolve_brew_style(brewery.brew_preparation.selected_contents)

	# Not brewable yet: the ingredients stay on the table rather than being lost.
	if brew_report == null:
		return
	if not MashTun.holds(brew_report.malt_weight, brewery.mash_capacity_kg()):
		print(LOG_MASH_TUN_FULL)
		return

	# The yield perk multiplies the raw yield, before bottling loss.
	var raw_yield : int = roundi(brew_report.bottle_yield * brewery.stats.multiplier(PerkStats.BREW_YIELD))
	var bottling : Dictionary = apply_bottling_costs(raw_yield)
	var effective_yield : int = bottling.effective_yield
	var bottles_lost : int = bottling.bottles_lost
	var label_cost : float = bottling.label_cost

	var first_this_season : bool = brew_report.is_matched and not brewery.brewed_styles.has(brew_report.beer_style.style)
	var quality : float = snappedf((brew_report.original_quality + brewery.stats.total(PerkStats.QUALITY_BONUS)) * quality_multiplier, BrewResolver.QUALITY_PRECISION)
	var new_batch := BrewBatch.from_result(brew_report, effective_yield, quality)
	new_batch.novelty = first_this_season
	new_batch.peak_days_multiplier = brewery.stats.multiplier(PerkStats.PEAK_SPEED)
	new_batch.decline_rate_multiplier = brewery.stats.multiplier(PerkStats.DECLINE_RATE)
	BatchTraits.apply(new_batch, brewery.brew_preparation.selected_contents, brewery.resolver.ingredient_table())

	# A save from before fermentation has no has_brewed, but its batches show it brewed.
	var is_first_brew : bool = not brewery.has_brewed and brewery.inventory.brew_batches.is_empty()
	Fermenter.new(brewery).start(new_batch, FermentationRules.duration(is_first_brew))
	brewery.has_brewed = true

	_award_brew_reputation(brew_report, first_this_season)
	if brew_report.is_matched:
		_reward_matched_brew(brew_report, new_batch, first_this_season)

	_roll_ingredient_refund()
	brewery.brew_preparation.clear_preparation()
	print(LOG_BREWED, BeerStyle.get_style_string_from_style(brew_report.beer_style.style))
	BrewerySignals.batch_bottled.emit(bottles_lost, label_cost, brew_report.beer_style.style_name)
	BrewerySignals.brewery_state_changed.emit(brewery)


## Reputation comes only from a run's first brew of a style, so repeat brews cannot farm
## it, and a discovery never costs any; a failed brew costs its value every time.
func _award_brew_reputation(brew_report : BrewResult, first_this_season : bool) -> void:
	var brew_reputation : int = 0
	if not brew_report.is_matched:
		brew_reputation = brewery.change_reputation(brew_report.reputation_change, ReputationRules.Source.BREWING)
	elif first_this_season:
		brewery.brewed_styles[brew_report.beer_style.style] = true
		brew_reputation = brewery.change_reputation(maxi(0, brew_report.reputation_change), ReputationRules.Source.BREWING)
	if brew_reputation != 0:
		BrewerySignals.brew_reputation_gained.emit(brew_reputation)


## A brew that hit a style: discovery and its recipe, the tutorial step, signals and xp.
func _reward_matched_brew(brew_report : BrewResult, new_batch : BrewBatch, first_this_season : bool) -> void:
	var is_new_discovery : bool = not brewery.discovered_styles.has(brew_report.beer_style.style)
	StyleDiscovery.new(brewery).discover_style(brew_report.beer_style.style)
	if is_new_discovery:
		RecipeBook.new(brewery).save_recipe(brew_report.beer_style, brewery.brew_preparation.selected_contents.duplicate())
	if brew_report.beer_style.style == BeerStyle.Style.KOTIKALJA:
		brewery.tutorial_brewed_kotikalja = true
	BrewerySignals.beer_brewed.emit(brew_report.beer_style.style)
	BrewerySignals.batch_brewed.emit(new_batch)
	if brew_report.spice_bonus != 0.0:
		BrewerySignals.brew_spiced.emit(brew_report.beer_style.style_name, brew_report.spice_bonus)

	var brew_xp : int = Brewery.XP_PER_SUCCESSFUL_BREW
	if is_new_discovery:
		brew_xp += Brewery.XP_PER_NEW_STYLE_DISCOVERY_BONUS
	if first_this_season:
		brew_xp += FirstBrewRules.xp_bonus(brew_report.beer_style)
	brewery.add_xp(brew_xp)
	BrewerySignals.brew_xp_gained.emit(brew_xp)
	if first_this_season:
		BrewerySignals.season_first_brew.emit(brew_report.beer_style.style, brew_report.beer_style.style_name)


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
