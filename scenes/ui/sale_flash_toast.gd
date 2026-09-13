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


func initialize(entry : SaleReceiptEntry) -> void:
	label.text = LABEL_FORMAT % [entry.get_summary_text(), entry.net_income]
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
