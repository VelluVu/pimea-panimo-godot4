class_name BeerPatchPanel
extends VBoxContainer


@onready var beer_batch_list_vbox : VBoxContainer = $BeerBatchScrollContainer/BeerBatchListVBox
## Name and stock sit on separate lines: on one clipped line the long style
## names pushed the bottle count past the ellipsis. The count never clips;
## the quality label next to it gives way instead.
const NAME_LABEL_STRING : String = "🍺 %s (%.1f%%)"
const AMOUNT_LABEL_STRING : String = "%d annosta"
const QUALITY_LABEL_STRING : String = "%s %s"
## Shown when there's nothing left to sell — without this the panel just
## goes quiet with no explanation. Customer traffic keeps arriving even
## now (CustomerSpawner no longer withholds spawning on empty inventory
## past the player's first brew — see its spawn_walk_in()
## docstring), it just gets turned away, costing reputation/risk, so this
## label is the only warning the player gets before that starts happening.
## See playtest_notes_2.txt.
const EMPTY_INVENTORY_TEXT : String = "Ei olutta myytävänä. Keitä lisää!"
const EMPTY_INVENTORY_COLOR : Color = Color(0.9490196, 0.7882353, 0.41960785, 1) # matches DailyGoalsPanel.GOAL_PENDING_COLOR

## Dumps the whole batch at once — see Brewery.BULK_SELL_RATE's docstring
## for why this is a "clear the warehouse" action, not a real sale.
## Short on purpose — RightWarehouseView's panel is only ~140px wide at
## this game's base resolution (640x360), with two action buttons now
## sharing each row alongside the batch label. Full context lives in the
## tooltip below instead of the button face.
const BULK_SELL_BUTTON_TEXT : String = "Myy"
## Hold toggle on each batch's name row, see BrewBatch.held.
const HELD_ICON : String = "🔒"
const RELEASED_ICON : String = "🔓"
const HOLD_BUTTON_TOOLTIP : String = "Kellaroi: lukittua erää ei myydä tiskillä, joten se ehtii vanheta. Kellarioluet maksavat kypsinä enemmän. Paina uudestaan vapauttaaksesi."
const BULK_SELL_BUTTON_TOOLTIP : String = "Myy koko erä kerralla varastosta. Hinta on paljon normaalia myyntihintaa halvempi, ja heikkolaatuinen tai vanhentunut erä voi tuottaa jopa tappiota raaka-ainekuluihin nähden."

const DESTINATION_LABEL_TEXT : String = "Kohde:"
const SHIP_BUTTON_TEXT : String = "Vie"
## Finger-sized row buttons and destination dropdown.
const ROW_BUTTON_SIZE : Vector2 = Vector2(40, 24)
const SHIP_BUTTON_TOOLTIP : String = "Vie koko erä yllä valittuun baariin. Parempi hinta kuin halpamyynti, mutta nostaa LVV-riskiä toimituksen mukana."

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
	_bar_contact_option_button.custom_minimum_size.y = ROW_BUTTON_SIZE.y
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

			var name_label := _make_batch_label(batch)
			name_label.text = NAME_LABEL_STRING % [batch.get_style_name(), batch.beer_style.abv]

			if batch.beer_style.style == BeerStyle.Style.KOTIKALJA:
				name_label.modulate = Color.DARK_GRAY
			elif batch.beer_style.style == BeerStyle.Style.IPA:
				name_label.modulate = Color.GOLD

			var amount_label := _make_batch_label(batch)
			amount_label.clip_text = false
			amount_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
			amount_label.size_flags_horizontal = Control.SIZE_FILL
			amount_label.custom_minimum_size = Vector2.ZERO
			amount_label.text = tr(AMOUNT_LABEL_STRING) % batch.amount_bottles

			var quality_label := _make_batch_label(batch)
			quality_label.custom_minimum_size = Vector2.ZERO
			quality_label.modulate = Color(1, 1, 1, 0.7)
			quality_label.text = QUALITY_LABEL_STRING % [
				batch.get_quality_tier_string(),
				batch.get_aging_trend_icon()
			]

			var bulk_sell_button := TooltipButton.new()
			bulk_sell_button.text = BULK_SELL_BUTTON_TEXT
			bulk_sell_button.tooltip_text = BULK_SELL_BUTTON_TOOLTIP
			bulk_sell_button.custom_minimum_size = ROW_BUTTON_SIZE
			bulk_sell_button.pressed.connect(func(): GUISignals.bulk_sell_batch_requested.emit(batch))

			var ship_button := TooltipButton.new()
			ship_button.text = SHIP_BUTTON_TEXT
			ship_button.tooltip_text = SHIP_BUTTON_TOOLTIP
			ship_button.custom_minimum_size = ROW_BUTTON_SIZE
			ship_button.pressed.connect(func():
				var bar : BarContact = _bar_contact_option_button.get_selected_bar()
				if bar != null:
					GUISignals.ship_batch_to_bar_requested.emit(batch, bar)
			)

			var action_row := HBoxContainer.new()
			action_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
			action_row.add_child(amount_label)
			action_row.add_child(quality_label)
			action_row.add_child(bulk_sell_button)
			action_row.add_child(ship_button)

			var hold_button := TooltipButton.new()
			hold_button.text = HELD_ICON if batch.held else RELEASED_ICON
			hold_button.tooltip_text = HOLD_BUTTON_TOOLTIP
			hold_button.flat = true
			hold_button.custom_minimum_size = ROW_BUTTON_SIZE
			hold_button.pressed.connect(func(): GUISignals.batch_hold_toggled.emit(batch))
			var name_row := HBoxContainer.new()
			name_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
			name_row.add_child(name_label)
			name_row.add_child(hold_button)

			var batch_box := VBoxContainer.new()
			batch_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
			batch_box.add_theme_constant_override("separation", 2)
			batch_box.add_child(name_row)
			batch_box.add_child(action_row)
			beer_batch_list_vbox.add_child(batch_box)

	if not any_bottles_left:
		var empty_label := Label.new()
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.add_theme_font_size_override("font_size", 16)
		empty_label.text = EMPTY_INVENTORY_TEXT
		empty_label.modulate = EMPTY_INVENTORY_COLOR
		beer_batch_list_vbox.add_child(empty_label)


func _make_batch_label(batch: BrewBatch) -> TooltipLabel:
	var label := TooltipLabel.new()
	label.mouse_filter = Control.MOUSE_FILTER_STOP
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.custom_minimum_size = Vector2(ROW_LABEL_MIN_WIDTH, 0)
	label.add_theme_font_size_override("font_size", 16)
	label.tooltip_text = batch.get_full_info_tooltip() + QualityWishText.too_weak_line(batch.current_quality, _possible_buyers(batch))
	return label


## Customers who can walk in now and would consider this batch's style at all, so the
## quality hint never names someone who would not buy it anyway (Zgen and a lager).
func _possible_buyers(batch : BrewBatch) -> Array[CustomerData]:
	var buyers : Array[CustomerData] = []
	for customer : CustomerData in CustomerRegistry.get_eligible_customers():
		if customer.meets_strict_requirements(batch.beer_style):
			buyers.append(customer)
	return buyers
