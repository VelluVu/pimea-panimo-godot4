class_name BrewRecipe
extends Resource


@export var recipe_name: String = ""
@export var beer_style: BeerStyle.Style = BeerStyle.Style.KOTIKALJA
@export var ingredient_amounts: Dictionary = {} # Avain: int (Ingredient ID) -> Arvo: int (Määrä)
@export var is_default: bool = false
