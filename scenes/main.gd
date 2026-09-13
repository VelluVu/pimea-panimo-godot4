extends Node


@onready var bartender: Bartender = $WorldYSort/Bartender


func _ready() -> void:
	BrewerySignals.bottles_sold.connect(_on_bottles_sold)


func _on_bottles_sold(_amount: int) -> void:
	bartender.play_serve_beer()
