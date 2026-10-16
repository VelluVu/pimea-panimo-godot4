class_name BrewDayLook
extends RefCounted

## How the brew day looks and sounds from the sessions' numbers: the liquid's colour and
## murk, the steam, the burner button's warmth, the boil loop and the sacks' pellets.

## Pellet colours: the bittering hops darkest, the aroma hops brightest, like potions.
const PELLET_COLORS : Dictionary = {
	HopAddition.Kind.BITTERING: Color(0.2, 0.45, 0.16),
	HopAddition.Kind.FLAVOR: Color(0.38, 0.7, 0.22),
	HopAddition.Kind.AROMA: Color(0.62, 0.95, 0.32),
	HopAddition.Kind.SPICE: Color(0.95, 0.56, 0.24),
}
const JUNIPER_COLOR : Color = Color(0.4, 0.42, 0.8)
## Wort is cloudier than the finished beer; the mash more than the boil.
const GRAIN_COLOR : Color = Color(0.45, 0.36, 0.24)
const MASH_CLOUD : float = 0.45
const BOIL_CLOUD : float = 0.25
## How much each liquid hides the paddle's blade (KettleView.murk): clear water, the
## blended mash, the boiling wort.
const WATER_MURK : float = 0.3
const MASH_MURK : float = 0.85
const BOIL_MURK : float = 0.6
## How far the pour alone takes the water toward the mash colour; blending does the rest.
const POUR_CLOUD : float = 0.3
## The heater button is cold this many degrees under the target and fully warm at it.
const WARM_SPAN : float = 15.0
## Steam: a faint haze over a hot mash, wisps as the wort nears the boil, thick
## steam at a rolling boil and thicker as the foam rises.
const MASH_STEAM : float = 0.12
const MASH_STEAM_FROM : float = 50.0
const MASH_STEAM_SPAN : float = 20.0
const NEAR_BOIL_STEAM : float = 0.3
const NEAR_BOIL_SPAN : float = 8.0
const BOIL_STEAM : float = 0.35
const FOAM_STEAM : float = 0.3
## The boil loop starts at this level and grows with the foam.
const BOIL_SOUND_BASE : float = 0.55


## A sack's pellets take the colour of its mark; juniper is its own blue.
static func pellet_color(mark : BoilMark) -> Color:
	if mark.ingredient_id == BrewDayLines.JUNIPER_ID:
		return JUNIPER_COLOR
	return PELLET_COLORS.get(mark.kind, PELLET_COLORS[HopAddition.Kind.FLAVOR])


## The ingredient's name without the "-humala" ending, as the sacks show it.
static func sack_name(ingredient_name : String) -> String:
	return UiText.of(ingredient_name).get_slice("-", 0)


static func mash_color(ebc : int) -> Color:
	return BeerColor.from_ebc(ebc).lerp(GRAIN_COLOR, MASH_CLOUD)


static func boil_color(ebc : int) -> Color:
	return BeerColor.from_ebc(ebc).lerp(GRAIN_COLOR, BOIL_CLOUD)


## How far the water has turned into mash: the pour clouds it to POUR_CLOUD
## (`poured` 0..1), then the blend (MashSession.blend) takes it the rest of the way.
static func mash_cloud(poured : float, blend : float, malts_added : bool) -> float:
	return lerpf(POUR_CLOUD, 1.0, blend) if malts_added else POUR_CLOUD * poured


static func mash_liquid(ebc : int, cloud : float) -> Color:
	return KettleView.WATER_COLOR.lerp(mash_color(ebc), cloud)


static func mash_murk(cloud : float) -> float:
	return lerpf(WATER_MURK, MASH_MURK, cloud)


static func warmth(temperature : float, target : float) -> float:
	return clampf((temperature - (target - WARM_SPAN)) / WARM_SPAN, 0.0, 1.0)


static func mash_steam(temperature : float) -> float:
	return MASH_STEAM * clampf((temperature - MASH_STEAM_FROM) / MASH_STEAM_SPAN, 0.0, 1.0)


static func boil_steam(temperature : float, boiling : bool, foam : float) -> float:
	if boiling:
		return BOIL_STEAM + FOAM_STEAM * clampf(foam, 0.0, 1.0)
	var near : float = (temperature - (BoilSession.BOIL_MIN - NEAR_BOIL_SPAN)) / NEAR_BOIL_SPAN
	return NEAR_BOIL_STEAM * clampf(near, 0.0, 1.0)


## The boil loop's level: silent until it boils, then louder as the foam rises.
static func boil_loop(boiling : bool, foam : float) -> float:
	if not boiling:
		return 0.0
	return BOIL_SOUND_BASE + (1.0 - BOIL_SOUND_BASE) * clampf(foam, 0.0, 1.0)
