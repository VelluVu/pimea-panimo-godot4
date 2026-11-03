class_name BarTaps
extends RefCounted

## The bar's taps and kegs drawn from a brewery: a tap per keg owned, and a keg behind the
## counter and a coloured handle per batch on serve. The cellar and the main menu's copy of
## it share this.


## Returns the batches on the taps, left to right.
static func show(brewery : Brewery, tap_tower : TapTower, keg_row : KegRow) -> Array[BrewBatch]:
	var batches : Array[BrewBatch] = brewery.inventory.batches_on_serve().slice(0, TapLayout.MAX_TAPS)
	var colors : Array[Color] = []
	for batch : BrewBatch in batches:
		colors.append(BeerColor.from_ebc(batch.final_ebc))
	tap_tower.set_taps(brewery.inventory.total_kegs(), colors)
	keg_row.show_kegs(batches)
	return batches
