#class_name BrewerySignals (Autoload)
extends Node

@warning_ignore("unused_signal")
signal brewery_state_changed(brewery: Brewery)
@warning_ignore("unused_signal")
signal dialogue_pushed(text: String, is_special: bool, slot_index: int, character_global_pos: Vector2)