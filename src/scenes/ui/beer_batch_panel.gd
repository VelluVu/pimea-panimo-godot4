class_name BeerPatchPanel
extends VBoxContainer


@onready var beer_batch_list_vbox : VBoxContainer = $BeerBatchScrollContainer/BeerBatchListVBox
## Name and stock on separate lines, so a long style name never hides the count.
const NAME_LABEL_STRING : String = "🍺 %s (%s%%)"
## A batch soured by a dirty keg, by how badly, see BrewBatch.get_sour_level().
const LIGHT_SOUR_LABEL_FORMAT : String = "Vähän hapan %s"
const SOUR_LABEL_FORMAT : String = "Hapan %s"
const STRONG_SOUR_LABEL_FORMAT : String = "Pilalla: %s"
## A brew still fermenting, see Fermenter. Shown above the kegs.
const FERMENTING_LABEL_FORMAT : String = "⏳ %s käymässä, %d s"
const FERMENTING_TOOLTIP : String = "Erä käy. Kun se on valmis, se menee puhtaimpaan tyhjään tynnyriin. Likainen tynnyri voi hapattaa sen."
## A novelty batch's label, see FirstBrewRules.
const NOVELTY_LABEL_FORMAT : String = "Uutuus! %s"
const AMOUNT_LABEL_STRING : String = "%d annosta"
## A full keg waiting for a free tap, see Inventory.batches_on_serve().
const SPARE_AMOUNT_FORMAT : String = "%d annosta, varalla"
const QUALITY_LABEL_STRING : String = "%s %s"
## Nothing to sell: customers still come and get turned away, so this is the warning.
const EMPTY_INVENTORY_TEXT : String = "Ei olutta myytävänä. Keitä lisää!"
const EMPTY_INVENTORY_COLOR : Color = Color(0.9490196, 0.7882353, 0.41960785, 1) # matches DailyGoalsPanel.GOAL_PENDING_COLOR

## Hold toggle on each batch's name row, see BrewBatch.held.
const HELD_ICON : String = "🔒"
const RELEASED_ICON : String = "🔓"
const HOLD_BUTTON_TOOLTIP : String = "Kellaroi: lukittua erää ei myydä tiskillä, joten se ehtii vanheta. Kellarioluet maksavat kypsinä enemmän. Paina uudestaan vapauttaaksesi."

const DESTINATION_LABEL_TEXT : String = "Kohde:"
const SHIP_BUTTON_TEXT : String = "Vie"
## Finger-sized row buttons and destination dropdown.
const ROW_BUTTON_SIZE : Vector2 = Vector2(40, 24)
const SHIP_BUTTON_TOOLTIP : String = "Vie koko erä yllä valittuun baariin. Nostaa LVV-riskiä toimituksen mukana."

## Floor under the row label's width: a near-zero width mid-layout makes word wrap blow
## the row up to hundreds of pixels. The full stats stay in the tooltip.
const ROW_LABEL_MIN_WIDTH : float = 50.0

## One shared bar picker above the batch list, built in code like the rows.
var _bar_contact_option_button : BarContactOptionButton = null
var _keg_count_label : TooltipLabel = null
## Fermenting batch -> its row label, updated each tick without a rebuild so a tooltip stays.
var _fermenting_labels : Dictionary = {}


func _ready() -> void:
	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)
	BrewerySignals.fermentation_ticked.connect(_on_fermentation_ticked)

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

	_keg_count_label = TooltipLabel.new()
	_keg_count_label.tooltip_text = KegCountText.TOOLTIP_TEXT
	_keg_count_label.mouse_filter = Control.MOUSE_FILTER_PASS
	_keg_count_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_keg_count_label)
	move_child(_keg_count_label, 0)

	_update_beer_batches_ui()


func _on_brewery_state_changed(_brewery: Brewery) -> void:
	_update_beer_batches_ui()


func _on_fermentation_ticked() -> void:
	for batch : BrewBatch in _fermenting_labels:
		(_fermenting_labels[batch] as Label).text = _fermenting_text(batch)


func _fermenting_text(batch : BrewBatch) -> String:
	return tr(FERMENTING_LABEL_FORMAT) % [batch.get_style_name(), ceili(batch.ferment_seconds_left)]


func _update_beer_batches_ui() -> void:
	for child in beer_batch_list_vbox.get_children():
		child.queue_free()
	_fermenting_labels.clear()
		
	if BrewEngine.current_brewery == null: 
		return
		
	var inventory : Inventory = BrewEngine.current_brewery.inventory
	var any_bottles_left : bool = false
	_keg_count_label.text = KegCountText.line(KegRules.tap_count(inventory.total_kegs()), inventory.kegs_in_use(), inventory.total_kegs(), inventory.dirty_keg_count())
	var on_tap : Array[BrewBatch] = inventory.batches_on_serve()

	for batch : BrewBatch in inventory.fermenting:
		var fermenting_label := TooltipLabel.new()
		fermenting_label.mouse_filter = Control.MOUSE_FILTER_STOP
		fermenting_label.clip_text = true
		fermenting_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		fermenting_label.add_theme_font_size_override("font_size", 16)
		fermenting_label.modulate = Color(1, 1, 1, 0.7)
		fermenting_label.tooltip_text = FERMENTING_TOOLTIP
		fermenting_label.text = _fermenting_text(batch)
		_fermenting_labels[batch] = fermenting_label
		beer_batch_list_vbox.add_child(fermenting_label)

	for batch: BrewBatch in inventory.brew_batches:

		if batch.amount_bottles > 0:
			any_bottles_left = true

			var name_label := _make_batch_label(batch)
			name_label.text = NAME_LABEL_STRING % [batch.get_style_name(), NumberText.decimal(batch.get_abv(), 1)]
			match batch.get_sour_level():
				FermentationRules.SourLevel.LIGHT:
					name_label.text = tr(LIGHT_SOUR_LABEL_FORMAT) % name_label.text
				FermentationRules.SourLevel.CLEAR:
					name_label.text = tr(SOUR_LABEL_FORMAT) % name_label.text
				FermentationRules.SourLevel.STRONG:
					name_label.text = tr(STRONG_SOUR_LABEL_FORMAT) % name_label.text
			if batch.novelty:
				name_label.text = tr(NOVELTY_LABEL_FORMAT) % name_label.text

			if batch.beer_style.style == BeerStyle.Style.KOTIKALJA:
				name_label.modulate = Color.DARK_GRAY
			elif batch.beer_style.style == BeerStyle.Style.IPA:
				name_label.modulate = Color.GOLD

			var amount_label := _make_batch_label(batch)
			amount_label.clip_text = false
			amount_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
			amount_label.size_flags_horizontal = Control.SIZE_FILL
			amount_label.custom_minimum_size = Vector2.ZERO
			var waiting : bool = not batch.held and not on_tap.has(batch)
			amount_label.text = tr(SPARE_AMOUNT_FORMAT if waiting else AMOUNT_LABEL_STRING) % batch.amount_bottles

			var quality_label := _make_batch_label(batch)
			quality_label.custom_minimum_size = Vector2.ZERO
			quality_label.modulate = Color(1, 1, 1, 0.7)
			quality_label.text = QUALITY_LABEL_STRING % [
				batch.get_quality_tier_string(),
				batch.get_aging_trend_icon()
			]

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


## Customers who can walk in now and would buy this style at all, so the quality hint never
## names someone who would not buy it anyway.
func _possible_buyers(batch : BrewBatch) -> Array[CustomerData]:
	var buyers : Array[CustomerData] = []
	for customer : CustomerData in CustomerRegistry.get_eligible_customers():
		if customer.accepts_batch(batch):
			buyers.append(customer)
	return buyers
