class_name HopAddition
extends RefCounted

## When something goes into the kettle. Styles list their kinds (BeerStyle.hop_additions),
## BoilSchedule times them and HopRoles picks a hop for each.

enum Kind { BITTERING, FLAVOR, AROMA, SPICE, DRY_HOP }
