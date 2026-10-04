extends Node


@onready var bartender: Bartender = $WorldYSort/Bartender


func _ready() -> void:
	BrewerySignals.beer_sale_breakdown.connect(_on_beer_sale_breakdown)


func _on_beer_sale_breakdown(entry: SaleReceiptEntry) -> void:
	bartender.play_serve_beer(1.0, entry.beer_ebc)
