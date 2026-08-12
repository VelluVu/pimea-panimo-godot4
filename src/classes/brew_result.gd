class_name BrewResult
extends Resource

enum BeerStyle {KOTIKALJA, BULKKI_LAGER, TUMMA_LAGER, VAALEA_ALE, AMBER_ALE, IPA}
@export var style : BeerStyle

@export var final_ebc : int = 0
@export var final_ibu : int = 0
@export var quality_multiplier : float = 1.0
@export var risk_change : int = 0
@export var reputation_change : int = 0
@export var bottle_yield : int = 40

func get_style_string() -> String:
	match style:
		BeerStyle.KOTIKALJA: return StringContainer.KOTIKALJA
		BeerStyle.BULKKI_LAGER: return StringContainer.BULKKILAGER
		BeerStyle.TUMMA_LAGER: return StringContainer.TUMMALAGER
		BeerStyle.VAALEA_ALE: return StringContainer.VAALEAALE
		BeerStyle.AMBER_ALE: return StringContainer.AMBERALE
		BeerStyle.IPA: return StringContainer.IPA
		_: return StringContainer.TUNTEMATON
