class_name Fermenter
extends RefCounted

## Runs the brewery's fermentations: TimeManager ticks them, and each finished batch goes
## into the cleanest empty keg, where a dirty keg may sour it. See FermentationRules.

var brewery : Brewery


func _init(owner : Brewery) -> void:
	brewery = owner


## A brew that needs no time (the run's first) is stored at once.
func start(batch : BrewBatch, seconds : float) -> void:
	batch.ferment_seconds_left = seconds
	brewery.inventory.start_fermenting(batch)
	if FermentationRules.is_done(seconds):
		_finish(batch)
		return
	BrewerySignals.fermentation_started.emit(batch.beer_style.style_name)


func tick(elapsed : float) -> void:
	if brewery.inventory.fermenting.is_empty():
		return
	for batch : BrewBatch in brewery.inventory.fermenting.duplicate():
		batch.ferment_seconds_left = FermentationRules.remaining(batch.ferment_seconds_left, elapsed)
		if FermentationRules.is_done(batch.ferment_seconds_left):
			_finish(batch)
	BrewerySignals.fermentation_ticked.emit()


## The day ends: whatever is still fermenting is ready for the next morning.
func finish_all() -> void:
	for batch : BrewBatch in brewery.inventory.fermenting.duplicate():
		_finish(batch)


func _finish(batch : BrewBatch) -> void:
	batch.ferment_seconds_left = 0.0
	brewery.inventory.finish_fermenting(batch)
	var chance : float = FermentationRules.infection_chance(batch.keg_cleanliness, brewery.stats.chance(PerkStats.INFECTION_REDUCTION))
	if chance > 0.0 and randf() < chance:
		batch.sour()
	BrewerySignals.batch_fermented.emit(batch)
	BrewerySignals.batch_stored.emit(batch.beer_style.style_name, batch.amount_bottles)
	BrewerySignals.brewery_state_changed.emit(brewery)
