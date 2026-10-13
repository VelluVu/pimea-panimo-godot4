@tool
extends McpTestSuite

const SessionScript := preload("res://src/brewery/keg_wash/keg_wash_session.gd")
const RulesScript := preload("res://src/brewery/keg_wash/keg_wash_rules.gd")
const TunnelScript := preload("res://src/brewery/keg_wash/keg_tunnel.gd")

const AT : Vector2 = TunnelScript.OPENING_CENTER + Vector2(-60, 20)
## A brisk scrub: 20 pixels each 1/20 s, 400 pixels a second.
const STEP : Vector2 = Vector2(20, 0)
const DT : float = 0.05


func suite_name() -> String:
	return "keg_wash_session"


func _session(kinds : Array[KegWashSpot.Kind]) -> KegWashSession:
	var spots : Array[KegWashSpot] = []
	for i : int in kinds.size():
		spots.append(KegWashSpot.new(kinds[i], AT + Vector2(0, 60 * i)))
	return SessionScript.new(spots)


## Brushes back and forth across `at` until `pixels` of stroke are done.
func _scrub(session : KegWashSession, at : Vector2, pixels : float) -> void:
	var done : float = 0.0
	var side : float = 1.0
	while done < pixels:
		session.scrub(at - STEP * side / 2.0, at + STEP * side / 2.0, DT)
		done += STEP.length()
		side = -side


func _spray_everywhere(session : KegWashSession) -> void:
	for cell : Vector2 in session.cells:
		session.sanitize(cell, 1.0)


func test_scrubbing_loosens_dirt_and_rinsing_takes_it_away() -> void:
	var session : KegWashSession = _session([KegWashSpot.Kind.YEAST])
	var spot : KegWashSpot = session.spots[0]
	_scrub(session, AT, RulesScript.WORK[KegWashSpot.Kind.YEAST])
	assert_eq(spot.state, KegWashSpot.State.LOOSE)
	session.rinse(AT, RulesScript.RINSE_SECONDS)
	assert_true(spot.is_gone())


func test_salmiakki_ignores_slow_scrubbing() -> void:
	var session : KegWashSession = _session([KegWashSpot.Kind.SALMIAKKI])
	for i : int in 50:
		session.scrub(AT, AT + Vector2(5, 0), DT)
	assert_eq(session.spots[0].state, KegWashSpot.State.STUCK)


func test_the_hat_pops_out_at_the_first_touch() -> void:
	var session : KegWashSession = _session([KegWashSpot.Kind.HAT])
	session.scrub(AT - STEP / 2.0, AT + STEP / 2.0, DT)
	assert_true(session.spots[0].is_gone())


func test_bees_buzz_a_while_before_they_leave() -> void:
	var session : KegWashSession = _session([KegWashSpot.Kind.BEES])
	var bees : KegWashSpot = session.spots[0]
	session.scrub(AT - STEP / 2.0, AT + STEP / 2.0, DT)
	assert_eq(bees.state, KegWashSpot.State.FLEEING)
	session.update(0.5)
	assert_false(bees.is_gone())
	session.update(1.0)
	assert_true(bees.is_gone())


func test_hosing_stuck_dirt_wastes_water() -> void:
	var session : KegWashSession = _session([KegWashSpot.Kind.GUM])
	var mistakes : Array = []
	session.mistake.connect(func(kind : KegWashSession.Mistake) -> void: mistakes.append(kind))
	session.rinse(AT, 1.0)
	assert_eq(session.spots[0].state, KegWashSpot.State.STUCK)
	assert_true(mistakes.has(KegWashSession.Mistake.WASTED_WATER))


func test_scrubbing_a_clean_keg_is_polishing() -> void:
	var session : KegWashSession = _session([KegWashSpot.Kind.HAT])
	var mistakes : Array = []
	session.mistake.connect(func(kind : KegWashSession.Mistake) -> void: mistakes.append(kind))
	session.scrub(AT - STEP / 2.0, AT + STEP / 2.0, DT)
	session.scrub(AT + Vector2(0, -80), AT + Vector2(20, -80), DT)
	assert_false(mistakes.has(KegWashSession.Mistake.POLISHING), "passing over a clean keg is fine")
	for i : int in 12:
		session.scrub(AT + Vector2(0, -80), AT + Vector2(20, -80), DT)
	assert_true(mistakes.has(KegWashSession.Mistake.POLISHING))


func test_the_sanitizer_does_not_stick_to_dirt() -> void:
	var session : KegWashSession = _session([KegWashSpot.Kind.YEAST])
	_spray_everywhere(session)
	assert_true(session.coverage() < 1.0)
	assert_false(session.is_completed)


func test_a_spotless_covered_keg_is_complete_and_clean() -> void:
	var session : KegWashSession = _session([KegWashSpot.Kind.YEAST, KegWashSpot.Kind.HAT])
	var done : Array = []
	session.completed.connect(func() -> void: done.append(true))
	_scrub(session, AT, RulesScript.WORK[KegWashSpot.Kind.YEAST])
	var hat_at : Vector2 = session.spots[1].position
	session.scrub(hat_at - STEP / 2.0, hat_at + STEP / 2.0, DT)
	session.rinse(AT, RulesScript.RINSE_SECONDS)
	_spray_everywhere(session)
	assert_true(session.is_completed)
	assert_eq(done.size(), 1)
	assert_eq(session.cleanliness(), 1.0)


func test_spraying_a_finished_patch_says_the_germs_are_dead() -> void:
	var session : KegWashSession = _session([KegWashSpot.Kind.YEAST])
	var mistakes : Array = []
	session.mistake.connect(func(kind : KegWashSession.Mistake) -> void: mistakes.append(kind))
	var far : Vector2 = TunnelScript.OPENING_CENTER + Vector2(100, -40)
	session.sanitize(far, 1.0)
	session.sanitize(far, 0.2)
	assert_false(mistakes.has(KegWashSession.Mistake.GERMS_DEAD), "a quick pass over a finished patch is fine")
	session.sanitize(far, RulesScript.MISTAKE_DWELL)
	assert_true(mistakes.has(KegWashSession.Mistake.GERMS_DEAD))


func test_a_half_done_wash_scores_partly_clean() -> void:
	var session : KegWashSession = _session([KegWashSpot.Kind.YEAST, KegWashSpot.Kind.GUM])
	assert_eq(session.cleanliness(), 0.0)
	_scrub(session, AT, RulesScript.WORK[KegWashSpot.Kind.YEAST])
	# Half the dirt scrubbed loose: half of the scrubbing share.
	assert_true(is_equal_approx(session.cleanliness(), RulesScript.SCRUB_SHARE / 2.0))


func _grimy_session() -> KegWashSession:
	var stain := KegWashStain.new(AT, Vector2(40, 25), RulesScript.STAIN_COLORS[0])
	return SessionScript.new([] as Array[KegWashSpot], [stain] as Array[KegWashStain], true)


func _hose_everywhere(session : KegWashSession) -> void:
	for cell : Vector2 in session.grime_cells:
		session.rinse(cell, 1.0)


func test_the_film_covers_the_whole_inside_and_a_stain_is_thicker() -> void:
	var session : KegWashSession = _grimy_session()
	assert_true(session.grime_cells.size() > 100)
	assert_true(session.grime_left() > 0.99)
	var thickest : float = 0.0
	for amount : float in session.grime:
		thickest = maxf(thickest, amount)
	assert_eq(thickest, 1.0)


func test_only_hosing_all_over_takes_the_grime_off() -> void:
	var session : KegWashSession = _grimy_session()
	var cleared : Array = []
	session.stain_cleared.connect(func(stain : KegWashStain) -> void: cleared.append(stain))
	session.rinse(AT, 1.0)
	assert_true(session.grime_left() > 0.5, "one spot of water cleans one patch, not the keg")
	assert_eq(cleared.size(), 0)
	_hose_everywhere(session)
	assert_eq(session.grime_left(), 0.0)
	assert_eq(cleared.size(), 1)


func test_the_sanitizer_does_not_stick_to_grime() -> void:
	var session : KegWashSession = _grimy_session()
	_spray_everywhere(session)
	assert_eq(session.coverage(), 0.0)
	_hose_everywhere(session)
	_spray_everywhere(session)
	assert_true(session.is_completed)


func test_hosing_the_grime_counts_toward_the_rinse_share() -> void:
	var session : KegWashSession = _grimy_session()
	assert_true(is_equal_approx(session.cleanliness(), RulesScript.SCRUB_SHARE + RulesScript.RINSE_SHARE / 2.0))
	_hose_everywhere(session)
	assert_true(is_equal_approx(session.cleanliness(), RulesScript.SCRUB_SHARE + RulesScript.RINSE_SHARE))


func test_hosing_most_of_the_grime_is_good_enough() -> void:
	var session : KegWashSession = _grimy_session()
	var rinsed : Array = []
	session.grime_rinsed.connect(func() -> void: rinsed.append(true))
	# Every cell but the outermost rim ones.
	for cell : Vector2 in session.grime_cells:
		if TunnelScript.reach(cell) < 0.9:
			session.rinse(cell, 1.0)
	assert_eq(rinsed.size(), 1)
	assert_eq(session.grime_left(), 0.0, "the last specks wash off with the rest")


func test_hosing_a_rinsed_keg_wastes_water() -> void:
	var session : KegWashSession = _grimy_session()
	var mistakes : Array = []
	session.mistake.connect(func(kind : KegWashSession.Mistake) -> void: mistakes.append(kind))
	_hose_everywhere(session)
	mistakes.clear()
	session.rinse(AT, 0.2)
	assert_false(mistakes.has(KegWashSession.Mistake.WASTED_WATER), "a quick pass is fine")
	session.rinse(AT, RulesScript.MISTAKE_DWELL)
	assert_true(mistakes.has(KegWashSession.Mistake.WASTED_WATER))
