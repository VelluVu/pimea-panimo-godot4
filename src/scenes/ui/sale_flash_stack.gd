class_name SaleFlashStack
extends VBoxContainer

## A brief toast for every sale and incident such as a bar fight, stacked while they fade.


const SALE_FLASH_TOAST_SCENE : PackedScene = preload("res://src/scenes/ui/sale_flash_toast.tscn")

const SHIP_FLASH_FORMAT : String = "Vienti (%s): %s x%d  %s (LVV-riski %+d)"

## Bad news in red-orange, so a bar fight never looks like a payout.
const BAR_FIGHT_FLASH_COLOR : Color = Color(1.0, 0.55, 0.4)
## A day event's direct effect in muted amber, apart from the bar fight's red.
const DAY_EVENT_EFFECT_FLASH_COLOR : Color = Color(0.9, 0.75, 0.35)
## Refunded ingredients are good news: green.
const INGREDIENT_REFUND_FLASH_COLOR : Color = Color(0.55, 0.85, 0.5)
const INGREDIENT_REFUND_FLASH_TEXT : String = "Osa raaka-aineista säästyi panon yhteydessä!"


func _ready() -> void:
	BrewerySignals.beer_sale_breakdown.connect(_on_beer_sale_breakdown)
	BrewerySignals.keg_shipped_to_bar.connect(_on_keg_shipped_to_bar)
	BrewerySignals.bar_fight_triggered.connect(_on_bar_fight_triggered)
	BrewerySignals.customer_outburst.connect(_on_bar_fight_triggered)
	BrewerySignals.customer_sale_narrated.connect(_on_customer_sale_narrated)
	BrewerySignals.day_event_effect_triggered.connect(_on_day_event_effect_triggered)
	BrewerySignals.ingredients_refunded.connect(_on_ingredients_refunded)


func _on_beer_sale_breakdown(entry : SaleReceiptEntry) -> void:
	var toast : SaleFlashToast = SALE_FLASH_TOAST_SCENE.instantiate()
	add_child(toast)
	toast.initialize(entry)


func _on_keg_shipped_to_bar(style_name : String, bar_name : String, bottles : int, payout : float, risk_added : int) -> void:
	var toast : SaleFlashToast = SALE_FLASH_TOAST_SCENE.instantiate()
	add_child(toast)
	toast.initialize_text(tr(SHIP_FLASH_FORMAT) % [tr(bar_name), tr(style_name), bottles, NumberText.signed_money(payout), risk_added])


func _on_bar_fight_triggered(message : String) -> void:
	var toast : SaleFlashToast = SALE_FLASH_TOAST_SCENE.instantiate()
	add_child(toast)
	toast.initialize_text(message, BAR_FIGHT_FLASH_COLOR)


func _on_customer_sale_narrated(message : String) -> void:
	var toast : SaleFlashToast = SALE_FLASH_TOAST_SCENE.instantiate()
	add_child(toast)
	toast.initialize_text(message, INGREDIENT_REFUND_FLASH_COLOR)


func _on_day_event_effect_triggered(message : String) -> void:
	var toast : SaleFlashToast = SALE_FLASH_TOAST_SCENE.instantiate()
	add_child(toast)
	toast.initialize_text(message, DAY_EVENT_EFFECT_FLASH_COLOR)


func _on_ingredients_refunded() -> void:
	var toast : SaleFlashToast = SALE_FLASH_TOAST_SCENE.instantiate()
	add_child(toast)
	toast.initialize_text(INGREDIENT_REFUND_FLASH_TEXT, INGREDIENT_REFUND_FLASH_COLOR)
