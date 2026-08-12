class_name BrewBatch
extends Resource


@export var style: BrewResult.BeerStyle = BrewResult.BeerStyle.KOTIKALJA

@export var final_ebc: int = 0
@export var final_ibu: int = 0

@export var quality_multiplier: float = 1.0
@export var current_quality : float = 0.0
@export var amount_bottles: int = 40


func get_style_name() -> String:
	match style:
		BrewResult.BeerStyle.KOTIKALJA: return StringContainer.KOTIKALJA
		BrewResult.BeerStyle.BULKKI_LAGER: return StringContainer.BULKKILAGER
		BrewResult.BeerStyle.TUMMA_LAGER: return StringContainer.TUMMALAGER
		BrewResult.BeerStyle.VAALEA_ALE: return StringContainer.VAALEAALE
		BrewResult.BeerStyle.AMBER_ALE: return StringContainer.AMBERALE
		BrewResult.BeerStyle.IPA: return StringContainer.IPA
		_: return StringContainer.TUNTEMATON
