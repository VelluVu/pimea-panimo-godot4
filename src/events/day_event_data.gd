class_name DayEventData
extends Resource

## A day's secret roll, announced from day 2 on. For part of the day it biases walk-ins and
## groups toward its featured customers. Most days roll the heavily weighted "nothing
## special", so a named event feels like something.


@export var event_name : String = ""
## Shown once on a held banner at day start.
@export_multiline var announcement_text : String = "Tavallinen päivä kellarissa."
## Played with the banner. Null plays AudioBank's generic day event chime.
@export var announcement_sound : AudioStream = null

@export_group("Painotus")
## Relative odds against every other day event.
@export var weight : float = 1.0

@export_group("Kohdistus")
## The group visit favoured while the window is open; null for "nothing special".
@export var featured_group_event : GroupVisitEventData = null
## CustomerData.titles the solo walk-ins lean toward; empty for "nothing special".
@export var featured_customer_titles : Array[String] = []
## Chance a solo walk-in in the window is rerolled toward featured_customer_titles.
@export_range(0.0, 1.0) var solo_customer_bias_chance : float = 0.55
## Chance a group visit is featured_group_event instead of a random pick while the
## window is open. Under 1.0 so a themed day can still surprise.
@export_range(0.0, 1.0) var featured_group_event_chance : float = 0.75

@export_group("Ajoitus")
## The window's length as a share of the day, rolled in this range. Keep it well under 1.0:
## it colours part of the day.
@export_range(0.0, 1.0) var window_fraction_min : float = 0.3
@export_range(0.0, 1.0) var window_fraction_max : float = 0.5
## How far into the day the window starts, so a rush does not always begin at opening.
@export_range(0.0, 1.0) var start_delay_fraction_min : float = 0.0
@export_range(0.0, 1.0) var start_delay_fraction_max : float = 0.25


func get_window_fraction() -> float:
	return randf_range(window_fraction_min, window_fraction_max)


func get_start_delay_fraction() -> float:
	return randf_range(start_delay_fraction_min, start_delay_fraction_max)


## A one-off misfortune (stock eaten, servings spoiled) fired when the event is rolled
## (DayEventEffects), apart from the bias window. Only the unfortunate pool sets it.
enum EffectType { NONE, INGREDIENT_LOSS, BOTTLE_SPOILAGE }

@export_group("Suora vaikutus")
@export var effect_type : EffectType = EffectType.NONE
## Only for INGREDIENT_LOSS: which ingredient type takes the hit.
@export var effect_ingredient_type : IngredientData.IngredientType = IngredientData.IngredientType.MALT
@export var effect_amount_min : int = 1
@export var effect_amount_max : int = 1
## Shown as its own toast when the effect lands; %d is what was really lost. Empty for NONE.
@export_multiline var effect_toast_format : String = ""


## False for an event about customers none of whom can come yet (`available_titles`),
## so a harbour day never comes before the first sailor is unlocked.
func has_audience(available_titles : Array) -> bool:
	if featured_customer_titles.is_empty():
		return true
	return featured_customer_titles.any(func(title : String) -> bool: return available_titles.has(title))


func get_effect_amount() -> int:
	return randi_range(effect_amount_min, effect_amount_max)
