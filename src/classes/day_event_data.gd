class_name DayEventData
extends Resource

## A day-level flavor roll: DayEventManager picks one of these in secret at
## the start of every day (from day 2 onward — day 1 already has its own
## first-brew tutorial banner and shouldn't compete with it) and announces
## announcement_text so the player knows what to expect, without ever
## showing the roll itself. For its active window (a fraction of the day,
## not the whole day — see window_fraction_min/max) it biases both the
## group-visit roll and the solo walk-in roll toward featured_group_event/
## featured_customer_titles, then quietly reverts to normal. Most days
## should land on a low-key "nothing special" entry (see day_event_none.tres)
## with a much higher weight than the named events, so a named event
## actually landing still feels like something.


@export var event_name : String = ""
## Shown once via a held banner at day start (see GUI._on_day_event_announced()).
@export_multiline var announcement_text : String = "Tavallinen päivä kellarissa."

@export_group("Painotus")
## Relative odds against every other DayEventData in the pool — mirrors
## SpecialEventData.get_weight()'s role but as a flat value here (no
## brewery-state-conditional events exist for this yet, unlike
## RiskBribeEventData's dynamic weight).
@export var weight : float = 1.0

@export_group("Kohdistus")
## The group-visit event heavily favored while this day event's window is
## active — see CustomerSpawner._on_group_event_timer_timeout(). Left null
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
## Chance the group-visit timer's roll uses featured_group_event instead of
## the normal random pool pick, while the window is active — see
## CustomerSpawner._on_group_event_timer_timeout(). Not 1.0: even a themed
## day should occasionally surprise the player with an unrelated group
## instead of reading as 100% on-rails.
@export_range(0.0, 1.0) var featured_group_event_chance : float = 0.75

@export_group("Ajoitus")
## The event's active window, as a fraction of TimeManager.day_duration_seconds
## (there's no literal in-game "hour" — the day clock is just a 0-1
## progress fraction, see TimeManager.get_day_progress()) — randomized
## within this per-event range so two days with the same event don't
## always feel identical. Deliberately well under 1.0: this should color
## part of the day, not take it over (see this class's own docstring).
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


## A same-day misfortune (stock eaten, bottles spoiled) instead of a themed
## rush of customers — fires once, immediately when this event is rolled
## (see DayEventManager._apply_direct_effect()), entirely separate from the
## featured_group_event/featured_customer_titles bias window above. NONE for
## every existing themed/customer-bias event; only the "unfortunate" pool
## entries set this.
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


func get_effect_amount() -> int:
	return randi_range(effect_amount_min, effect_amount_max)
