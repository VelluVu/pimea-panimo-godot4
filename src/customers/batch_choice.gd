class_name BatchChoice
extends RefCounted

## Which batches on tap a customer buys from: their taste first, and a batch that clears
## their quality bar always over one that does not.

## A batch good enough for the customer always beats one that is not, whatever the taste.
const QUALITY_BONUS_WEIGHT : float = 10.0


## The batch the customer would buy from, or null. A strict requirement makes a
## batch invisible to the customer, not just a worse option.
static func find_best_batch(batches : Array[BrewBatch], data : CustomerData) -> BrewBatch:
	var best_batch : BrewBatch = null
	var best_score : float = -1.0

	for batch : BrewBatch in batches:
		if not on_offer(batch, data):
			continue
		var score : float = data.get_batch_preference(batch)
		if SaleEvaluation.clears_bar(data, batch.current_quality):
			score += QUALITY_BONUS_WEIGHT
		if score > best_score:
			best_score = score
			best_batch = batch
	return best_batch


## The best batch, or for a picks_at_random customer up to `count` random batches of
## different styles that clear the bar. With none clearing it, the best batch, to refuse.
static func pick_batches(batches : Array[BrewBatch], data : CustomerData, count : int = 1) -> Array[BrewBatch]:
	var picks : Array[BrewBatch] = []
	if data.picks_at_random:
		var candidates : Array[BrewBatch] = []
		for batch : BrewBatch in batches:
			if on_offer(batch, data) and SaleEvaluation.clears_bar(data, batch.current_quality):
				candidates.append(batch)
		candidates.shuffle()
		var styles_taken : Array[BeerStyle.Style] = []
		for batch : BrewBatch in candidates:
			if picks.size() >= count:
				break
			if styles_taken.has(batch.beer_style.style):
				continue
			styles_taken.append(batch.beer_style.style)
			picks.append(batch)
	if picks.is_empty():
		var best : BrewBatch = find_best_batch(batches, data)
		if best != null:
			picks.append(best)
	return picks


static func on_offer(batch : BrewBatch, data : CustomerData) -> bool:
	return batch.amount_bottles > 0 and not batch.held and data.accepts_batch(batch)
