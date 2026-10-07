class_name SaleOutcomeCapture
extends RefCounted

## Records the xp, reputation and tip that BrewerySignals reports while one
## synchronous sale runs, so the customer can show popups for exactly its own
## sale. Call start() before the sale and stop() right after it.

## What a sale did to the customer's opinion of the cellar, shown as a popup over them.
enum Note { FRIEND_RECOMMENDED, BAD_REVIEW, BECAME_REGULAR, LOST_REGULAR }

var xp: int = 0
var reputation: int = 0
var tip: float = 0.0
## What the bottles cost, without the tip.
var income: float = 0.0
var tip_tier: PopupTierRules.Tier = PopupTierRules.Tier.NORMAL
## Quality of the beer sold, or -1 when nothing was sold.
var beer_quality: float = -1.0
## Bottles broken in a bar fight during the sale, or -1 when none broke out.
var bar_fight_bottles: int = -1
## EBC of the beer sold, or -1 when nothing was sold.
var beer_ebc: int = -1
var notes: Array[Note] = []


func start() -> void:
	BrewerySignals.sale_xp_gained.connect(_on_xp)
	BrewerySignals.sale_reputation_gained.connect(_on_reputation)
	BrewerySignals.sale_tip_gained.connect(_on_tip)
	BrewerySignals.bar_fight_started.connect(_on_bar_fight)
	BrewerySignals.beer_sale_breakdown.connect(_on_sale_breakdown)
	BrewerySignals.sale_popup_tiers_rated.connect(_on_tiers_rated)
	BrewerySignals.friend_recommended.connect(_on_friend_recommended)
	BrewerySignals.bad_review_spread.connect(_on_bad_review)
	BrewerySignals.regular_status_changed.connect(_on_regular_status_changed)


func stop() -> void:
	BrewerySignals.sale_xp_gained.disconnect(_on_xp)
	BrewerySignals.sale_reputation_gained.disconnect(_on_reputation)
	BrewerySignals.sale_tip_gained.disconnect(_on_tip)
	BrewerySignals.bar_fight_started.disconnect(_on_bar_fight)
	BrewerySignals.beer_sale_breakdown.disconnect(_on_sale_breakdown)
	BrewerySignals.sale_popup_tiers_rated.disconnect(_on_tiers_rated)
	BrewerySignals.friend_recommended.disconnect(_on_friend_recommended)
	BrewerySignals.bad_review_spread.disconnect(_on_bad_review)
	BrewerySignals.regular_status_changed.disconnect(_on_regular_status_changed)


func emit_xp_popup(position: Vector2) -> void:
	var tier: PopupTierRules.Tier = PopupTierRules.quality_tier(beer_quality, xp)
	BrewerySignals.xp_popup_requested.emit(xp, position, tier)


## Nothing is emitted for a zero reputation change or a sale that earned nothing.
func emit_reputation_and_money_popups(position: Vector2) -> void:
	if reputation != 0:
		BrewerySignals.reputation_popup_requested.emit(reputation, position, PopupTierRules.quality_tier(beer_quality, reputation))
	if income > 0.0 or tip > 0.0:
		BrewerySignals.money_popup_requested.emit(income, tip, position, tip_tier)
	for note: Note in notes:
		BrewerySignals.customer_note_popup_requested.emit(note, position)


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
	income = entry.gross_income


func _on_friend_recommended(_data: CustomerData) -> void:
	notes.append(Note.FRIEND_RECOMMENDED)


func _on_bad_review() -> void:
	notes.append(Note.BAD_REVIEW)


func _on_regular_status_changed(_customer_title: String, is_regular: bool) -> void:
	notes.append(Note.BECAME_REGULAR if is_regular else Note.LOST_REGULAR)


func _on_tiers_rated(rated_tip_tier: PopupTierRules.Tier, quality: float) -> void:
	tip_tier = rated_tip_tier
	beer_quality = quality
