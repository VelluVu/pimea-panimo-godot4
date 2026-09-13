class_name SaleReceiptLogWindow
extends Panel

## The receipt library: today's sales, reviewable whenever the player wants
## — no timers, nothing disappears. Opened from a button next to MoneyLabel
## (see GUISignals.receipt_log_requested); cleared alongside
## Brewery.today_sale_receipts at day change. Each row toggles its own
## breakdown open/closed on click and stays that way until toggled again or
## the day rolls over — a manual version of the same collapsed/expanded
## idea the old transient popup used, minus any expiry.

const TITLE_TEXT : String = "Päivän kuitit"
const CLOSE_BUTTON_TEXT : String = "Sulje"
const EMPTY_TEXT : String = "Ei myyntejä vielä tänään."
const ROW_SUMMARY_FORMAT : String = "%s  %s  +%.1f €"
const COLLAPSED_ICON : String = "▶"
const EXPANDED_ICON : String = "▼"

@onready var title_label : Label = $MarginContainer/MainVBox/HeaderHBox/TitleLabel
@onready var close_button : Button = $MarginContainer/MainVBox/HeaderHBox/CloseButton
@onready var rows_vbox : VBoxContainer = $MarginContainer/MainVBox/ScrollContainer/RowsVBox

## Entry -> true for every receipt currently toggled open. Keyed by the
## SaleReceiptEntry Resource itself (reference identity), reset on day
## change alongside the receipts it points to.
var _expanded_entries : Dictionary = {}


func _ready() -> void:
	title_label.text = TITLE_TEXT
	close_button.text = CLOSE_BUTTON_TEXT
	close_button.pressed.connect(_on_close_button_pressed)

	GUISignals.receipt_log_requested.connect(_on_receipt_log_requested)
	BrewerySignals.beer_sale_breakdown.connect(_on_beer_sale_breakdown)
	TimeManager.day_changed.connect(_on_day_changed)


func _on_receipt_log_requested() -> void:
	_refresh_rows()
	show()


func _on_close_button_pressed() -> void:
	hide()


func _on_beer_sale_breakdown(_entry : SaleReceiptEntry) -> void:
	if visible:
		_refresh_rows()


func _on_day_changed(_new_day : int) -> void:
	_expanded_entries.clear()
	if visible:
		_refresh_rows()


func _refresh_rows() -> void:
	for child in rows_vbox.get_children():
		child.queue_free()

	if BrewEngine.current_brewery == null:
		return

	var receipts : Array[SaleReceiptEntry] = BrewEngine.current_brewery.today_sale_receipts

	if receipts.is_empty():
		var empty_label := Label.new()
		empty_label.text = EMPTY_TEXT
		empty_label.modulate = Color.DIM_GRAY
		rows_vbox.add_child(empty_label)
		return

	# Newest first, so the latest sale is visible without scrolling.
	for i in range(receipts.size() - 1, -1, -1):
		rows_vbox.add_child(_build_row(receipts[i]))


func _build_row(entry : SaleReceiptEntry) -> Control:
	var row_vbox := VBoxContainer.new()

	var is_expanded : bool = _expanded_entries.has(entry)
	var icon : String = EXPANDED_ICON if is_expanded else COLLAPSED_ICON

	var summary_button := Button.new()
	summary_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	summary_button.text = ROW_SUMMARY_FORMAT % [icon, entry.get_summary_text(), entry.net_income]
	summary_button.pressed.connect(_on_row_pressed.bind(entry))
	row_vbox.add_child(summary_button)

	if is_expanded:
		var detail_label := Label.new()
		detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail_label.add_theme_font_size_override("font_size", 13)
		detail_label.text = entry.get_breakdown_text() + "\n" + entry.get_totals_text()
		row_vbox.add_child(detail_label)

	return row_vbox


func _on_row_pressed(entry : SaleReceiptEntry) -> void:
	if _expanded_entries.has(entry):
		_expanded_entries.erase(entry)
	else:
		_expanded_entries[entry] = true
	_refresh_rows()
