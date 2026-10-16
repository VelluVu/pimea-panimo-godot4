@tool
extends McpTestSuite

const BoilSessionScript := preload("res://src/brewing/brew_day/boil_session.gd")

const STEP : float = 1.0 / 60.0
const HOP_ID : int = 200
const AROMA_HOP_ID : int = 201
const SPICE_ID : int = 401


func suite_name() -> String:
	return "boil_session"


func _marks(list : Array) -> Array[BoilMark]:
	var marks : Array[BoilMark] = []
	for entry : Array in list:
		marks.append(BoilMark.new(entry[0], entry[1], entry[2]))
	return marks


## Keeps a rolling boil in the middle of the band.
func _hold_boil(session : BoilSession, seconds : float) -> void:
	var elapsed : float = 0.0
	while elapsed < seconds and session.phase != BoilSession.Phase.DONE:
		session.set_heating(session.heat.temperature < 99.5)
		session.step(STEP)
		elapsed += STEP


func _until_counted(session : BoilSession, at : float) -> void:
	while session.counted < at and session.phase != BoilSession.Phase.DONE:
		_hold_boil(session, STEP)


## Sacks are keyed by their mark's index.
func _pour(session : BoilSession, sack : int, seconds : float) -> void:
	session.start_pour(sack)
	_hold_boil(session, seconds)
	session.stop_pour(sack)


func test_the_clock_waits_for_the_boil() -> void:
	var session : BoilSession = BoilSessionScript.new(_marks([]))
	session.step(1.0)
	assert_eq(session.counted, 0.0)
	assert_eq(session.phase, BoilSession.Phase.RAMP)


func test_a_well_held_boil_with_no_marks_scores_high() -> void:
	var session : BoilSession = BoilSessionScript.new(_marks([]))
	_hold_boil(session, 30.0)
	assert_eq(session.phase, BoilSession.Phase.DONE)
	assert_eq(session.boil_overs, 0)
	assert_gt(session.score(), 0.8)


func test_the_hop_stand_takes_aroma_hops_after_the_boil() -> void:
	var session : BoilSession = BoilSessionScript.new(_marks([[HopAddition.Kind.AROMA, HOP_ID, 10]]))
	_until_counted(session, BoilSchedule.BOIL_SECONDS + 1.0)
	assert_eq(session.phase, BoilSession.Phase.HOP_STAND)
	session.set_heating(true)
	assert_false(session.heat.heating, "the flame is out")
	session.start_pour(0)
	for i : int in roundi(BoilSessionScript.POUR_SECONDS_AT_TARGET / STEP):
		session.step(STEP)
	session.stop_pour(0)
	assert_eq(session.marks[0].result, BoilMark.Result.FULL)
	assert_eq(session.phase, BoilSession.Phase.DONE, "every mark done ends the stand early")


func test_the_stand_ends_on_its_own_and_misses_what_is_left() -> void:
	var session : BoilSession = BoilSessionScript.new(_marks([[HopAddition.Kind.AROMA, HOP_ID, 10]]))
	_until_counted(session, BoilSchedule.BOIL_SECONDS + 0.1)
	for i : int in roundi(BoilSchedule.HOP_STAND_SECONDS / STEP) + 5:
		session.step(STEP)
	assert_eq(session.phase, BoilSession.Phase.DONE)
	assert_eq(session.marks[0].result, BoilMark.Result.MISS)


func test_full_heat_boils_over() -> void:
	var session : BoilSession = BoilSessionScript.new(_marks([]))
	session.set_heating(true)
	for i : int in 900:
		session.step(STEP)
	assert_gt(session.boil_overs, 0)


func test_a_timed_pour_of_the_right_amount_is_a_full_hit() -> void:
	var session : BoilSession = BoilSessionScript.new(_marks([[HopAddition.Kind.BITTERING, HOP_ID, 30]]))
	_until_counted(session, 0.1)
	_pour(session, 0, BoilSessionScript.POUR_SECONDS_AT_TARGET)
	assert_eq(session.marks[0].result, BoilMark.Result.FULL)


func test_a_bittering_hop_at_an_aroma_mark_is_at_best_half() -> void:
	var marks : Array[BoilMark] = _marks([[HopAddition.Kind.FLAVOR, HOP_ID, 30]])
	marks[0].bittering_only = true
	var session : BoilSession = BoilSessionScript.new(marks)
	_until_counted(session, BoilSchedule.time_for(HopAddition.Kind.FLAVOR) - 0.3)
	_pour(session, 0, BoilSessionScript.POUR_SECONDS_AT_TARGET)
	assert_eq(session.marks[0].result, BoilMark.Result.HALF)


func test_the_wrong_amount_is_half() -> void:
	var session : BoilSession = BoilSessionScript.new(_marks([[HopAddition.Kind.BITTERING, HOP_ID, 30]]))
	_until_counted(session, 0.1)
	_pour(session, 0, 0.3)
	assert_eq(session.marks[0].result, BoilMark.Result.HALF)


func test_a_mark_left_alone_is_missed() -> void:
	var session : BoilSession = BoilSessionScript.new(_marks([[HopAddition.Kind.FLAVOR, HOP_ID, 30]]))
	_hold_boil(session, 30.0)
	assert_eq(session.marks[0].result, BoilMark.Result.MISS)
	assert_true(session.score() <= 0.5)


func test_a_pour_far_from_any_mark_is_lost() -> void:
	var session : BoilSession = BoilSessionScript.new(_marks([[HopAddition.Kind.AROMA, HOP_ID, 30]]))
	var strays : Array = []
	session.stray_pour.connect(func(id : int) -> void: strays.append(id))
	_until_counted(session, 2.0)
	_pour(session, 0, 0.4)
	assert_eq(strays, [HOP_ID])
	assert_true(session.sacks[0] < 30.0)
	assert_eq(session.marks[0].result, BoilMark.Result.OPEN)


func test_the_wrong_sack_on_a_mark_is_half() -> void:
	var session : BoilSession = BoilSessionScript.new(_marks([[HopAddition.Kind.BITTERING, HOP_ID, 30], [HopAddition.Kind.AROMA, AROMA_HOP_ID, 10]]))
	_until_counted(session, 0.2)
	_pour(session, 1, 0.5)
	assert_eq(session.marks[0].result, BoilMark.Result.HALF)


func test_spices_go_in_with_one_tap() -> void:
	var piece_ids : Array[int] = [SPICE_ID]
	var session : BoilSession = BoilSessionScript.new(_marks([[HopAddition.Kind.SPICE, SPICE_ID, 2]]), piece_ids)
	_until_counted(session, BoilSchedule.time_for(HopAddition.Kind.SPICE))
	session.start_pour(0)
	assert_eq(session.marks[0].result, BoilMark.Result.FULL)
	assert_eq(session.sacks[0], 0.0)


func test_every_mark_hit_scores_high() -> void:
	var session : BoilSession = BoilSessionScript.new(_marks([[HopAddition.Kind.BITTERING, HOP_ID, 30], [HopAddition.Kind.AROMA, AROMA_HOP_ID, 10]]))
	_until_counted(session, 0.1)
	_pour(session, 0, BoilSessionScript.POUR_SECONDS_AT_TARGET)
	_until_counted(session, BoilSchedule.time_for(HopAddition.Kind.AROMA) - 0.5)
	_pour(session, 1, BoilSessionScript.POUR_SECONDS_AT_TARGET)
	_hold_boil(session, 5.0)
	assert_eq(session.phase, BoilSession.Phase.DONE)
	assert_gt(session.score(), 0.8)


func test_the_dry_hop_stays_out_of_the_boil() -> void:
	var session : BoilSession = BoilSessionScript.new(_marks([[HopAddition.Kind.DRY_HOP, HOP_ID, 30]]))
	assert_true(session.marks.is_empty())
	assert_true(session.sacks.is_empty())


func test_a_hop_on_two_marks_gets_a_sack_for_each() -> void:
	var session : BoilSession = BoilSessionScript.new(_marks([[HopAddition.Kind.FLAVOR, AROMA_HOP_ID, 12], [HopAddition.Kind.AROMA, AROMA_HOP_ID, 2]]))
	assert_eq(session.sacks, {0: 12.0, 1: 2.0})
	_until_counted(session, BoilSchedule.time_for(HopAddition.Kind.AROMA) - 0.3)
	# Pouring the small sack to the bottom is exactly its mark's grams.
	_pour(session, 1, BoilSessionScript.POUR_SECONDS_AT_TARGET * 3.0)
	assert_eq(session.sacks[1], 0.0)
	assert_eq(session.marks[1].result, BoilMark.Result.FULL)
	assert_eq(session.sacks[0], 12.0, "the other sack is untouched")


func test_a_same_hop_sack_stands_in_for_its_twin() -> void:
	var session : BoilSession = BoilSessionScript.new(_marks([[HopAddition.Kind.FLAVOR, AROMA_HOP_ID, 10], [HopAddition.Kind.AROMA, AROMA_HOP_ID, 10]]))
	_until_counted(session, BoilSchedule.time_for(HopAddition.Kind.AROMA) - 0.3)
	_pour(session, 0, BoilSessionScript.POUR_SECONDS_AT_TARGET)
	assert_eq(session.marks[1].result, BoilMark.Result.FULL, "the flavour sack still counts for the aroma mark")
