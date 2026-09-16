class_name BeerPatchPanel
extends VBoxContainer


@onready var beer_batch_list_vbox : VBoxContainer = $BeerBatchScrollContainer/BeerBatchListVBox
const LABEL_STRING : String = "🍺 %s (%.1f%%) - %s annosta (%s %s)"
## Shown when there's nothing left to sell — without this the panel just
## goes quiet with no explanation. Customer traffic keeps arriving even
## now (CustomerSpawner no longer withholds spawning on empty inventory
## past the player's first brew — see its _on_walk_in_timer_timeout()
## docstring), it just gets turned away, costing reputation/risk, so this
## label is the only warning the player gets before that starts happening.
## See playtest_notes_2.txt.
const EMPTY_INVENTORY_TEXT : String = "Ei olutta myytävänä — keitä lisää!"
const EMPTY_INVENTORY_COLOR : Color = Color(0.9490196, 0.7882353, 0.41960785, 1) # matches DailyGoalsPanel.GOAL_PENDING_COLOR

## Dumps the whole batch at once — see Brewery.BULK_SELL_RATE's docstring
## for why this is a "clear the warehouse" action, not a real sale.
## Short on purpose — RightWarehouseView's panel is only ~140px wide at
## this game's base resolution (640x360), with two action buttons now
## sharing each row alongside the batch label. Full context lives in the
## tooltip below instead of the button face.
const BULK_SELL_BUTTON_TEXT : String = "Myy"
const BULK_SELL_BUTTON_TOOLTIP : String = "Myy koko erä kerralla varastosta — hinta on paljon normaalia myyntihintaa halvempi, ja heikkolaatuinen tai vanhentunut erä voi tuottaa jopa tappiota raaka-ainekuluihin nähden."

const DESTINATION_LABEL_TEXT : String = "Kohde:"
const SHIP_BUTTON_TEXT : String = "Vie"
const SHIP_BUTTON_TOOLTIP : String = "Vie koko erä yllä valittuun baariin — parempi hinta kuin halpamyynti, mutta nostaa LVV-riskiä toimituksen mukana."

## Floor under the batch row label's width — without it, HBoxContainer's
## layout pass can hand the label (size_flags SIZE_EXPAND_FILL, sharing
## the row with two buttons) a near-zero width before settling, and word
## wrap under a near-zero width blows the row up to hundreds of pixels
## tall instead of the intended one or two lines. See get_full_info_tooltip()
## for where the batch's full stats still live once the label itself
## clips.
const ROW_LABEL_MIN_WIDTH : float = 50.0

## Built once in _ready() rather than in the scene — RightWarehouseView's
## tabbed layout is already assembled almost entirely by script (see this
## panel's own row-building below), and a single shared picker above the
## batch list is simpler than giving every row its own BarContact dropdown.
var _bar_contact_option_button : BarContactOptionButton = null


func _ready() -> void:
	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)

	var destination_row := HBoxContainer.new()
	destination_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var destination_label := Label.new()
	destination_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	destination_label.text = DESTINATION_LABEL_TEXT
	_bar_contact_option_button = BarContactOptionButton.new()
	_bar_contact_option_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	destination_row.add_child(destination_label)
	destination_row.add_child(_bar_contact_option_button)
	add_child(destination_row)
	move_child(destination_row, 0)

	_update_beer_batches_ui()


func _on_brewery_state_changed(_brewery: Brewery) -> void:
	_update_beer_batches_ui()


func _update_beer_batches_ui() -> void:
	for child in beer_batch_list_vbox.get_children():
		child.queue_free()
		
	if BrewEngine.current_brewery == null: 
		return
		
	var inventory : Inventory = BrewEngine.current_brewery.inventory
	var any_bottles_left : bool = false

	for batch: BrewBatch in inventory.brew_batches:

		if batch.amount_bottles > 0:
			any_bottles_left = true

			var row_label := Label.new()
			row_label.mouse_filter = Control.MOUSE_FILTER_STOP
			row_label.clip_text = true
			row_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			row_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row_label.custom_minimum_size = Vector2(ROW_LABEL_MIN_WIDTH, 0)
			row_label.add_theme_font_size_override("font_size", 16)

			row_label.text = LABEL_STRING % [
				batch.get_style_name(),
				batch.beer_style.abv,
				str(batch.amount_bottles),
				batch.get_quality_tier_string(),
				batch.get_aging_trend_icon()
			]
			row_label.tooltip_text = batch.get_full_info_tooltip()

			if batch.beer_style.style == BeerStyle.Style.KOTIKALJA:
				row_label.modulate = Color.DARK_GRAY
			elif batch.beer_style.style == BeerStyle.Style.IPA:
				row_label.modulate = Color.GOLD

			var bulk_sell_button := Button.new()
			bulk_sell_button.text = BULK_SELL_BUTTON_TEXT
			bulk_sell_button.tooltip_text = BULK_SELL_BUTTON_TOOLTIP
			bulk_sell_button.pressed.connect(func(): GUISignals.bulk_sell_batch_requested.emit(batch))

			var ship_button := Button.new()
			ship_button.text = SHIP_BUTTON_TEXT
			ship_button.tooltip_text = SHIP_BUTTON_TOOLTIP
			ship_button.pressed.connect(func():
				var bar : BarContact = _bar_contact_option_button.get_selected_bar()
				if bar != null:
					GUISignals.ship_batch_to_bar_requested.emit(batch, bar)
			)

			var row := HBoxContainer.new()
			row.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(row_label)
			row.add_child(bulk_sell_button)
			row.add_child(ship_button)
			beer_batch_list_vbox.add_child(row)

	if not any_bottles_left:
		var empty_label := Label.new()
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.add_theme_font_size_override("font_size", 16)
		empty_label.text = EMPTY_INVENTORY_TEXT
		empty_label.modulate = EMPTY_INVENTORY_COLOR
		beer_batch_list_vbox.add_child(empty_label)
