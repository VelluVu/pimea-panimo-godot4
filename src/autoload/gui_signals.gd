#class_name GuiSignals (autoload)
extends Node

@warning_ignore("unused_signal")
signal active_ingredient_changed(ingredient_id : int)

@warning_ignore("unused_signal")
signal add_ingredient_to_brew_preparation(ingredient_id : int, amount : int)
@warning_ignore("unused_signal")
signal remove_ingredients_from_brew_preparation(ingredient_id : int, amount : int)

@warning_ignore("unused_signal")
signal buy_ingredient(ingredient_id : int, amount : int)
@warning_ignore("unused_signal")
signal sell_ingredient(ingredient_id : int, amount : int)

@warning_ignore("unused_signal")
signal start_brewing()
