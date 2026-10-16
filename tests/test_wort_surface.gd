@tool
extends McpTestSuite

## Unit tests for WortSurface: the paddle's swirl and the hops' blooms.

const SurfaceScript := preload("res://src/ui/brew_day/wort_surface.gd")

const STEP : float = 1.0 / 60.0


func suite_name() -> String:
	return "wort_surface"


func _middle() -> Vector2:
	return KettleView.LIQUID_RECT.get_center()


## Circles the blade around the middle at half the mouth's size, `turns` times a second.
func _circle(surface : WortSurface, seconds : float, turns : float) -> void:
	var radius : Vector2 = KettleView.LIQUID_RECT.size / 4.0
	var t : float = 0.0
	while t < seconds:
		t += STEP
		var angle : float = TAU * turns * t
		surface.stir(_middle() + Vector2(cos(angle), sin(angle)) * radius, true, false, STEP)


func test_circling_clockwise_turns_the_wort_clockwise() -> void:
	var surface : WortSurface = SurfaceScript.new(_middle() + Vector2(KettleView.LIQUID_RECT.size.x / 4.0, 0))
	_circle(surface, 1.0, 0.5)
	assert_true(surface.swirl > 0.5, "swirl %f" % surface.swirl)
	var other : WortSurface = SurfaceScript.new(_middle() + Vector2(KettleView.LIQUID_RECT.size.x / 4.0, 0))
	_circle(other, 1.0, -0.5)
	assert_true(other.swirl < -0.5)


func test_the_swirl_never_passes_its_cap() -> void:
	var surface : WortSurface = SurfaceScript.new(_middle() + Vector2(KettleView.LIQUID_RECT.size.x / 4.0, 0))
	_circle(surface, 2.0, 5.0)
	assert_true(surface.swirl <= WortSurface.MAX_SWIRL)


func test_a_free_swirl_slows_down_but_a_rolling_boil_keeps_it_turning() -> void:
	var surface : WortSurface = SurfaceScript.new(_middle())
	surface.swirl = 2.0
	for i : int in 600:
		surface.stir(_middle(), false, false, STEP)
	assert_true(surface.swirl < 0.5, "drag slows it")
	var boiling : WortSurface = SurfaceScript.new(_middle())
	for i : int in 600:
		boiling.stir(_middle(), false, true, STEP)
	assert_true(is_equal_approx(boiling.swirl, WortSurface.BOIL_SWIRL), "boil swirl %f" % boiling.swirl)


func test_blooms_only_near_the_middle_but_every_hop_tints() -> void:
	var surface : WortSurface = SurfaceScript.new(_middle())
	assert_true(surface.land(_middle(), Color.GREEN, true))
	assert_eq(surface.bloom_count(), 1)
	var edge : Vector2 = _middle() + Vector2(KettleView.LIQUID_RECT.size.x * 0.45, 0)
	assert_true(surface.land(edge, Color.GREEN, true), "an edge hop still tints")
	assert_eq(surface.bloom_count(), 1)
	assert_false(surface.land(_middle(), Color.BROWN, false), "malt only splashes")
	assert_eq(surface.bloom_count(), 1)


func test_blooms_are_capped_and_fade_out() -> void:
	var surface : WortSurface = SurfaceScript.new(_middle())
	for i : int in WortSurface.MAX_BLOOMS + 5:
		surface.land(_middle(), Color.GREEN, true)
	assert_eq(surface.bloom_count(), WortSurface.MAX_BLOOMS)
	surface.step(WortSurface.BLOOM_SECONDS + 0.1)
	assert_eq(surface.bloom_count(), 0)
