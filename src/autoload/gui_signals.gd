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
signal ship_batch_to_bar_requested(batch : BrewBatch, bar : BarContact)
## Keeps a batch in the cellar (customers skip it) or releases it, see BrewBatch.held.
@warning_ignore("unused_signal")
signal batch_hold_toggled(batch : BrewBatch)

## A keg wash is done: washes the dirtiest empty keg to `cleanliness` (0 to 1).
@warning_ignore("unused_signal")
signal keg_wash_finished(cleanliness : float)

## Brews the table at once at BrewDayRules.NORMAL_MULTIPLIER (bots, the console).
@warning_ignore("unused_signal")
signal start_brewing()
## The player's Brew button: opens the brew day minigame for the table.
@warning_ignore("unused_signal")
signal brew_day_requested()
## The brew day is over; brews the table with the quality multiplier it earned.
@warning_ignore("unused_signal")
signal brew_day_finished(quality_multiplier : float)
## The brew day window opened or closed; level-up cards wait while it is open.
@warning_ignore("unused_signal")
signal brew_day_opened()
@warning_ignore("unused_signal")
signal brew_day_closed()
## A one-shot brew day sound, named by a BrewDaySound constant.
@warning_ignore("unused_signal")
signal brew_day_sound(sound : StringName)
## The brew day's looping sounds, every frame while it is open: burner power and boil
## strength 0..1, and whether a hop sack is pouring.
@warning_ignore("unused_signal")
signal brew_day_loops(burner : float, boil : float, pouring : bool)

@warning_ignore("unused_signal")
signal warehouse_door_clicked()

## A short line that drifts up from a place in the cellar (its bottom centre at
## world_position), shown by DialogView above the world's darkness.
@warning_ignore("unused_signal")
signal world_popup_requested(text: String, color: Color, world_position: Vector2)

@warning_ignore("unused_signal")
signal brewery_view_requested()

@warning_ignore("unused_signal")
signal brewery_view_closed()

@warning_ignore("unused_signal")
signal warehouse_view_opened()

@warning_ignore("unused_signal")
signal warehouse_view_closed()

@warning_ignore("unused_signal")
signal bar_view_exited()

@warning_ignore("unused_signal")
signal bar_view_entered()

@warning_ignore("unused_signal")
signal mouse_entered_brewery_hover_area(is_entered : bool)

@warning_ignore("unused_signal")
signal mouse_entered_shop_hover_area(is_entered : bool)

@warning_ignore("unused_signal")
signal mouse_entered_recipe_shelf_hover_area(is_entered : bool)

@warning_ignore("unused_signal")
signal mouse_entered_receipt_machine_hover_area(is_entered : bool)

@warning_ignore("unused_signal")
signal mouse_entered_chalkboard_hover_area(is_entered : bool)

@warning_ignore("unused_signal")
signal mouse_entered_warehouse_hover_area(is_entered : bool)

@warning_ignore("unused_signal")
signal mouse_entered_customer_book_hover_area(is_entered : bool)

## `count` is how many unwashed kegs the pile holds, for its label.
@warning_ignore("unused_signal")
signal mouse_entered_dirty_keg_pile(is_entered : bool, count : int)
## The dirty keg pile was clicked: opens the keg wash.
@warning_ignore("unused_signal")
signal keg_wash_requested()
## The keg wash window opened or closed; level-up cards wait while it is open.
@warning_ignore("unused_signal")
signal keg_wash_opened()
@warning_ignore("unused_signal")
signal keg_wash_closed()
## A one-shot keg wash sound, named by KegWashWindow.SOUND_*.
@warning_ignore("unused_signal")
signal keg_wash_sound(sound : StringName)

## Touch screens have no hover: every hotspot's name label shows (true) or hides (false)
## at once, without the hover glow. See TouchHints.
@warning_ignore("unused_signal")
signal touch_hints_shown(is_shown : bool)

@warning_ignore("unused_signal")
signal recipe_library_requested()

@warning_ignore("unused_signal")
signal receipt_log_requested()

@warning_ignore("unused_signal")
signal customer_book_requested()

@warning_ignore("unused_signal")
signal run_effects_requested()

@warning_ignore("unused_signal")
signal game_menu_requested()

@warning_ignore("unused_signal")
signal game_menu_closed()

@warning_ignore("unused_signal")
signal options_requested()

@warning_ignore("unused_signal")
signal options_closed()

@warning_ignore("unused_signal")
signal leaderboard_requested()

@warning_ignore("unused_signal")
signal leaderboard_closed()

@warning_ignore("unused_signal")
signal achievements_requested()

@warning_ignore("unused_signal")
signal achievements_closed()

@warning_ignore("unused_signal")
signal olutoppi_requested()

@warning_ignore("unused_signal")
signal olutoppi_closed()

@warning_ignore("unused_signal")
signal menu_button_pressed()

## A window without its own *_closed signal was closed, so the click sound can play.
@warning_ignore("unused_signal")
signal window_closed()

## A settings or view tab was switched, for the click sound.
@warning_ignore("unused_signal")
signal tab_switched()

## A toast appeared, for its sound.
@warning_ignore("unused_signal")
signal toast_shown()

## The day event banner appeared (it waits for the day recap window), for its sound.
@warning_ignore("unused_signal")
signal day_event_banner_shown(event: DayEventData)

@warning_ignore("unused_signal")
signal close_day_requested()

@warning_ignore("unused_signal")
signal clear_brew_preparation_requested()

@warning_ignore("unused_signal")
signal save_recipe_requested()
@warning_ignore("unused_signal")
signal load_recipe_requested(recipe : BrewRecipe)
@warning_ignore("unused_signal")
signal fill_recipe_from_inventory_requested()
## The shop's "buy what's missing": everything the loaded recipe needs beyond the table
## and the warehouse, bought at once or not at all.
@warning_ignore("unused_signal")
signal buy_missing_for_recipe_requested()

@warning_ignore("unused_signal")
signal cellar_upgrades_requested()
## The player asked to buy the next level of the upgrade with this upgrade_id.
@warning_ignore("unused_signal")
signal cellar_upgrade_requested(upgrade_id : String)
## The player flipped the on/off switch of an owned machine, see CellarMachines.
@warning_ignore("unused_signal")
signal machine_switch_requested(upgrade_id : String)
