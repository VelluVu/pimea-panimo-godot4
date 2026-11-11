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
## The only season the event can come in, by the player's clock; NONE for all year.
@export var season : SeasonRules.Season = SeasonRules.Season.NONE
## Set for a morning after: the event comes only the day after this one (Krapulapäivä
## after Uudenvuodenaatto), and then at its weight. Null for any day.
@export var only_after_event : DayEventData = null
## Comes at most once in a run (Musta perjantai is one day, however long the season is).
@export var once_per_run : bool = false

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


## Every customer who walks in that day wears a party hat (PartyHat), unless their own
## headgear stays on (CustomerData.wears_party_hat).
@export var party_hats : bool = false

## Holds for the event's whole day, not just the bias window (Brewery.set_day_perk).
@export var day_perk : RunPerk = null


func can_come_in(current : SeasonRules.Season) -> bool:
	return season == SeasonRules.Season.NONE or SeasonRules.includes(current, season)


## True when yesterday's event (`previous`, null for a plain day or a new run) lets this
## one come: always, unless it only follows another event.
func can_follow(previous : DayEventData) -> bool:
	if only_after_event == null:
		return true
	return previous != null and previous.resource_path == only_after_event.resource_path


## What Brewery.seen_once_events remembers this event by.
func id() -> String:
	return resource_path.get_file().get_basename()


## The odds of rolling this event today; 0 when it cannot come. `seen_once` is the run's
## Brewery.seen_once_events.
func weight_for(current : SeasonRules.Season, available_titles : Array, previous : DayEventData, seen_once : Array[String] = []) -> float:
	if not has_audience(available_titles) or not can_come_in(current) or not can_follow(previous):
		return 0.0
	if once_per_run and seen_once.has(id()):
		return 0.0
	return weight


func get_effect_amount() -> int:
	return randi_range(effect_amount_min, effect_amount_max)
