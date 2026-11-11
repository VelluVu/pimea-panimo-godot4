class_name HonourRules
extends RefCounted

## A customer who honours the cellar (Ritari knights the brewer) does it once a run, when
## his favourite style is sold to him at or above CustomerData.honour_min_quality.


## `best_quality`: the best favourite-style batch sold in this visit, or below 0 for none.
static func earns(min_quality: float, best_quality: float, already_honoured: bool) -> bool:
	if min_quality < 0.0 or already_honoured:
		return false
	return best_quality >= min_quality
