class_name SaleOutcomeCapture
extends RefCounted

## Records the xp, reputation and tip that BrewerySignals reports while one
## synchronous sale runs, so the customer can show popups for exactly its own
## sale. Call start() before the sale and stop() right after it.

var xp: int = 0
var reputation: int = 0
var tip: float = 0.0


func start() -> void:
	BrewerySignals.sale_xp_gained.connect(_on_xp)
	BrewerySignals.sale_reputation_gained.connect(_on_reputation)
	BrewerySignals.sale_tip_gained.connect(_on_tip)


func stop() -> void:
	BrewerySignals.sale_xp_gained.disconnect(_on_xp)
	BrewerySignals.sale_reputation_gained.disconnect(_on_reputation)
	BrewerySignals.sale_tip_gained.disconnect(_on_tip)


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
