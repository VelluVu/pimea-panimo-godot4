class_name SaleFlashToast
extends Panel

## A brief, non-interactive "a sale happened" notice — no click, no
## breakdown, just enough to notice. The full breakdown always lands in
## Brewery.today_sale_receipts for the player to check later in
## SaleReceiptLogWindow, on their own time.

const HOLD_SECONDS : float = 1.5
const FADE_OUT_SECONDS : float = 1.0

const LABEL_FORMAT : String = "Myyty: %s  +%.1f €"

## Same clamp idea as SpeechBubble's own MIN/MAX_WIDTH (see speech_bubble.gd)
## — SaleFlashStack's toast column only has ~13px of margin to the actual
## right screen edge, so an uncapped long string (a long style/bar name)
## would grow past it instead of wrapping onto another line.
const MAX_WIDTH : float = 180.0

@onready var label : Label = $MarginContainer/Label
@onready var margin_container : MarginContainer = $MarginContainer


## The toast column overlaps the warehouse rows, so no node here may eat their clicks.
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE


func initialize(entry : SaleReceiptEntry) -> void:
	initialize_text(tr(LABEL_FORMAT) % [entry.get_summary_text(), entry.net_income])


## A flash without a SaleReceiptEntry (shipping, bar fights). Pass a warmer text_color
## for bad news so it doesn't read as a payout.
func initialize_text(text : String, text_color : Color = Color.WHITE) -> void:
	label.text = text
	label.modulate = text_color
	_resize_to_fit_content()

	var timer := get_tree().create_timer(HOLD_SECONDS)
	timer.timeout.connect(_start_fade_out)


## Panel doesn't extend Container, so it never relays its child's computed
## minimum size to the VBoxContainer that stacks these toasts.
func _resize_to_fit_content() -> void:
	await get_tree().process_frame
	if not is_instance_valid(self):
		return

	var natural_size : Vector2 = margin_container.get_combined_minimum_size()
	if natural_size.x <= MAX_WIDTH:
		custom_minimum_size = natural_size
		return

	# Wider than the column allows — fix the width at MAX_WIDTH so the
	# Label's existing autowrap (WORD_SMART, see sale_flash_toast.tscn)
	# actually has a rect to wrap against, then re-measure height once
	# that width has taken effect for a frame.
	custom_minimum_size = Vector2(MAX_WIDTH, natural_size.y)
	await get_tree().process_frame
	if is_instance_valid(self):
		custom_minimum_size.y = margin_container.get_combined_minimum_size().y


func _start_fade_out() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, FADE_OUT_SECONDS)
	tween.tween_callback(queue_free)
