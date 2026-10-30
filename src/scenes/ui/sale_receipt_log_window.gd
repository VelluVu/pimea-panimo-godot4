class_name SaleReceiptLogWindow
extends Panel

## Today's sales, cleared at day change; each row toggles its breakdown on click.

const TITLE_TEXT : String = "Päivän kuitit"
const EMPTY_TEXT : String = "Ei myyntejä vielä tänään."
const EMPTY_TEXT_COLOR : Color = Color(0.9490196, 0.7882353, 0.41960785, 1) # matches BeerBatchPanel.EMPTY_INVENTORY_COLOR
const ROW_SUMMARY_FORMAT : String = "%s  %s  %s"
const COLLAPSED_ICON : String = "▶"
const EXPANDED_ICON : String = "▼"
const PAPER_COLOR : Color = Color(0.91, 0.87, 0.77)
const INK_COLOR : Color = Color(0.16, 0.13, 0.11)
const PAPER_MARGIN : float = 6.0
const RECEIPT_FONT_SIZE : int = 16

@onready var title_label : Label = %TitleLabel
@onready var rows_vbox : VBoxContainer = %RowsVBox

## Receipts toggled open, keyed by the entry itself, reset with the day.
var _expanded_entries : Dictionary = {}


func _ready() -> void:
	title_label.text = TITLE_TEXT
	WindowCloseButton.attach(self, _on_close_button_pressed)

	GUISignals.receipt_log_requested.connect(_on_receipt_log_requested)
	BrewerySignals.beer_sale_breakdown.connect(_on_beer_sale_breakdown)
	TimeManager.day_changed.connect(_on_day_changed)


func _on_receipt_log_requested() -> void:
	# Tapping the spot that opened it closes it again.
	if visible:
		_on_close_button_pressed()
		return
	_refresh_rows()
	show()


func _on_close_button_pressed() -> void:
	GUISignals.window_closed.emit()
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
		# The empty-list gold the warehouse uses: dim grey on the brown panel was hard to read.
		empty_label.modulate = EMPTY_TEXT_COLOR
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
	summary_button.text = ROW_SUMMARY_FORMAT % [icon, entry.get_summary_text(), NumberText.signed_money(entry.net_income)]
	summary_button.pressed.connect(_on_row_pressed.bind(entry))
	row_vbox.add_child(summary_button)

	if is_expanded:
		row_vbox.add_child(_make_paper(ReceiptText.text(entry)))

	return row_vbox


## The receipt printed on a strip of paper from the till.
func _make_paper(text : String) -> Control:
	var paper := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER_COLOR
	style.set_content_margin_all(PAPER_MARGIN)
	paper.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", RECEIPT_FONT_SIZE)
	label.add_theme_color_override("font_color", INK_COLOR)
	# The theme's dark label outline smears dark ink on light paper.
	label.add_theme_constant_override("outline_size", 0)
	label.text = text
	paper.add_child(label)
	return paper


func _on_row_pressed(entry : SaleReceiptEntry) -> void:
	if _expanded_entries.has(entry):
		_expanded_entries.erase(entry)
	else:
		_expanded_entries[entry] = true
	_refresh_rows()
