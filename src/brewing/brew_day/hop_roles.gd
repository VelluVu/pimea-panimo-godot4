class_name HopRoles
extends RefCounted

## Gives each hop addition a recipe hop: the most bitter one bitters, the style's flavour
## takes the later marks, leftovers join the last. A hop on several marks splits its
## grams; a mark left with none is dropped.


## `table` maps ingredient id -> IngredientData. Returns the marks sorted by time, the
## dry hop marks included (they go in on their own in the fermentor).
static func assign(contents : Dictionary, table : Dictionary, kinds : Array[HopAddition.Kind], preferred_profiles : Array[HopData.FlavorProfile]) -> Array[BoilMark]:
	var hops : Array[HopData] = _hops_in(contents, table)
	var pairs : Array = []
	if not hops.is_empty():
		var bittering : bool = kinds.has(HopAddition.Kind.BITTERING)
		var late_kinds : Array[HopAddition.Kind] = []
		for kind : HopAddition.Kind in [HopAddition.Kind.FLAVOR, HopAddition.Kind.AROMA, HopAddition.Kind.DRY_HOP]:
			if kinds.has(kind):
				late_kinds.append(kind)
		# A style without hop marks still boils the hops someone put on the table.
		if not bittering and late_kinds.is_empty():
			bittering = true
		if bittering:
			pairs.append([HopAddition.Kind.BITTERING, hops[0]])
		var late_hops : Array[HopData] = hops.slice(1) if bittering and hops.size() > 1 else hops.duplicate()
		late_hops.sort_custom(func(a : HopData, b : HopData) -> bool:
			var a_preferred : bool = preferred_profiles.has(a.flavor_profile)
			var b_preferred : bool = preferred_profiles.has(b.flavor_profile)
			if a_preferred != b_preferred:
				return a_preferred
			return _more_bitter(a, b))
		for i : int in late_kinds.size():
			pairs.append([late_kinds[i], late_hops[i % late_hops.size()]])
		var last_kind : HopAddition.Kind = late_kinds.back() if not late_kinds.is_empty() else HopAddition.Kind.BITTERING
		for hop : HopData in hops:
			if not pairs.any(func(pair : Array) -> bool: return pair[1] == hop):
				var has_aroma : bool = hop.flavor_profile != HopData.FlavorProfile.NONE
				pairs.append([HopAddition.Kind.FLAVOR if late_kinds.is_empty() and has_aroma else last_kind, hop])

	var marks : Array[BoilMark] = _split_grams(pairs, contents)
	for id : int in contents:
		var data : IngredientData = table.get(id)
		if data != null and data.type == IngredientData.IngredientType.SPICE and int(contents[id]) > 0:
			marks.append(BoilMark.new(HopAddition.Kind.SPICE, id, int(contents[id])))
	marks.sort_custom(func(a : BoilMark, b : BoilMark) -> bool:
		if a.kind == HopAddition.Kind.DRY_HOP or b.kind == HopAddition.Kind.DRY_HOP:
			return b.kind == HopAddition.Kind.DRY_HOP and a.kind != HopAddition.Kind.DRY_HOP
		return a.time < b.time)
	return marks


## Flavour and aroma marks want a hop with an aroma of its own.
static func is_late_kind(kind : HopAddition.Kind) -> bool:
	return kind == HopAddition.Kind.FLAVOR or kind == HopAddition.Kind.AROMA


## Most bitter first; equal hops keep a stable order by id.
static func _hops_in(contents : Dictionary, table : Dictionary) -> Array[HopData]:
	var hops : Array[HopData] = []
	for id : int in contents:
		if table.get(id) is HopData and int(contents[id]) > 0:
			hops.append(table[id])
	hops.sort_custom(_more_bitter)
	return hops


static func _more_bitter(a : HopData, b : HopData) -> bool:
	return a.alpha_acids > b.alpha_acids or (a.alpha_acids == b.alpha_acids and a.id < b.id)


static func _split_grams(pairs : Array, contents : Dictionary) -> Array[BoilMark]:
	var uses : Dictionary = {}
	for pair : Array in pairs:
		var id : int = (pair[1] as HopData).id
		uses[id] = int(uses.get(id, 0)) + 1
	var handed_out : Dictionary = {}
	var marks : Array[BoilMark] = []
	for pair : Array in pairs:
		var id : int = (pair[1] as HopData).id
		var total : int = int(contents[id])
		var share : int = floori(float(total) / int(uses[id]))
		# The remainder goes a gram at a time to the hop's first marks.
		var earlier : int = int(handed_out.get(id, 0))
		if earlier < total % int(uses[id]):
			share += 1
		handed_out[id] = earlier + 1
		if share > 0:
			var mark := BoilMark.new(pair[0], id, share)
			mark.bittering_only = is_late_kind(pair[0]) and (pair[1] as HopData).flavor_profile == HopData.FlavorProfile.NONE
			marks.append(mark)
	return marks
