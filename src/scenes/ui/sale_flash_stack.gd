class_name SaleFlashStack
extends VBoxContainer

## Spawns a brief SaleFlashToast for every sale, plus any other "something
## just happened" incident (currently: bar fights — see
## BrewerySignals.bar_fight_triggered) that used to be buried in a
## customer's own dialogue bubble instead of getting its own notice.
## Self-contained: connects to BrewerySignals directly. No coordination
## needed between toasts — each one manages its own hold/fade and frees
## itself; the VBoxContainer just stacks whatever's currently alive, which
## is exactly what lets an overlapping sale and bar fight show as two
## separate stacked toasts instead of one clobbering the other.


const SALE_FLASH_TOAST_SCENE : PackedScene = preload("res://src/scenes/ui/sale_flash_toast.tscn")

const BULK_SELL_FLASH_FORMAT : String = "Halpamyynti: %s x%d  +%.1f €"
const SHIP_FLASH_FORMAT : String = "Vienti (%s): %s x%d  +%.1f € (LVV-riski +%d)"

## Warm red-orange instead of the default sale-toast white, so a bar-fight
## flash reads as bad news at a glance instead of looking like another payout.
const BAR_FIGHT_FLASH_COLOR : Color = Color(1.0, 0.55, 0.4)
## Same "bad news" reasoning as BAR_FIGHT_FLASH_COLOR, for a day event's own
## direct effect (stock eaten, bottles spoiled) — muted amber instead of the
## bar fight's red-orange so the two read as distinct kinds of bad news.
const DAY_EVENT_EFFECT_FLASH_COLOR : Color = Color(0.9, 0.75, 0.35)
## Good news this time (ingredients_refunded) — a cool green instead of any
## of the "something bad happened" colors above.
const INGREDIENT_REFUND_FLASH_COLOR : Color = Color(0.55, 0.85, 0.5)
const INGREDIENT_REFUND_FLASH_TEXT : String = "Osa raaka-aineista säästyi panon yhteydessä!"


func _ready() -> void:
	BrewerySignals.beer_sale_breakdown.connect(_on_beer_sale_breakdown)
	BrewerySignals.batch_bulk_sold.connect(_on_batch_bulk_sold)
	BrewerySignals.keg_shipped_to_bar.connect(_on_keg_shipped_to_bar)
	BrewerySignals.bar_fight_triggered.connect(_on_bar_fight_triggered)
	BrewerySignals.day_event_effect_triggered.connect(_on_day_event_effect_triggered)
	BrewerySignals.ingredients_refunded.connect(_on_ingredients_refunded)


func _on_beer_sale_breakdown(entry : SaleReceiptEntry) -> void:
	var toast : SaleFlashToast = SALE_FLASH_TOAST_SCENE.instantiate()
	add_child(toast)
	toast.initialize(entry)


func _on_batch_bulk_sold(style_name : String, bottles : int, payout : float) -> void:
	var toast : SaleFlashToast = SALE_FLASH_TOAST_SCENE.instantiate()
	add_child(toast)
	toast.initialize_text(BULK_SELL_FLASH_FORMAT % [style_name, bottles, payout])


func _on_keg_shipped_to_bar(style_name : String, bar_name : String, bottles : int, payout : float, risk_added : int) -> void:
	var toast : SaleFlashToast = SALE_FLASH_TOAST_SCENE.instantiate()
	add_child(toast)
	toast.initialize_text(SHIP_FLASH_FORMAT % [bar_name, style_name, bottles, payout, risk_added])


func _on_bar_fight_triggered(message : String) -> void:
	var toast : SaleFlashToast = SALE_FLASH_TOAST_SCENE.instantiate()
	add_child(toast)
	toast.initialize_text(message, BAR_FIGHT_FLASH_COLOR)


func _on_day_event_effect_triggered(message : String) -> void:
	var toast : SaleFlashToast = SALE_FLASH_TOAST_SCENE.instantiate()
	add_child(toast)
	toast.initialize_text(message, DAY_EVENT_EFFECT_FLASH_COLOR)


func _on_ingredients_refunded() -> void:
	var toast : SaleFlashToast = SALE_FLASH_TOAST_SCENE.instantiate()
	add_child(toast)
	toast.initialize_text(INGREDIENT_REFUND_FLASH_TEXT, INGREDIENT_REFUND_FLASH_COLOR)
