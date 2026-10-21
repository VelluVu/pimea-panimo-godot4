class_name TipsyRules
extends RefCounted

## How much a customer sways on the way out after buying: servings times the strongest
## ABV, in whole art pixels, so the sway stays on the pixel grid.

## Servings times ABV (%) for each sway step: two 5 % beers sway one pixel, four two.
const UNITS_PER_STEP : float = 10.0
const MAX_STEPS : int = 2
const SWAY_HZ : float = 0.9


static func sway_steps(servings : int, strongest_abv : float) -> int:
	return clampi(floori(servings * strongest_abv / UNITS_PER_STEP), 0, MAX_STEPS)


## The sideways offset in art pixels at `seconds` into the walk.
static func sway_offset(seconds : float, steps : int) -> int:
	return roundi(sin(seconds * TAU * SWAY_HZ) * steps)
