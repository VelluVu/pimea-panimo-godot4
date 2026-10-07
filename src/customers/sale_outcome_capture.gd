class_name SaleOutcomeCapture
extends RefCounted

## Records the xp, reputation and tip that BrewerySignals reports while one
## synchronous sale runs, so the customer can show popups for exactly its own
## sale. Call start() before the sale and stop() right after it.

var xp: int = 0
var reputation: int = 0
var tip: float = 0.0
var tip_tier: PopupTierRules.Tier = PopupTierRules.Tier.NORMAL
## Quality of the beer sold, or -1 when nothing was sold.
var beer_quality: float = -1.0
## Bottles broken in a bar fight during the sale, or -1 when none broke out.
var bar_fight_bottles: int = -1
## EBC of the beer sold, or -1 when nothing was sold.
var beer_ebc: int = -1

var _critical_announced: bool = false


func start() -> void:
	BrewerySignals.sale_xp_gained.connect(_on_xp)
	BrewerySignals.sale_reputation_gained.connect(_on_reputation)
	BrewerySignals.sale_tip_gained.connect(_on_tip)
	BrewerySignals.bar_fight_started.connect(_on_bar_fight)
	BrewerySignals.beer_sale_breakdown.connect(_on_sale_breakdown)
	BrewerySignals.sale_popup_tiers_rated.connect(_on_tiers_rated)


func stop() -> void:
	BrewerySignals.sale_xp_gained.disconnect(_on_xp)
	BrewerySignals.sale_reputation_gained.disconnect(_on_reputation)
	BrewerySignals.sale_tip_gained.disconnect(_on_tip)
	BrewerySignals.bar_fight_started.disconnect(_on_bar_fight)
	BrewerySignals.beer_sale_breakdown.disconnect(_on_sale_breakdown)
	BrewerySignals.sale_popup_tiers_rated.disconnect(_on_tiers_rated)


func emit_xp_popup(position: Vector2) -> void:
	var tier: PopupTierRules.Tier = PopupTierRules.quality_tier(beer_quality, xp)
	BrewerySignals.xp_popup_requested.emit(xp, position, tier)
	_announce_if_critical(tier, position)


## Nothing is emitted for a zero reputation change or a missing tip.
func emit_reputation_and_tip_popups(position: Vector2) -> void:
	if reputation != 0:
		var tier: PopupTierRules.Tier = PopupTierRules.quality_tier(beer_quality, reputation)
		BrewerySignals.reputation_popup_requested.emit(reputation, position, tier)
		_announce_if_critical(tier, position)
	if tip > 0:
		BrewerySignals.tip_popup_requested.emit(tip, position, tip_tier)
		_announce_if_critical(tip_tier, position)


## One crit sound per sale, however many of its popups are critical.
func _announce_if_critical(tier: PopupTierRules.Tier, position: Vector2) -> void:
	if tier == PopupTierRules.Tier.CRITICAL and not _critical_announced:
		_critical_announced = true
		BrewerySignals.critical_gain_shown.emit(position)


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


func _on_tiers_rated(rated_tip_tier: PopupTierRules.Tier, quality: float) -> void:
	tip_tier = rated_tip_tier
	beer_quality = quality
