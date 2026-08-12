class_name BeerPatchPanel
extends VBoxContainer


@onready var beer_batch_list_vbox : VBoxContainer = $BeerBatchScrollContainer/BeerBatchListVBox


func _ready() -> void:
	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)
	_update_beer_batches_ui()


func _on_brewery_state_changed(_brewery: Brewery) -> void:
	_update_beer_batches_ui()


func _update_beer_batches_ui() -> void:
	# 1. Siivotaan vanhat tekstirivit solmusta pois, etteivät ne monistu ruudulle
	for child in beer_batch_list_vbox.get_children():
		child.queue_free()
		
	# Varmistetaan, että peli on käynnissä ja panimo olemassa
	if BrewEngine.current_brewery == null: 
		return
		
	var inventory : Inventory = BrewEngine.current_brewery.inventory
	
	# 2. Loopataan läpi kaikki kellarissa (taulukossa) odottavat valmiit erät!
	# (Käytetään juuri luomaasi BrewBatch-luokkaa)
	for batch: BrewBatch in inventory.brew_batches:
		
		# Piirretään rivi vain, jos erässä on vielä pulloja jäljellä myytäväksi
		if batch.amount_bottles > 0:
			
			# Luodaan uusi siisti Label-solmu oluterälle
			var row_label := Label.new()
			
			# Haetaan suomenkielinen tyylinimi ja muotoillaan teksti dynaamisesti
			# Esimerkki: "🍺 IPA (Laatu: 1.0) - 40 pulloa"
			row_label.text = "🍺 %s (Laatu: %s) - %s pulloa" % [
				batch.get_style_name(), 
				str(batch.quality_multiplier), 
				str(batch.amount_bottles)
			]
			
			# Visuaalinen hifistely teeman mukaan: 
			# Jos kyseessä on huonolaatuinen rankki/kotikalja, värjätään se harmaammaksi,
			# ja onnistuneet hifistely-IPA:t loistavat kultaisina!
			if batch.style == BrewResult.BeerStyle.KOTIKALJA:
				row_label.modulate = Color.DARK_GRAY
			elif batch.style == BrewResult.BeerStyle.IPA:
				row_label.modulate = Color.GOLD
				
			# Laitetaan uusi erärivi dynaamiseen kellarilistaasi!
			beer_batch_list_vbox.add_child(row_label)
