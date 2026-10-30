class_name SaleFlashToast
extends Panel

## A brief, non-interactive sale notice; the breakdown is in the receipt log.

const HOLD_SECONDS : float = 1.5
const FADE_OUT_SECONDS : float = 1.0

const LABEL_FORMAT : String = "Myyty: %s  %s"

## The toast column has little margin to the screen edge, so long text wraps at this.
const MAX_WIDTH : float = 180.0

@onready var label : Label = $MarginContainer/Label
@onready var margin_container : MarginContainer = $MarginContainer


## The toast column overlaps the warehouse rows, so no node here may eat their clicks.
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE


func initialize(entry : SaleReceiptEntry) -> void:
	initialize_text(tr(LABEL_FORMAT) % [entry.get_summary_text(), NumberText.signed_money(entry.net_income)])


## A flash without a receipt (shipping, bar fights); a warmer colour for bad news.
func initialize_text(text : String, text_color : Color = Color.WHITE) -> void:
	label.text = text
	label.modulate = text_color
	_resize_to_fit_content()

	var timer := GameSpeed.reading_timer(get_tree(), HOLD_SECONDS)
	timer.timeout.connect(_start_fade_out)


## A Panel does not pass its child's minimum size to the stacking VBoxContainer.
func _resize_to_fit_content() -> void:
	await get_tree().process_frame
	if not is_instance_valid(self):
		return

	var natural_size : Vector2 = margin_container.get_combined_minimum_size()
	if natural_size.x <= MAX_WIDTH:
		custom_minimum_size = natural_size
		return

	# Too wide: fix the width so the label's autowrap has a rect, then measure the height a
	# frame later.
	custom_minimum_size = Vector2(MAX_WIDTH, natural_size.y)
	await get_tree().process_frame
	if is_instance_valid(self):
		custom_minimum_size.y = margin_container.get_combined_minimum_size().y


func _start_fade_out() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, FADE_OUT_SECONDS)
	tween.tween_callback(queue_free)
