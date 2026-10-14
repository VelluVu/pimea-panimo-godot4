class_name BrewFormulas
extends RefCounted

## The brewing maths for one 20 L keg: colour by the Morey formula, gravity from the
## grist and ABV from the yeast's attenuation, so real recipes land on real numbers.
## See dev/docs/brewing_rework.md.

const BATCH_LITRES : float = 20.0
## Share of a malt's extract the mash gets out; sugar dissolves completely.
const MASH_EFFICIENCY : float = 0.72
## Gravity points per kg per litre of pure sugar (46 points per pound per gallon).
const SUGAR_POINTS_PER_KG_LITRE : float = 384.0
## ABV per gravity point fermented away.
const ABV_PER_POINT : float = 0.131
const POUNDS_PER_KG : float = 2.2046
const LITRES_PER_GALLON : float = 3.785


## A malt's colour units in the batch: pounds × degrees Lovibond per gallon.
static func malt_color_units(kg : float, ebc : float) -> float:
	var lovibond : float = (ebc * 0.508 + 0.76) / 1.3546
	return kg * POUNDS_PER_KG * lovibond / (BATCH_LITRES / LITRES_PER_GALLON)


## The beer's EBC from the summed colour units (Morey).
static func ebc_from_color_units(color_units : float) -> float:
	if color_units <= 0.0:
		return 0.0
	return 1.4922 * pow(color_units, 0.6859) * 1.97


## Gravity points `kg` of a malt (or sugar) adds to the batch.
static func gravity_points(kg : float, extract : float, is_sugar : bool) -> float:
	var efficiency : float = 1.0 if is_sugar else MASH_EFFICIENCY
	return kg * extract * SUGAR_POINTS_PER_KG_LITRE * efficiency / BATCH_LITRES


static func abv(points : float, attenuation_percent : float) -> float:
	return points * attenuation_percent / 100.0 * ABV_PER_POINT
