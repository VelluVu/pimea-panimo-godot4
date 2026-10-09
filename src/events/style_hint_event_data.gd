class_name StyleHintEventData
extends IngredientDonationEventData

## An old master trades a tip for malt and hint_cost: one undiscovered style he has not
## hinted yet, rolled per visit, shows its exact EBC and IBU in the recipe library from
## then on (Brewery.hinted_styles). Never offered once nothing is left to tell.

@export var hint_cost: int = 50
## Rolled by prepared() and saved with an open window.
@export var hinted_style: BeerStyle.Style = BeerStyle.Style.KOTIKALJA


func get_weight(brewery: Brewery) -> float:
	if brewery.money < hint_cost or untold_styles(brewery).is_empty():
		return 0.0
	return super(brewery)


func prepared(brewery: Brewery, bars: Array[BarContact]) -> SpecialEventData:
	var rolled: StyleHintEventData = super(brewery, bars)
	if rolled == self:
		rolled = duplicate()
	var untold: Array[BeerStyle.Style] = untold_styles(brewery)
	if not untold.is_empty():
		rolled.hinted_style = untold.pick_random()
	return rolled


## Undiscovered styles without a tip yet.
static func untold_styles(brewery: Brewery) -> Array[BeerStyle.Style]:
	var found: Array[BeerStyle.Style] = []
	for beer_style: BeerStyle in brewery.resolver.active_styles:
		if not brewery.is_style_known(beer_style.style) and not brewery.hinted_styles.has(beer_style.style):
			found.append(beer_style.style)
	return found


func money_on_success(brewery: Brewery) -> float:
	return super(brewery) - hint_cost


func try_fulfill(brewery: Brewery) -> bool:
	if brewery.money < hint_cost:
		return false
	if not super(brewery):
		return false
	brewery.hinted_styles[hinted_style] = true
	return true
