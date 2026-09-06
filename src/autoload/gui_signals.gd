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

@warning_ignore("unused_signal")
signal warehouse_hovered(is_hovered : bool)

@warning_ignore("unused_signal")
signal brewery_view_requested()

@warning_ignore("unused_signal")
signal brewery_view_closed()

@warning_ignore("unused_signal")
signal mouse_entered_brewery_hover_area(is_entered : bool)

@warning_ignore("unused_signal")
signal mouse_entered_shop_hover_area(is_entered : bool)