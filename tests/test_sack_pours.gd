@tool
extends McpTestSuite

## Unit tests for SackPours: carrying sacks over the kettle and the pellets they pour.

const PoursScript := preload("res://src/ui/brew_day/sack_pours.gd")

const STEP : float = 1.0 / 60.0
const HOP : int = 200

var _landed : Array[Vector2] = []


func suite_name() -> String:
	return "sack_pours"


func _pours() -> SackPours:
	_landed.clear()
	var pours : SackPours = PoursScript.new()
	pours.landed.connect(func(at : Vector2, _color : Color, _blooms : bool) -> void: _landed.append(at))
	return pours


func _run(pours : SackPours, seconds : float) -> void:
	var t : float = 0.0
	while t < seconds:
		pours.step(STEP)
		t += STEP


func test_a_key_lifted_sack_hangs_over_the_mouth() -> void:
	var pours := _pours()
	pours.carry(HOP, Color.GREEN, false, true, Vector2.ZERO)
	assert_true(pours.is_carrying(HOP))
	assert_true(pours.is_over_mouth(HOP))
	pours.drop(HOP)
	assert_false(pours.is_carrying(HOP))
	assert_false(pours.is_over_mouth(HOP))


func test_a_carried_sack_lags_behind_the_pointer_and_pours_only_over_the_mouth() -> void:
	var pours := _pours()
	var aside := Vector2(-300, 300)
	pours.carry(HOP, Color.GREEN, true, true, aside)
	assert_false(pours.is_over_mouth(HOP))
	pours.set_target(HOP, KettleView.LIQUID_RECT.get_center() - Vector2(0, 40))
	pours.step(STEP)
	assert_false(pours.is_over_mouth(HOP), "one frame is not enough to get there")
	_run(pours, 1.0)
	assert_true(pours.is_over_mouth(HOP))


func test_pellets_fall_into_the_liquid_and_report_their_landing() -> void:
	var pours := _pours()
	pours.carry(HOP, Color.GREEN, false, true, Vector2.ZERO)
	pours.set_pouring(HOP, true)
	_run(pours, 1.0)
	assert_true(_landed.size() > 10, "landed %d" % _landed.size())
	var liquid : Rect2 = KettleView.LIQUID_RECT
	for at : Vector2 in _landed:
		assert_true(at.y >= liquid.position.y + SackPours.LANDING_DEPTH.x)
	pours.set_pouring(HOP, false)
	_run(pours, 1.0)
	assert_eq(pours.pellet_count(), 0, "a stopped pour leaves nothing in the air")


func test_a_handful_tips_in_at_once() -> void:
	var pours := _pours()
	pours.carry(HOP, Color.ORANGE, false, true, Vector2.ZERO)
	pours.drop_handful(HOP, 12)
	assert_eq(pours.pellet_count(), 12)


func test_shaking_starts_above_a_speed_and_saturates() -> void:
	assert_eq(SackPours.shake(Vector2.ZERO), 0.0)
	assert_eq(SackPours.shake(Vector2(SackPours.SHAKE_FROM, 0)), 0.0)
	assert_eq(SackPours.shake(Vector2(SackPours.SHAKE_FROM + SackPours.SHAKE_RANGE * 2.0, 0)), 1.0)
