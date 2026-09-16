class_name SaleFlashStack
extends VBoxContainer

## Spawns a brief SaleFlashToast for every sale. Self-contained: connects to
## BrewerySignals directly. No coordination needed between toasts — each one
## manages its own hold/fade and frees itself; the VBoxContainer just stacks
## whatever's currently alive.


const SALE_FLASH_TOAST_SCENE : PackedScene = preload("res://scenes/ui/sale_flash_toast.tscn")

const BULK_SELL_FLASH_FORMAT : String = "Halpamyynti: %s x%d  +%.1f €"
const SHIP_FLASH_FORMAT : String = "Vienti (%s): %s x%d  +%.1f € (LVV-riski +%d)"


func _ready() -> void:
	BrewerySignals.beer_sale_breakdown.connect(_on_beer_sale_breakdown)
	BrewerySignals.batch_bulk_sold.connect(_on_batch_bulk_sold)
	BrewerySignals.keg_shipped_to_bar.connect(_on_keg_shipped_to_bar)


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
