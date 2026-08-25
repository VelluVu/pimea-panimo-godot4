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
	var yeast_type: int = -1
	
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
	
		var result := BrewResult.new()
		result.beer_style = beer_style
		result.final_ebc = final_ebc
		result.final_ibu = final_ibu
		result.original_quality = beer_style.original_quality
		result.risk_change = beer_style.risk_change
		result.reputation_change = beer_style.reputation_change
		return result
	
	var failed_result := BrewResult.new()
	failed_result.beer_style = get_beer_style(BeerStyle.Style.KOTIKALJA)
	failed_result.final_ebc = final_ebc
	failed_result.final_ibu = final_ibu
	failed_result.original_quality = 1.0
	failed_result.risk_change = 2
	failed_result.reputation_change = -1
	
	return failed_result


func get_beer_style(style : BeerStyle.Style) -> BeerStyle:
	for beer_Style in active_styles:
		if beer_Style.style == style:
			return beer_Style
	
	return null
