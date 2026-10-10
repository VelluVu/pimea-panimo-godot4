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


## The intro takes the amount and the malt in the partitive (%d, %s): "5 kiloa savumallasta",
## and his fee as {cost}.
func intro_text() -> String:
	var ingredient: IngredientData = IngredientDatabase.get_item_by_id(required_ingredient_id)
	var malt: String = ""
	if ingredient != null:
		malt = UiText.of(ingredient.name_partitive if not ingredient.name_partitive.is_empty() else ingredient.name)
	return (tr(intro_dialogue) % [required_ingredient_amount, malt]).format(intro_values())


func intro_values() -> Dictionary:
	var values: Dictionary = super()
	values["cost"] = hint_cost
	return values


## Waits for the money as well as the malt: buying the malt can leave too little for him.
func can_fulfill(brewery: Brewery) -> bool:
	return brewery.money >= hint_cost and super(brewery)


func money_on_success(brewery: Brewery) -> float:
	return super(brewery) - hint_cost


func try_fulfill(brewery: Brewery) -> bool:
	if brewery.money < hint_cost:
		return false
	if not super(brewery):
		return false
	brewery.hinted_styles[hinted_style] = true
	return true
