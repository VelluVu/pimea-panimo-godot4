class_name GroupVisit
extends RefCounted

## The running state of one crowd visit, shared by the stages of GroupVisitDirector and
## kept explicit so snapshot() can freeze it for a save.

## In order; the sale happens between ORDERING and SERVING, in one frame.
enum Stage { SPAWNING, CHANTING, ORDERING, SERVING, TALKING, DISMISSING, DONE }

var event_data : GroupVisitEventData
## Counter slot the crowd was sent to.
var slot : int
## Shared by every member, so evicting any of them clears the group's bubble.
var dialogue_slot : int
var counter_position : Vector2
## In walk-in order; index 0 is the representative. Members can be freed mid-visit, so
## check is_instance_valid() before use.
var members : Array = []

var stage : Stage = Stage.SPAWNING
var group_size : int = 0
var chant_index : int = 0
var order_data : CustomerData
var response_text : String = ""
var purchased : bool = false
var beer_ebc : int = -1
var bar_fight_bottles : int = -1
## Members poured for so far, and the glasses that went on the counter.
var served : int = 0
var glasses_out : int = 0
## The sale's popups wait for the round to be poured; null once shown.
var outcome : SaleOutcomeCapture
## The current wait, read for the save.
var timer : SceneTreeTimer

var bubble_text : String = ""
var bubble_position : Vector2 = Vector2.ZERO
var bubble_fade : float = 0.0
var bubble_timer : SceneTreeTimer


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
	purchased = true
	for member : Variant in members:
		if is_instance_valid(member):
			member.made_purchase = true


func snapshot() -> GroupVisitSnapshot:
	var snap := GroupVisitSnapshot.new()
	snap.event_data = event_data
	snap.slot = slot
	snap.counter_position = counter_position
	snap.stage = stage
	snap.time_left = timer.time_left if timer != null else 0.0
	snap.group_size = group_size
	snap.chant_index = chant_index
	snap.order_data = order_data
	snap.response_text = response_text
	snap.purchased = purchased
	snap.beer_ebc = beer_ebc
	snap.bar_fight_bottles = bar_fight_bottles
	snap.served = served
	snap.glasses_out = glasses_out
	if outcome != null:
		snap.popups_pending = true
		snap.popup_reputation = outcome.reputation
		snap.popup_income = outcome.income
		snap.popup_tip = outcome.tip
		snap.popup_tip_tier = outcome.tip_tier
		snap.popup_beer_quality = outcome.beer_quality
		for note : SaleOutcomeCapture.Note in outcome.notes:
			snap.popup_notes.append(note)
	snap.bubble_text = bubble_text
	snap.bubble_position = bubble_position
	snap.bubble_fade = bubble_fade
	snap.bubble_time_left = bubble_timer.time_left if bubble_timer != null else 0.0
	for member : Variant in members:
		var here : bool = is_instance_valid(member) and not member.is_queued_for_deletion()
		snap.members.append(member.snapshot() if here else null)
	return snap


## Takes the stage and progress back from a save; the members are rebuilt by the director.
func restore(snap : GroupVisitSnapshot) -> void:
	stage = snap.stage
	group_size = snap.group_size
	chant_index = snap.chant_index
	order_data = snap.order_data
	response_text = snap.response_text
	purchased = snap.purchased
	beer_ebc = snap.beer_ebc
	bar_fight_bottles = snap.bar_fight_bottles
	served = snap.served
	glasses_out = snap.glasses_out
	if snap.popups_pending:
		outcome = SaleOutcomeCapture.new()
		outcome.reputation = snap.popup_reputation
		outcome.income = snap.popup_income
		outcome.tip = snap.popup_tip
		outcome.tip_tier = snap.popup_tip_tier
		outcome.beer_quality = snap.popup_beer_quality
		for note : int in snap.popup_notes:
			outcome.notes.append(note as SaleOutcomeCapture.Note)
