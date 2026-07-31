extends Node

signal add_ingredient_to_brew_preparation(ingredient_id : int, amount : int)
signal remove_ingredients_from_brew_preparation(ingredient_id : int, amount : int)

signal buy_ingredient(ingredient_id : int, amount : int)
signal sell_ingredient(ingredient_id : int, amount : int)

signal start_brewing()
