class_name AdoptionEventData
extends PerkOfferEventData

## A stray cat: pay offer_cost to keep it, once a season. It brings its perk and walks
## through the cellar now and then (ImmersionVignetteData.needs_cellar_cat).


func get_weight(brewery: Brewery) -> float:
	return 0.0 if brewery.cellar_cat_adopted else super(brewery)


func try_fulfill(brewery: Brewery) -> bool:
	if not super(brewery):
		return false
	brewery.cellar_cat_adopted = true
	return true
