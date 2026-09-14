class_name BeerPatchPanel
extends VBoxContainer


@onready var beer_batch_list_vbox : VBoxContainer = $BeerBatchScrollContainer/BeerBatchListVBox
const LABEL_STRING : String = "🍺 %s (%.1f%%) - %s pulloa (%s %s)"
## Shown when there's nothing left to sell — without this the panel just
## goes quiet with no explanation. Customer traffic keeps arriving even
## now (CustomerSpawner no longer withholds spawning on empty inventory
## past the player's first brew — see its _on_walk_in_timer_timeout()
## docstring), it just gets turned away, costing reputation/risk, so this
## label is the only warning the player gets before that starts happening.
## See playtest_notes_2.txt.
const EMPTY_INVENTORY_TEXT : String = "Ei olutta myytävänä — keitä lisää!"
const EMPTY_INVENTORY_COLOR : Color = Color(0.9490196, 0.7882353, 0.41960785, 1) # matches DailyGoalsPanel.GOAL_PENDING_COLOR


func _ready() -> void:
	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)
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
			row_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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

			beer_batch_list_vbox.add_child(row_label)

	if not any_bottles_left:
		var empty_label := Label.new()
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.add_theme_font_size_override("font_size", 16)
		empty_label.text = EMPTY_INVENTORY_TEXT
		empty_label.modulate = EMPTY_INVENTORY_COLOR
		beer_batch_list_vbox.add_child(empty_label)
