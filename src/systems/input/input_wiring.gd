class_name InputWiring
extends InputBindings

## This project's shortcuts and their Finnish wording: the one file to edit after copying
## the input system. The game's InputManager autoload extends this, so game code reads
## the action names as InputManager.ACTION_*.

const ACTION_CANCEL: StringName = &"menu_cancel"
const ACTION_OPEN_CONSOLE: StringName = &"open_console"
const ACTION_TOGGLE_BREWERY: StringName = &"toggle_brewery"
const ACTION_TOGGLE_SHOP: StringName = &"toggle_shop"
const ACTION_TOGGLE_WAREHOUSE: StringName = &"toggle_warehouse"
const ACTION_TOGGLE_RUN_EFFECTS: StringName = &"toggle_run_effects"
const ACTION_TOGGLE_RECEIPT_LOG: StringName = &"toggle_receipt_log"
const ACTION_TOGGLE_RECIPE_LIBRARY: StringName = &"toggle_recipe_library"
const ACTION_TOGGLE_BREWERY_BOOK: StringName = &"toggle_brewery_book"
const ACTION_TOGGLE_UPGRADES: StringName = &"toggle_upgrades"


func _init() -> void:
	cancel_action = ACTION_CANCEL
	# Console first: DevConsole reads it in its own _input(), so it is a direct action.
	rebindable_actions = [
		ACTION_OPEN_CONSOLE,
		ACTION_TOGGLE_BREWERY,
		ACTION_TOGGLE_SHOP,
		ACTION_TOGGLE_WAREHOUSE,
		ACTION_TOGGLE_RUN_EFFECTS,
		ACTION_TOGGLE_RECEIPT_LOG,
		ACTION_TOGGLE_RECIPE_LIBRARY,
		ACTION_TOGGLE_BREWERY_BOOK,
		ACTION_TOGGLE_UPGRADES,
	]
	direct_actions = [ACTION_OPEN_CONSOLE]
	default_keys = {
		ACTION_OPEN_CONSOLE: KEY_C,
		ACTION_TOGGLE_BREWERY: KEY_P,
		ACTION_TOGGLE_SHOP: KEY_K,
		ACTION_TOGGLE_WAREHOUSE: KEY_I,
		ACTION_TOGGLE_RUN_EFFECTS: KEY_T,
		ACTION_TOGGLE_RECEIPT_LOG: KEY_U,
		ACTION_TOGGLE_RECIPE_LIBRARY: KEY_R,
		ACTION_TOGGLE_BREWERY_BOOK: KEY_B,
		ACTION_TOGGLE_UPGRADES: KEY_L,
	}
	action_labels = {
		ACTION_OPEN_CONSOLE: "Konsoli",
		ACTION_TOGGLE_BREWERY: "Panimo",
		ACTION_TOGGLE_SHOP: "Kauppa",
		ACTION_TOGGLE_WAREHOUSE: "Varasto",
		ACTION_TOGGLE_RUN_EFFECTS: "Kauden vaikutukset",
		ACTION_TOGGLE_RECEIPT_LOG: "Kuittiloki",
		ACTION_TOGGLE_RECIPE_LIBRARY: "Reseptikirja",
		ACTION_TOGGLE_BREWERY_BOOK: "Panimokirja",
		ACTION_TOGGLE_UPGRADES: "Kellarin parannukset",
	}
	ui_text = {
		"hint": "Valitse toiminto ja paina uutta näppäintä. Esc peruu.",
		"press_key": "Paina näppäintä...",
		"key_in_use": "Näppäin on jo käytössä: %s",
		"reset": "Palauta oletukset",
	}
	save_path = "user://input_bindings.cfg"
