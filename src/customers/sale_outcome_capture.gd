class_name SaleOutcomeCapture
extends RefCounted

## Records the xp, reputation and tip that BrewerySignals reports while one
## synchronous sale runs, so the customer can show popups for exactly its own
## sale. Call start() before the sale and stop() right after it.

var xp: int = 0
var reputation: int = 0
var tip: float = 0.0
## Bottles broken in a bar fight during the sale, or -1 when none broke out.
var bar_fight_bottles: int = -1
## EBC of the beer sold, or -1 when nothing was sold.
var beer_ebc: int = -1


func start() -> void:
	BrewerySignals.sale_xp_gained.connect(_on_xp)
	BrewerySignals.sale_reputation_gained.connect(_on_reputation)
	BrewerySignals.sale_tip_gained.connect(_on_tip)
	BrewerySignals.bar_fight_started.connect(_on_bar_fight)
	BrewerySignals.beer_sale_breakdown.connect(_on_sale_breakdown)


func stop() -> void:
	BrewerySignals.sale_xp_gained.disconnect(_on_xp)
	BrewerySignals.sale_reputation_gained.disconnect(_on_reputation)
	BrewerySignals.sale_tip_gained.disconnect(_on_tip)
	BrewerySignals.bar_fight_started.disconnect(_on_bar_fight)
	BrewerySignals.beer_sale_breakdown.disconnect(_on_sale_breakdown)


func emit_xp_popup(position: Vector2) -> void:
	BrewerySignals.xp_popup_requested.emit(xp, position)


## Nothing is emitted for a zero reputation change or a missing tip.
func emit_reputation_and_tip_popups(position: Vector2) -> void:
	if reputation != 0:
		BrewerySignals.reputation_popup_requested.emit(reputation, position)
	if tip > 0:
		BrewerySignals.tip_popup_requested.emit(tip, position)


func _on_xp(amount: int) -> void:
	xp = amount


func _on_reputation(amount: int) -> void:
	reputation = amount


func _on_tip(amount: float) -> void:
	tip = amount


func _on_bar_fight(broken_bottles: int) -> void:
	bar_fight_bottles = broken_bottles


func _on_sale_breakdown(entry: SaleReceiptEntry) -> void:
	beer_ebc = entry.beer_ebc
