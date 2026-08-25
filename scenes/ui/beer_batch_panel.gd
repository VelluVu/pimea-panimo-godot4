class_name BeerPatchPanel
extends VBoxContainer


@onready var beer_batch_list_vbox : VBoxContainer = $BeerBatchScrollContainer/BeerBatchListVBox


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
	
	for batch: BrewBatch in inventory.brew_batches:
		
		if batch.amount_bottles > 0:
			
			var row_label := Label.new()
			
			row_label.text = "🍺 %s (Laatu: %s) - %s pulloa - ebc %s - ibu %s" % [
				batch.get_style_name(), 
				str(batch.current_quality), 
				str(batch.amount_bottles),
				str(batch.final_ebc),
				str(batch.final_ibu)
			]
			
			if batch.beer_style.style == BeerStyle.Style.KOTIKALJA:
				row_label.modulate = Color.DARK_GRAY
			elif batch.beer_style.style == BeerStyle.Style.IPA:
				row_label.modulate = Color.GOLD
				
			beer_batch_list_vbox.add_child(row_label)
