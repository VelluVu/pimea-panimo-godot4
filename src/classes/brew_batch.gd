class_name BrewBatch
extends Resource


@export var style: BeerStyle.Style = BeerStyle.Style.KOTIKALJA

@export var final_ebc: int = 0
@export var final_ibu: int = 0

@export var quality_multiplier: float = 1.0
@export var current_quality : float = 0.0
@export var amount_bottles: int = 40


func get_style_name() -> String:
	return BeerStyle.get_style_string_from_style(style)
