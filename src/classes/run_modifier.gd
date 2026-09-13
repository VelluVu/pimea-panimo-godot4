class_name RunModifier
extends Resource

## Rolled once per run in Brewery._init() (see Brewery.run_modifier) and
## read at the handful of call sites that touch AVI raids and ingredient
## pricing — never mutates shared IngredientData/Brewery constants in
## place, since those are reused across runs.

@export var modifier_name: String = ""
@export var description: String = ""

## Multiplies Brewery.AVI_RAID_THRESHOLD — see Brewery.get_effective_raid_threshold().
## Below 1.0 means raids trigger sooner (more dangerous); above 1.0 means later.
@export var avi_threshold_multiplier: float = 1.0

## Multiplies IngredientData.base_price wherever it's read for a real
## transaction or cost preview (Brewery._on_buy_ingredient/_on_sell_ingredient,
## BrewResolver's cost-preview functions). Since beer sale prices are fixed
## per style (BeerStyle.fixed_price_per_bottle), a higher multiplier directly
## squeezes profit margin rather than just being flavor text.
@export var ingredient_price_multiplier: float = 1.0
