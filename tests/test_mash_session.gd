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


const PIVOT : Vector2 = Vector2(116, -18)
const REACH : Vector2 = Vector2(0, 200)
const BLADE : float = 200.0


## One swing across the clump, fast or slow.
func _swing_through(session : MashSession, clump : MashClump, speed : float) -> void:
	var offset : Vector2 = clump.position - PIVOT
	var angle : float = atan2(offset.x, offset.y)
	session.paddle_swing(PIVOT, angle - 0.3, angle + 0.3, REACH, BLADE, speed)


func _break_all_clumps(session : MashSession) -> void:
	for clump : MashClump in session.clumps:
		for i : int in MashSessionScript.SWIPES_PER_CLUMP:
			clump.cooldown = 0.0
			_swing_through(session, clump, 8.0)


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


func test_a_clump_takes_several_hard_swings() -> void:
	var session : MashSession = _session([65.0], 1)
	session.add_malts()
	var clump : MashClump = session.clumps[0]
	for i : int in MashSessionScript.SWIPES_PER_CLUMP - 1:
		clump.cooldown = 0.0
		_swing_through(session, clump, 8.0)
	assert_false(clump.is_broken())
	clump.cooldown = 0.0
	_swing_through(session, clump, 8.0)
	assert_true(clump.is_broken())


func test_a_slow_swing_only_pushes() -> void:
	var session : MashSession = _session([65.0], 1)
	session.add_malts()
	var clump : MashClump = session.clumps[0]
	_swing_through(session, clump, 1.0)
	assert_eq(clump.swipes_left, MashSessionScript.SWIPES_PER_CLUMP)
	assert_gt(clump.velocity.length(), 0.0)


func test_a_hit_knocks_the_clump_away_and_waits_before_the_next() -> void:
	var session : MashSession = _session([65.0], 1)
	session.add_malts()
	var clump : MashClump = session.clumps[0]
	var before : Vector2 = clump.position
	_swing_through(session, clump, 8.0)
	_swing_through(session, clump, 8.0)
	assert_eq(clump.swipes_left, MashSessionScript.SWIPES_PER_CLUMP - 1, "the cooldown stops a double hit")
	for i : int in 10:
		session.step(STEP)
	assert_gt(clump.position.distance_to(before), 3.0)


func test_the_shaft_only_pushes() -> void:
	var session : MashSession = _session([65.0], 1)
	session.add_malts()
	var clump : MashClump = session.clumps[0]
	var offset : Vector2 = clump.position - PIVOT
	var angle : float = atan2(offset.x, offset.y)
	# The blade is well past the clump, so only the shaft crosses it.
	session.paddle_swing(PIVOT, angle - 0.3, angle + 0.3, Vector2(0, offset.length() + 60.0), 20.0, 8.0)
	assert_eq(clump.swipes_left, MashSessionScript.SWIPES_PER_CLUMP)
	assert_gt(clump.velocity.length(), 0.0)


func test_a_swing_beside_the_clump_misses() -> void:
	var session : MashSession = _session([65.0], 1)
	session.add_malts()
	var clump : MashClump = session.clumps[0]
	var offset : Vector2 = clump.position - PIVOT
	var angle : float = atan2(offset.x, offset.y)
	session.paddle_swing(PIVOT, angle + 0.5, angle + 0.9, REACH, BLADE, 8.0)
	assert_eq(clump.swipes_left, MashSessionScript.SWIPES_PER_CLUMP)


func test_clumps_stay_in_the_kettle() -> void:
	var session : MashSession = _session([65.0], 3)
	session.add_malts()
	for clump : MashClump in session.clumps:
		clump.velocity = Vector2(500, -500)
	for i : int in 120:
		session.step(STEP)
	for clump : MashClump in session.clumps:
		assert_true(Rect2(Vector2.ZERO, MashSessionScript.LIQUID_SIZE).has_point(clump.position))


func test_more_clumps_appear_later() -> void:
	var session : MashSession = _session([65.0], 2)
	_play_well(session, 5.0)
	session.add_malts()
	assert_eq(session.clumps.size(), 2)
	_play_well(session, 30.0)
	assert_gt(session.clumps.size(), 2)


func test_clumps_spawn_inside_the_liquid() -> void:
	var session : MashSession = _session([65.0], 5)
	session.add_malts()
	for clump : MashClump in session.clumps:
		assert_true(Rect2(Vector2.ZERO, MashSessionScript.LIQUID_SIZE).has_point(clump.position))
