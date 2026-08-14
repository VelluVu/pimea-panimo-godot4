class_name BrewResolver
extends Resource


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
	
	var result := BrewResult.new()
	result.final_ebc = roundi(weighted_ebc_sum / total_malt_weight)
	
	if total_hop_amount == 0:
		result.style = BrewResult.BeerStyle.KOTIKALJA
		result.final_ibu = 0
		result.quality_multiplier = 0.4
		result.risk_change = 1
		result.reputation_change = 0
		return result
	
	result.final_ibu = roundi(total_alpha_acids / 10)
	
	if yeast_type == 301: # LAGER-HIIVA
		if result.final_ebc > 45:
			result.style = BrewResult.BeerStyle.TUMMA_LAGER
			result.risk_change = 5
			result.reputation_change = 2
		else:
			result.style = BrewResult.BeerStyle.BULKKI_LAGER
			result.risk_change = 3
			result.reputation_change = 1
	
	elif yeast_type == 302: # ALE-HIIVA
		if result.final_ibu > 40: 
			result.style = BrewResult.BeerStyle.IPA
			result.risk_change = 8
			result.reputation_change = 4
		elif result.final_ebc > 25:
			result.style = BrewResult.BeerStyle.AMBER_ALE
			result.risk_change = 5
			result.reputation_change = 2
		else:
			result.style = BrewResult.BeerStyle.VAALEA_ALE
			result.risk_change = 4
			result.reputation_change = 2
	
	return result
