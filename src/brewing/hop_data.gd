class_name HopData
extends IngredientData


enum FlavorProfile { NONE, CITRUS, TROPICAL, PINE, NOBLE, EARTHY }
## What the hop is good for. Flavour and aroma marks score the same for any hop with an
## aroma (HopRoles), so there is no separate flavour use. A mild noble hop also bitters
## the noble-hop styles (BrewQuality.is_good_bittering_hop).
enum Use { BITTERING, AROMA, DUAL, NOBLE }

## From this much alpha up an aroma hop bitters well too, as real dual-purpose hops do.
const DUAL_ALPHA_MIN : int = 8
const USE_FORMAT : String = "Käyttö: %s"
const USE_FLAVOR_FORMAT : String = "Käyttö: %s / Maku: %s"
const USE_BITTERING : String = "Katkeroiva"
const USE_AROMA : String = "Aromi"
const USE_DUAL : String = "Katkeroiva ja aromi"
const USE_NOBLE : String = "Aromi, katkeroi perinteisiä oluita"

## Hops go by 10 g: a low-alpha hop can bitter where 10 g of Magnum would overshoot,
## so every style can still be hit, with far fewer amounts to choose from.
const GRAM_STEP : int = 10

@export var alpha_acids : int
@export var beta_acids : int
@export var flavor_profile : FlavorProfile = FlavorProfile.NONE


func amount_step() -> int:
	return GRAM_STEP


func get_stat_string() -> String:
	var base_stats := tr(StringContainer.HOP_STAT_STRING) % [alpha_acids, beta_acids]
	var use_name : String = get_use_display_name(use_of(alpha_acids, flavor_profile))
	if flavor_profile == FlavorProfile.NONE:
		return base_stats + "\n" + tr(USE_FORMAT) % use_name
	return base_stats + "\n" + tr(USE_FLAVOR_FORMAT) % [use_name, get_flavor_profile_display_name(flavor_profile)]


static func use_of(alpha : int, profile : FlavorProfile) -> Use:
	if profile == FlavorProfile.NONE:
		return Use.BITTERING
	if alpha >= DUAL_ALPHA_MIN:
		return Use.DUAL
	return Use.NOBLE if profile == FlavorProfile.NOBLE else Use.AROMA


static func get_use_display_name(use : Use) -> String:
	match use:
		Use.BITTERING: return UiText.of(USE_BITTERING)
		Use.AROMA: return UiText.of(USE_AROMA)
		Use.NOBLE: return UiText.of(USE_NOBLE)
		_: return UiText.of(USE_DUAL)


static func get_flavor_profile_display_name(profile: FlavorProfile) -> String:
	match profile:
		FlavorProfile.CITRUS: return UiText.of(StringContainer.HOP_FLAVOR_CITRUS)
		FlavorProfile.TROPICAL: return UiText.of(StringContainer.HOP_FLAVOR_TROPICAL)
		FlavorProfile.PINE: return UiText.of(StringContainer.HOP_FLAVOR_PINE)
		FlavorProfile.NOBLE: return UiText.of(StringContainer.HOP_FLAVOR_NOBLE)
		FlavorProfile.EARTHY: return UiText.of(StringContainer.HOP_FLAVOR_EARTHY)
		_: return ""
