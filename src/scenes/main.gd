extends Node


@onready var bartender: Bartender = $WorldYSort/Bartender
@onready var tap_tower: TapTower = $WorldYSort/BarTable/BarTable_Sprite2D/TapTower
@onready var keg_row: KegRow = $WorldYSort/KegRow
@onready var customer_spawner: CustomerSpawner = $WorldYSort/CustomerSpawner

## The batches on the taps, left to right, as last drawn.
var _tap_batches: Array[BrewBatch] = []


func _ready() -> void:
	customer_spawner.bind_brewery(BrewEngine.current_brewery)
	BrewEngine.brewery_changed.connect(customer_spawner.bind_brewery)
	BrewerySignals.beer_sale_breakdown.connect(_on_beer_sale_breakdown)
	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)
	if BrewEngine.current_brewery != null:
		_on_brewery_state_changed(BrewEngine.current_brewery)


## A tap per keg owned; a keg behind the counter and a coloured handle per batch on serve.
func _on_brewery_state_changed(brewery: Brewery) -> void:
	_tap_batches = brewery.inventory.batches_on_serve().slice(0, TapLayout.MAX_TAPS)
	var colors: Array[Color] = []
	for batch: BrewBatch in _tap_batches:
		colors.append(BeerColor.from_ebc(batch.final_ebc))
	tap_tower.set_taps(brewery.inventory.total_kegs(), colors)
	keg_row.show_kegs(_tap_batches)


## The bartender pours under the sold batch's tap; an unknown batch pours where he stands.
func _on_beer_sale_breakdown(entry: SaleReceiptEntry) -> void:
	var tap: int = _tap_batches.find(entry.batch)
	var offset: float = 0.0 if tap < 0 else bartender.offset_to_pour_at(tap_tower.spout_global_x(tap))
	bartender.play_serve_beer(Bartender.SOLO_POUR_SPEED_SCALE, entry.beer_ebc, offset)
