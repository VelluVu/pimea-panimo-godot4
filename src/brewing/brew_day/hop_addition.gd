class_name HopAddition
extends RefCounted

## When something goes into the brew day's kettle. A style lists its hop kinds as data
## (BeerStyle.hop_additions); BoilSchedule times them and HopRoles picks the recipe's
## hop for each. Spices get a SPICE mark whenever the recipe has any.

enum Kind { BITTERING, FLAVOR, AROMA, SPICE, DRY_HOP }
