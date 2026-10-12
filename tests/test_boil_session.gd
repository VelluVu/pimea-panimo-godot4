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


func _pour(session : BoilSession, id : int, seconds : float) -> void:
	session.start_pour(id)
	_hold_boil(session, seconds)
	session.stop_pour(id)


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


func test_full_heat_boils_over() -> void:
	var session : BoilSession = BoilSessionScript.new(_marks([]))
	session.set_heating(true)
	for i : int in 900:
		session.step(STEP)
	assert_gt(session.boil_overs, 0)


func test_a_timed_pour_of_the_right_amount_is_a_full_hit() -> void:
	var session : BoilSession = BoilSessionScript.new(_marks([[HopAddition.Kind.BITTERING, HOP_ID, 30]]))
	_until_counted(session, 0.1)
	_pour(session, HOP_ID, BoilSessionScript.POUR_SECONDS_AT_TARGET)
	assert_eq(session.marks[0].result, BoilMark.Result.FULL)


func test_the_wrong_amount_is_half() -> void:
	var session : BoilSession = BoilSessionScript.new(_marks([[HopAddition.Kind.BITTERING, HOP_ID, 30]]))
	_until_counted(session, 0.1)
	_pour(session, HOP_ID, 0.3)
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
	_pour(session, HOP_ID, 0.4)
	assert_eq(strays, [HOP_ID])
	assert_true(session.sacks[HOP_ID] < 30.0)
	assert_eq(session.marks[0].result, BoilMark.Result.OPEN)


func test_the_wrong_sack_on_a_mark_is_half() -> void:
	var session : BoilSession = BoilSessionScript.new(_marks([[HopAddition.Kind.BITTERING, HOP_ID, 30], [HopAddition.Kind.AROMA, AROMA_HOP_ID, 10]]))
	_until_counted(session, 0.2)
	_pour(session, AROMA_HOP_ID, 0.5)
	assert_eq(session.marks[0].result, BoilMark.Result.HALF)


func test_spices_go_in_with_one_tap() -> void:
	var piece_ids : Array[int] = [SPICE_ID]
	var session : BoilSession = BoilSessionScript.new(_marks([[HopAddition.Kind.SPICE, SPICE_ID, 2]]), piece_ids)
	_until_counted(session, BoilSchedule.time_for(HopAddition.Kind.SPICE))
	session.start_pour(SPICE_ID)
	assert_eq(session.marks[0].result, BoilMark.Result.FULL)
	assert_eq(session.sacks[SPICE_ID], 0.0)


func test_every_mark_hit_scores_high() -> void:
	var session : BoilSession = BoilSessionScript.new(_marks([[HopAddition.Kind.BITTERING, HOP_ID, 30], [HopAddition.Kind.AROMA, AROMA_HOP_ID, 10]]))
	_until_counted(session, 0.1)
	_pour(session, HOP_ID, BoilSessionScript.POUR_SECONDS_AT_TARGET)
	_until_counted(session, BoilSchedule.time_for(HopAddition.Kind.AROMA) - 0.5)
	_pour(session, AROMA_HOP_ID, BoilSessionScript.POUR_SECONDS_AT_TARGET)
	_hold_boil(session, 5.0)
	assert_eq(session.phase, BoilSession.Phase.DONE)
	assert_gt(session.score(), 0.8)


func test_the_dry_hop_stays_out_of_the_boil() -> void:
	var session : BoilSession = BoilSessionScript.new(_marks([[HopAddition.Kind.DRY_HOP, HOP_ID, 30]]))
	assert_true(session.marks.is_empty())
	assert_false(session.sacks.has(HOP_ID))
