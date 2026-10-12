@tool
extends McpTestSuite

const MashSessionScript := preload("res://src/brewing/brew_day/mash_session.gd")

const STEP : float = 1.0 / 60.0


func suite_name() -> String:
	return "mash_session"


func _session(steps : Array, clumps : int = 0) -> MashSession:
	var temperatures : Array[float] = []
	temperatures.assign(steps)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	return MashSessionScript.new(temperatures, 2.0, 0.35, clumps, rng)


## Heats while under the target, a little early to beat the burner's lag.
func _play_well(session : MashSession, seconds : float) -> void:
	var elapsed : float = 0.0
	while elapsed < seconds and session.phase != MashSession.Phase.DONE:
		session.set_heating(session.heat.temperature < session.target() - 0.6)
		session.step(STEP)
		elapsed += STEP


func _break_all_clumps(session : MashSession) -> void:
	for clump : MashClump in session.clumps:
		for i : int in MashSessionScript.SWIPES_PER_CLUMP:
			session.paddle_at(clump.position)
			session.paddle_at(Vector2(-1, -1))


func test_the_water_starts_under_the_malt_marker() -> void:
	var session : MashSession = _session([65.0])
	assert_eq(session.malt_marker(), 68.0)
	assert_true(session.heat.temperature < session.malt_marker())
	assert_eq(session.target(), 68.0)


func test_the_clock_waits_for_the_malts() -> void:
	var session : MashSession = _session([65.0])
	_play_well(session, 5.0)
	assert_eq(session.counted, 0.0)
	assert_eq(session.phase, MashSession.Phase.WATER)


func test_malts_drop_the_temperature_and_start_the_clock() -> void:
	var session : MashSession = _session([65.0])
	_play_well(session, 5.0)
	var before : float = session.heat.temperature
	session.add_malts()
	assert_eq(session.heat.temperature, before - MashSessionScript.MALT_DROP)
	assert_eq(session.phase, MashSession.Phase.HOLD)
	session.step(STEP)
	assert_gt(session.counted, 0.0)


func test_good_control_scores_high() -> void:
	var session : MashSession = _session([65.0])
	_play_well(session, 5.0)
	session.add_malts()
	_play_well(session, 30.0)
	assert_eq(session.phase, MashSession.Phase.DONE)
	assert_gt(session.score(), 0.8)


func test_doing_nothing_scores_low() -> void:
	var session : MashSession = _session([65.0])
	session.add_malts()
	for i : int in 900:
		session.step(STEP)
	assert_true(session.score() < 0.3)


func test_a_step_mash_ramps_without_counting() -> void:
	var session : MashSession = _session([45.0, 63.0, 72.0])
	_play_well(session, 5.0)
	session.add_malts()
	_play_well(session, 60.0)
	assert_eq(session.phase, MashSession.Phase.DONE)
	assert_true(absf(session.counted - MashProgram.MASH_SECONDS) < 0.1, "ramps add no counted time")
	assert_gt(session.score(), 0.7)


func test_clumps_left_cut_the_score() -> void:
	var clean : MashSession = _session([65.0], 3)
	var lumpy : MashSession = _session([65.0], 3)
	for session : MashSession in [clean, lumpy]:
		_play_well(session, 5.0)
		session.add_malts()
	_break_all_clumps(clean)
	_play_well(clean, 30.0)
	_play_well(lumpy, 30.0)
	_break_all_clumps(clean)
	assert_eq(clean.clumps_left(), 0)
	assert_gt(lumpy.clumps_left(), 0)
	assert_gt(clean.score(), lumpy.score())


func test_a_clump_takes_two_passes() -> void:
	var session : MashSession = _session([65.0], 1)
	session.add_malts()
	var clump : MashClump = session.clumps[0]
	session.paddle_at(clump.position)
	session.paddle_at(Vector2(-1, -1))
	assert_false(clump.is_broken())
	session.paddle_at(clump.position)
	session.paddle_at(Vector2(-1, -1))
	assert_true(clump.is_broken())


func test_more_clumps_appear_later() -> void:
	var session : MashSession = _session([65.0], 2)
	_play_well(session, 5.0)
	session.add_malts()
	assert_eq(session.clumps.size(), 2)
	_play_well(session, 30.0)
	assert_gt(session.clumps.size(), 2)


func test_a_paddle_swept_across_a_clump_swipes_it() -> void:
	var session : MashSession = _session([65.0], 1)
	session.add_malts()
	var clump : MashClump = session.clumps[0]
	var above : Vector2 = clump.position + Vector2(0, -40)
	var below : Vector2 = clump.position + Vector2(0, 40)
	# The blade crosses the clump although neither end is near it.
	session.paddle_swept(above + Vector2(-30, 0), below + Vector2(30, 0))
	session.paddle_swept(above + Vector2(-80, 0), below + Vector2(-80, 0))
	assert_eq(clump.swipes_left, MashSessionScript.SWIPES_PER_CLUMP - 1)


func test_clumps_spawn_inside_the_liquid() -> void:
	var session : MashSession = _session([65.0], 5)
	session.add_malts()
	for clump : MashClump in session.clumps:
		assert_true(Rect2(Vector2.ZERO, MashSessionScript.LIQUID_SIZE).has_point(clump.position))
