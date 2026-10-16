class_name DayEventData
extends Resource

## A day's secret roll, announced by DayEventManager from day 2 on. For part of the day
## (window_fraction_min/max) it biases group and solo walk-ins toward its featured
## customers, then reverts. Most days should land on the heavily weighted "nothing
## special" entry, so a named event still feels like something.


@export var event_name : String = ""
## Shown once via a held banner at day start (see GuiAnnouncer._on_day_event_announced()).
@export_multiline var announcement_text : String = "Tavallinen päivä kellarissa."
## Played with the banner. Null plays AudioBank's generic day event chime.
@export var announcement_sound : AudioStream = null

@export_group("Painotus")
## Relative odds against every other DayEventData in the pool — mirrors
## SpecialEventData.get_weight()'s role but as a flat value here (no
## brewery-state-conditional events exist for this yet, unlike
## RiskBribeEventData's dynamic weight).
@export var weight : float = 1.0

@export_group("Kohdistus")
## The group-visit event heavily favored while this day event's window is
## active — see CustomerSpawner._pick_group_event(). Left null
## for a "nothing special" entry, which simply never overrides the normal
## random group-event roll.
@export var featured_group_event : GroupVisitEventData = null
## CustomerData.title values (e.g. "Zgen") this event's solo walk-ins should
## skew toward — see CustomerRegistry.get_random_customer_data(). Empty for
## a "nothing special" entry.
@export var featured_customer_titles : Array[String] = []
## Chance a solo walk-in during the active window is rerolled to match
## featured_customer_titles instead of the normal pool — see
## CustomerRegistry.get_random_customer_data(). Irrelevant when
## featured_customer_titles is empty.
@export_range(0.0, 1.0) var solo_customer_bias_chance : float = 0.55
## Chance a group visit is featured_group_event instead of a random pick while the
## window is open. Under 1.0 so a themed day can still surprise.
@export_range(0.0, 1.0) var featured_group_event_chance : float = 0.75

@export_group("Ajoitus")
## The active window as a fraction of the day (TimeManager.get_day_progress()), rolled
## in this range so the same event varies. Keep it well under 1.0: it colours part of
## the day, not all of it.
@export_range(0.0, 1.0) var window_fraction_min : float = 0.3
@export_range(0.0, 1.0) var window_fraction_max : float = 0.5
## How long after day start the window begins, same fraction basis as
## above — so a themed rush doesn't always start literally at the doors
## opening.
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
## Only read for EffectType.INGREDIENT_LOSS — which ingredient bucket takes
## the hit.
@export var effect_ingredient_type : IngredientData.IngredientType = IngredientData.IngredientType.MALT
@export var effect_amount_min : int = 1
@export var effect_amount_max : int = 1
## Shown as its own stacked toast (BrewerySignals.day_event_effect_triggered)
## the instant the effect lands — %d is substituted with however much was
## actually lost (can be less than rolled if stock/batches run short). Left
## empty for EffectType.NONE.
@export_multiline var effect_toast_format : String = ""


## False for an event about customers none of whom can come yet (`available_titles`),
## so a harbour day never comes before the first sailor is unlocked.
func has_audience(available_titles : Array) -> bool:
	if featured_customer_titles.is_empty():
		return true
	return featured_customer_titles.any(func(title : String) -> bool: return available_titles.has(title))


func get_effect_amount() -> int:
	return randi_range(effect_amount_min, effect_amount_max)
