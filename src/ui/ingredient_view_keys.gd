class_name IngredientViewKeys
extends RefCounted

## Keyboard control for the shop and brewery views: step the ingredient, the amount and
## the ingredient type, and confirm. The views call handle() from _input(), before the
## GUI, so arrows, Tab and Enter never move focus or press a focused button.

const SHIFT_AMOUNT_STEP : float = 10.0


## Returns whether the event was used; the caller then marks it handled.
static func handle(event : InputEvent, view : Control, selector : IngredientTypeSelector, slider : Range, confirm : Callable) -> bool:
	if not event is InputEventKey or not event.is_pressed() or not view.is_visible_in_tree():
		return false
	# Typing in a text field (the console) keeps its arrows and Enter.
	if view.get_viewport().gui_get_focus_owner() is LineEdit:
		return false

	var shift : bool = (event as InputEventKey).shift_pressed
	if event.is_action_pressed(InputManager.ACTION_INGREDIENT_PREVIOUS, true):
		selector.step_ingredient(-1)
	elif event.is_action_pressed(InputManager.ACTION_INGREDIENT_NEXT, true):
		selector.step_ingredient(1)
	elif event.is_action_pressed(InputManager.ACTION_AMOUNT_UP, true):
		slider.value = SliderStepper.stepped(slider.value, amount_step(shift), slider.step, slider.min_value, slider.max_value)
	elif event.is_action_pressed(InputManager.ACTION_AMOUNT_DOWN, true):
		slider.value = SliderStepper.stepped(slider.value, -amount_step(shift), slider.step, slider.min_value, slider.max_value)
	elif event.is_action_pressed(InputManager.ACTION_INGREDIENT_TYPE):
		selector.step_type(-1 if shift else 1)
	elif event.is_action_pressed(InputManager.ACTION_INGREDIENT_CONFIRM):
		confirm.call()
	else:
		return false
	return true


static func amount_step(shift : bool) -> float:
	return SHIFT_AMOUNT_STEP if shift else 1.0
