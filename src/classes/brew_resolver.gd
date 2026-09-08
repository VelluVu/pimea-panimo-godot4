class_name BrewResolver
extends Resource


var active_styles: Array[BeerStyle] = []


func _ready() -> void:
	_load_all_beer_styles()


func _load_all_beer_styles() -> void:
	var path = StringContainer.PATH_TO_BREW_STYLES
	
	if not DirAccess.dir_exists_absolute(path):
		DirAccess.make_dir_absolute(path)
		print(StringContainer.CREATED_MISSING_BEER_STYLES_FOLDER, path)
		return
	
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir() and (file_name.ends_with(StringContainer.RESOURCE_END) or file_name.ends_with(StringContainer.REMAP_END)):
				var clean_path = path + file_name.replace(StringContainer.REMAP_END, "")
				var style_resource = load(clean_path)
				
				if style_resource is BeerStyle:
					active_styles.append(style_resource)
					
			file_name = dir.get_next()
		dir.list_dir_end()
		print(StringContainer.LOADED_BEER_STYLES_MESSAGE % str(active_styles.size()))
		for current_style in active_styles:
			print(current_style.get_style_string())


func resolve_brew_style(prep_contents : Dictionary) -> BrewResult:
	var total_malt_weight: int = 0
	var weighted_ebc_sum: float = 0
	var total_hop_amount: int = 0
	var total_alpha_acids: float = 0
	var total_beta_acids: float = 0
	var yeast_type: int = -1
	var distinct_hop_ids: Dictionary = {}
	var hop_profiles_used: Dictionary = {}

	for id in prep_contents.keys():
		var amount: int = prep_contents[id]
		var data: IngredientData = IngredientDatabase.database[id]

		match data.type:
			IngredientData.IngredientType.MALT:
				total_malt_weight += amount
				weighted_ebc_sum += data.ebc * amount
			IngredientData.IngredientType.HOP:
				total_hop_amount += amount
				total_alpha_acids += (data.alpha_acids * amount)
				total_beta_acids += (data.beta_acids * amount)
				if amount > 0:
					distinct_hop_ids[id] = true
					hop_profiles_used[data.flavor_profile] = true
			IngredientData.IngredientType.YEAST:
				yeast_type = id

	if total_malt_weight < 3 or yeast_type == -1:
		print(StringContainer.NOT_ENOUGH_INGREDIENTS_ERROR)
		return null

	var final_ebc = roundi(weighted_ebc_sum / total_malt_weight)
	var final_ibu = 0
	if total_hop_amount > 0:
		final_ibu = roundi(total_alpha_acids / 10)

	for beer_style in active_styles:
		if yeast_type != beer_style.required_yeast_id:
			continue
		if total_malt_weight < beer_style.min_malt_weight:
			continue
		if final_ebc < beer_style.min_ebc or final_ebc > beer_style.max_ebc:
			continue
		if final_ibu < beer_style.min_ibu or final_ibu > beer_style.max_ibu:
			continue

		var ebc_precision := _range_precision(final_ebc, beer_style.min_ebc, beer_style.max_ebc)
		var ibu_precision := _range_precision(final_ibu, beer_style.min_ibu, beer_style.max_ibu)
		var precision_score := (ebc_precision + ibu_precision) / 2.0

		var distinct_hop_bonus := clampf((distinct_hop_ids.size() - 1) * 0.05, 0.0, 0.15)

		var hop_balance_bonus := 0.0
		if total_alpha_acids > 0.0 and total_beta_acids > 0.0:
			hop_balance_bonus = (min(total_alpha_acids, total_beta_acids) / max(total_alpha_acids, total_beta_acids)) * 0.1

		var flavor_matched := beer_style.preferred_hop_profile != HopData.FlavorProfile.NONE and hop_profiles_used.has(beer_style.preferred_hop_profile)
		var flavor_match_bonus := 0.1 if flavor_matched else 0.0

		var quality_multiplier := 1.0 + (precision_score - 0.5) * 0.4 + distinct_hop_bonus + hop_balance_bonus + flavor_match_bonus
		quality_multiplier = clampf(quality_multiplier, 0.5, 1.5)

		var result := BrewResult.new()
		result.beer_style = beer_style
		result.final_ebc = final_ebc
		result.final_ibu = final_ibu
		result.original_quality = snappedf(beer_style.original_quality * quality_multiplier, 0.01)
		result.risk_change = beer_style.risk_change
		result.reputation_change = beer_style.reputation_change
		result.is_matched = true
		result.precision_score = precision_score
		result.hop_diversity_count = distinct_hop_ids.size()
		result.hop_balance_bonus = hop_balance_bonus
		result.flavor_matched = flavor_matched
		return result

	var failed_result := BrewResult.new()
	failed_result.beer_style = get_beer_style(BeerStyle.Style.KOTIKALJA)
	failed_result.final_ebc = final_ebc
	failed_result.final_ibu = final_ibu
	failed_result.original_quality = 1.0
	failed_result.risk_change = 2
	failed_result.reputation_change = -1
	failed_result.is_matched = false

	return failed_result


func _range_precision(value: float, min_v: float, max_v: float) -> float:
	if max_v <= min_v:
		return 1.0

	var center := (min_v + max_v) / 2.0
	var half_range := (max_v - min_v) / 2.0
	var distance := absf(value - center)

	return clampf(1.0 - (distance / half_range), 0.0, 1.0)


func get_beer_style(style : BeerStyle.Style) -> BeerStyle:
	for beer_Style in active_styles:
		if beer_Style.style == style:
			return beer_Style
	
	return null
