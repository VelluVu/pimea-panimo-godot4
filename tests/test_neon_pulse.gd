@tool
extends McpTestSuite

## NeonPulse: the Cyber Week lamps' slow pulse and colour drift.

const COLORS : Array[Color] = [Color(0.0, 1.0, 1.0), Color(1.0, 0.0, 1.0)]


func suite_name() -> String:
	return "neon_pulse"


func test_brightness_stays_between_the_dip_and_full() -> void:
	for step : int in 60:
		var value : float = NeonPulse.brightness(step * 0.25, step % 3)
		assert_true(value >= 1.0 - NeonPulse.PULSE_DEPTH - 0.0001 and value <= 1.0001, "brightness %.3f" % value)


func test_a_pulse_reaches_its_dip_halfway_through() -> void:
	assert_true(is_equal_approx(NeonPulse.brightness(0.0, 0), 1.0))
	assert_true(is_equal_approx(NeonPulse.brightness(NeonPulse.PULSE_PERIOD_SECONDS / 2.0, 0), 1.0 - NeonPulse.PULSE_DEPTH))


func test_neighbouring_lamps_pulse_out_of_step() -> void:
	assert_false(is_equal_approx(NeonPulse.brightness(1.0, 0), NeonPulse.brightness(1.0, 1)))


func test_colour_drifts_only_part_way_to_the_next() -> void:
	for step : int in 60:
		var lamp_color : Color = NeonPulse.color(step * 0.5, 0, COLORS)
		# The cyan lamp's red channel shows how far it has drifted towards magenta.
		assert_true(lamp_color.r <= NeonPulse.MAX_DRIFT + 0.0001, "drift %.3f" % lamp_color.r)
		assert_true(lamp_color.g >= 1.0 - NeonPulse.MAX_DRIFT - 0.0001)


func test_lamps_alternate_their_colours() -> void:
	assert_true(NeonPulse.color(0.0, 0, COLORS).g > NeonPulse.color(0.0, 1, COLORS).g, "lamp 0 is the cyan one")
