#class_name GuiSignals (autoload)
extends Node

signal active_ingredient_changed(ingredient_id : int)

signal add_ingredient_to_brew_preparation(ingredient_id : int, amount : int)
signal remove_ingredients_from_brew_preparation(ingredient_id : int, amount : int)

signal buy_ingredient(ingredient_id : int, amount : int)
signal sell_ingredient(ingredient_id : int, amount : int)

signal start_brewing()
