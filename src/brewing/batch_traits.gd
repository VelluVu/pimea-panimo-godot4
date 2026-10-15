class_name BatchTraits
extends RefCounted

## What went into a batch, kept on it so customers can ask for spiced, hoppy or malty
## beer whatever the style (see TasteRule).

const LATE_HOP_KINDS : Array[HopAddition.Kind] = [HopAddition.Kind.AROMA, HopAddition.Kind.DRY_HOP]


## `contents` maps ingredient id -> amount, `table` id -> IngredientData.
static func apply(batch : BrewBatch, contents : Dictionary, table : Dictionary) -> void:
	batch.spiced = has_spices(contents, table)
	batch.malt_ids = malt_ids(contents, table)
	batch.late_hop_profiles = late_hop_profiles(batch.beer_style, contents, table)


static func has_spices(contents : Dictionary, table : Dictionary) -> bool:
	for id : int in contents:
		var data : IngredientData = table.get(id)
		if data != null and data.type == IngredientData.IngredientType.SPICE and int(contents[id]) > 0:
			return true
	return false


static func malt_ids(contents : Dictionary, table : Dictionary) -> Array[int]:
	var ids : Array[int] = []
	for id : int in contents:
		var data : IngredientData = table.get(id)
		if data != null and data.type == IngredientData.IngredientType.MALT and int(contents[id]) > 0:
			ids.append(id)
	ids.sort()
	return ids


## The flavours of the hops that go in as aroma or dry hops, as the brew day assigns
## them. A hop with no aroma of its own (Magnum) adds nothing.
static func late_hop_profiles(style : BeerStyle, contents : Dictionary, table : Dictionary) -> Array[HopData.FlavorProfile]:
	var profiles : Array[HopData.FlavorProfile] = []
	if style == null:
		return profiles
	for mark : BoilMark in HopRoles.assign(contents, table, style.hop_additions, style.preferred_hop_profiles):
		if not LATE_HOP_KINDS.has(mark.kind) or mark.grams <= 0:
			continue
		var hop : HopData = table.get(mark.ingredient_id) as HopData
		if hop != null and hop.flavor_profile != HopData.FlavorProfile.NONE and not profiles.has(hop.flavor_profile):
			profiles.append(hop.flavor_profile)
	return profiles
