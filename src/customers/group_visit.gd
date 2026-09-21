class_name GroupVisit
extends RefCounted

## The running state of one crowd visit, shared by the phases of GroupVisitDirector.

var event_data : GroupVisitEventData
## Counter slot the crowd was sent to.
var slot : int
## Speech-bubble slot shared by every member, so evicting any of them clears the group's bubble.
var dialogue_slot : int
var counter_position : Vector2
## Every member spawned, in walk-in order; index 0 is the order-place representative. A
## member can be freed mid-visit (eviction), so check is_instance_valid() before use.
var members : Array = []


func _init(data : GroupVisitEventData, counter_slot : int, bubble_slot : int, position : Vector2) -> void:
	event_data = data
	slot = counter_slot
	dialogue_slot = bubble_slot
	counter_position = position


func size() -> int:
	return members.size()


func has_anyone_here() -> bool:
	for member : Variant in members:
		if is_instance_valid(member):
			return true
	return false


func mark_purchased() -> void:
	for member : Variant in members:
		if is_instance_valid(member):
			member.made_purchase = true
