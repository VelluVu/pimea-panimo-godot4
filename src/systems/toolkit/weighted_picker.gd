class_name WeightedPicker
extends RefCounted

## Weighted random choice.


## One of `items` by its weight (same length); a non-positive total picks uniformly. `roll`
## is injectable for tests.
static func pick(items: Array, weights: Array[float], roll: float = randf()) -> Variant:
	if items.is_empty():
		return null

	var total_weight: float = 0.0
	for weight: float in weights:
		total_weight += weight
	if total_weight <= 0.0:
		return items.pick_random()

	var target: float = roll * total_weight
	var cumulative: float = 0.0
	for i in range(items.size()):
		cumulative += weights[i]
		if target < cumulative:
			return items[i]
	return items.back()
