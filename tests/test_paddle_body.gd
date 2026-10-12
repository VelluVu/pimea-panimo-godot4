@tool
extends McpTestSuite

const PaddleBodyScript := preload("res://src/ui/brew_day/paddle_body.gd")

const MOUTH : Rect2 = Rect2(0, 0, 232, 104)
const REST : Vector2 = Vector2(170, 76)
const STEP : float = 1.0 / 60.0


func suite_name() -> String:
	return "paddle_body"


func _paddle() -> PaddleBody:
	return PaddleBodyScript.new(MOUTH, REST)


func _run(paddle : PaddleBody, seconds : float, target : Callable) -> void:
	var elapsed : float = 0.0
	while elapsed < seconds:
		paddle.step(STEP, target.call(elapsed), true)
		elapsed += STEP


func _sweep(t : float) -> Vector2:
	return Vector2(116 + 110 * sign(sin(t * 6.0)), 52 + 30 * sin(t * 2.0))


func test_the_blade_follows_the_pointer() -> void:
	var paddle : PaddleBody = _paddle()
	_run(paddle, 2.0, func(_t : float) -> Vector2: return Vector2(60, 50))
	assert_true(paddle.points[0].distance_to(Vector2(60, 50)) < 3.0)


func test_the_shaft_leans_over_the_far_rim() -> void:
	var paddle : PaddleBody = _paddle()
	_run(paddle, 3.0, func(_t : float) -> Vector2: return Vector2(40, 52))
	assert_gt(paddle.handle().x, MOUTH.get_center().x, "blade left, handle right")
	assert_true(paddle.handle().y < paddle.points[0].y, "the handle leans up")
	_run(paddle, 3.0, func(_t : float) -> Vector2: return Vector2(192, 52))
	assert_true(paddle.handle().x < MOUTH.get_center().x, "blade right, handle left")


func test_the_handle_lags_behind_a_quick_move() -> void:
	var paddle : PaddleBody = _paddle()
	_run(paddle, 3.0, func(_t : float) -> Vector2: return Vector2(40, 52))
	_run(paddle, 0.1, func(_t : float) -> Vector2: return Vector2(192, 52))
	assert_gt(paddle.handle().distance_to(paddle.handle_goal(paddle.points[0])), 10.0)


func test_the_blade_stays_in_the_mouth() -> void:
	var paddle : PaddleBody = _paddle()
	_run(paddle, 3.0, func(t : float) -> Vector2: return Vector2(500 * sin(t * 9.0), 300 * cos(t * 7.0)))
	assert_true(paddle.inside_mouth(paddle.points[0]).distance_to(paddle.points[0]) < 0.01)


## Slammed about it squashes for a moment, so the average is what counts.
func test_the_stick_keeps_its_length() -> void:
	var paddle : PaddleBody = _paddle()
	var total : float = 0.0
	var frames : int = 0
	var elapsed : float = 0.0
	while elapsed < 3.0:
		paddle.step(STEP, _sweep(elapsed), true)
		total += paddle.length()
		frames += 1
		elapsed += STEP
	var straight : float = PaddleBodyScript.stick_length()
	var average : float = total / frames
	assert_true(absf(average - straight) < straight * 0.1, "average length %.1f" % average)


func test_a_wild_sweep_bends_it_and_rest_straightens_it() -> void:
	var paddle : PaddleBody = _paddle()
	var most : float = 0.0
	var elapsed : float = 0.0
	while elapsed < 2.0:
		paddle.step(STEP, _sweep(elapsed), true)
		most = maxf(most, paddle.bend())
		elapsed += STEP
	assert_gt(most, 4.0)
	_run(paddle, 4.0, func(_t : float) -> Vector2: return Vector2(116, 70))
	assert_true(paddle.bend() < 2.0, "bend %.1f" % paddle.bend())


func test_a_hard_hit_on_the_wall_knocks() -> void:
	var paddle : PaddleBody = _paddle()
	var knocks : Array = []
	paddle.knocked.connect(func(speed : float) -> void: knocks.append(speed))
	_run(paddle, 2.0, func(t : float) -> Vector2: return Vector2(116 + 300 * sign(sin(t * 6.0)), 52))
	assert_false(knocks.is_empty())


func test_a_loose_paddle_drifts_back_to_rest() -> void:
	var paddle : PaddleBody = _paddle()
	_run(paddle, 1.0, func(_t : float) -> Vector2: return Vector2(30, 50))
	for i : int in 600:
		paddle.step(STEP, Vector2.ZERO, false)
	assert_true(paddle.points[0].distance_to(REST) < 5.0, str(paddle.points[0]))
