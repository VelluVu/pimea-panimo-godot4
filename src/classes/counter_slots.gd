class_name CounterSlots
extends RefCounted

## Which counter positions are taken, and by whom. A group visit registers every
## member against one shared slot, so a slot counts its occupants and is only
## freed when the last one leaves.

var _occupied : Array[bool] = []
var _occupant_counts : Array[int] = []
## Slot -> the most recently registered customer standing there.
var _customers : Dictionary = {}


func _init(slot_count : int) -> void:
	reset(slot_count)


## Frees every slot and resizes to `slot_count`.
func reset(slot_count : int) -> void:
	_occupied.clear()
	_occupant_counts.clear()
	_customers.clear()
	for i : int in range(slot_count):
		_occupied.append(false)
		_occupant_counts.append(0)


func size() -> int:
	return _occupied.size()


## The lowest free slot, or -1 when the counter is full.
func first_free() -> int:
	for i : int in range(_occupied.size()):
		if not _occupied[i]:
			return i
	return -1


func register(slot : int, customer : Node2D) -> void:
	_occupied[slot] = true
	_occupant_counts[slot] += 1
	_customers[slot] = customer


func release(slot : int) -> void:
	_occupant_counts[slot] = maxi(0, _occupant_counts[slot] - 1)
	if _occupant_counts[slot] > 0:
		return

	_customers.erase(slot)
	_occupied[slot] = false


func has_customers() -> bool:
	return not _customers.is_empty()


## One registered customer per occupied slot (freed nodes included).
func customers() -> Array:
	return _customers.values()
