class_name SaleFlashToast
extends Panel

## A brief, non-interactive "a sale happened" notice — no click, no
## breakdown, just enough to notice. The full breakdown always lands in
## Brewery.today_sale_receipts for the player to check later in
## SaleReceiptLogWindow, on their own time.

const HOLD_SECONDS : float = 1.5
const FADE_OUT_SECONDS : float = 1.0

const LABEL_FORMAT : String = "Myyty: %s  +%.1f €"

@onready var label : Label = $MarginContainer/Label
@onready var margin_container : MarginContainer = $MarginContainer


## Panel's own mouse_filter defaults to STOP and was never overridden in
## the scene — harmless while this only ever sat over empty background,
## but SaleFlashStack's toast column overlaps RightWarehouseView's batch
## rows, and a live toast (in front by sibling order) was silently
## swallowing clicks meant for the "Myy"/"Vie" buttons underneath it for
## its whole ~2.5s lifetime. A non-interactive notice should never be able
## to eat a click for anything, so every node in this scene explicitly
## ignores the mouse — matches this project's existing convention of
## setting mouse_filter = IGNORE explicitly on layout-only nodes rather
## than relying on a class default (see e.g. BeerBatchScrollContainer/
## BeerBatchListVBox in right_warehouse_view.tscn).
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE


func initialize(entry : SaleReceiptEntry) -> void:
	initialize_text(LABEL_FORMAT % [entry.get_summary_text(), entry.net_income])


## Generic entry point for flashes that don't have a SaleReceiptEntry to
## summarize — see SaleFlashStack's bulk-sell/ship-to-bar listeners, which
## aren't real customer sales but still deserve the same brief "something
## happened" notice.
func initialize_text(text : String) -> void:
	label.text = text
	_resize_to_fit_content()

	var timer := get_tree().create_timer(HOLD_SECONDS)
	timer.timeout.connect(_start_fade_out)


## Panel doesn't extend Container, so it never relays its child's computed
## minimum size to the VBoxContainer that stacks these toasts.
func _resize_to_fit_content() -> void:
	await get_tree().process_frame
	if is_instance_valid(self):
		custom_minimum_size = margin_container.get_combined_minimum_size()


func _start_fade_out() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, FADE_OUT_SECONDS)
	tween.tween_callback(queue_free)
