class_name SaleFlashStack
extends VBoxContainer

## Spawns a brief SaleFlashToast for every sale. Self-contained: connects to
## BrewerySignals directly. No coordination needed between toasts — each one
## manages its own hold/fade and frees itself; the VBoxContainer just stacks
## whatever's currently alive.


const SALE_FLASH_TOAST_SCENE : PackedScene = preload("res://scenes/ui/sale_flash_toast.tscn")


func _ready() -> void:
	BrewerySignals.beer_sale_breakdown.connect(_on_beer_sale_breakdown)


func _on_beer_sale_breakdown(entry : SaleReceiptEntry) -> void:
	var toast : SaleFlashToast = SALE_FLASH_TOAST_SCENE.instantiate()
	add_child(toast)
	toast.initialize(entry)
