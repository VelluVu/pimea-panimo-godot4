class_name MashTun
extends RefCounted

## How much malt the cellar's mash tun holds. The keg is always 20 L, so a bigger tun is
## what makes a stronger beer possible; the "Parempi Mäskipata" upgrade adds to it.

const BASE_CAPACITY_KG : float = 6.0


static func capacity_kg(extra_kg : int) -> float:
	return BASE_CAPACITY_KG + extra_kg


## A small margin, so 10 × 100 g packs count as the kilogram they are.
static func holds(malt_kg : float, capacity : float) -> bool:
	return malt_kg <= capacity + 0.001
