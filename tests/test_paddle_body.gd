@tool
extends McpTestSuite

const PaddleBodyScript := preload("res://src/ui/brew_day/paddle_body.gd")

const AREA : Rect2 = Rect2(0, 0, 232, 104)
const STEP : float = 1.0 / 60.0


func suite_name() -> String:
	return "paddle_body"


func _paddle() -> PaddleBody:
	return PaddleBodyScript.new(AREA, Vector2(200, 20), Vector2(-0.5, 1))


func _run(paddle : PaddleBody, seconds : float, target : Callable) -> void:
	var elapsed : float = 0.0
	while elapsed < seconds:
		paddle.step(STEP, target.call(elapsed), true)
		elapsed += STEP


func test_the_handle_follows_the_pointer() -> void:
	var paddle : PaddleBody = _paddle()
	_run(paddle, 2.0, func(_t : float) -> Vector2: return Vector2(60, 50))
	assert_true(paddle.points[0].distance_to(Vector2(60, 50)) < 3.0)


## Slammed into a wall it squashes for a moment, so the average is what counts.
func test_the_stick_keeps_its_length() -> void:
	var paddle : PaddleBody = _paddle()
	var total : float = 0.0
	var frames : int = 0
	var elapsed : float = 0.0
	while elapsed < 3.0:
		paddle.step(STEP, Vector2(116 + 100 * sign(sin(elapsed * 6.0)), 52), true)
		total += paddle.length()
		frames += 1
		elapsed += STEP
	var straight : float = PaddleBodyScript.SEGMENT * (PaddleBodyScript.POINTS - 1)
	var average : float = total / frames
	assert_true(absf(average - straight) < straight * 0.1, "average length %.1f" % average)


func test_a_wild_sweep_bends_it_and_rest_straightens_it() -> void:
	var paddle : PaddleBody = _paddle()
	var most : float = 0.0
	var elapsed : float = 0.0
	while elapsed < 2.0:
		paddle.step(STEP, Vector2(116 + 100 * sign(sin(elapsed * 8.0)), 52), true)
		most = maxf(most, paddle.bend())
		elapsed += STEP
	assert_gt(most, 4.0)
	_run(paddle, 4.0, func(_t : float) -> Vector2: return Vector2(116, 30))
	assert_true(paddle.bend() < 2.0, "bend %.1f" % paddle.bend())


func test_it_stays_inside_the_kettle() -> void:
	var paddle : PaddleBody = _paddle()
	_run(paddle, 3.0, func(t : float) -> Vector2: return Vector2(500 * sin(t * 9.0), 300 * cos(t * 7.0)))
	for point : Vector2 in paddle.points:
		assert_true(AREA.grow(0.01).has_point(point), str(point))


func test_a_hard_hit_on_the_wall_knocks() -> void:
	var paddle : PaddleBody = _paddle()
	var knocks : Array = []
	paddle.knocked.connect(func(speed : float) -> void: knocks.append(speed))
	_run(paddle, 2.0, func(t : float) -> Vector2: return Vector2(116 + 200 * sign(sin(t * 6.0)), 52))
	assert_false(knocks.is_empty())


func test_a_loose_stick_drifts_back_to_rest() -> void:
	var paddle : PaddleBody = _paddle()
	_run(paddle, 1.0, func(_t : float) -> Vector2: return Vector2(30, 80))
	for i : int in 600:
		paddle.step(STEP, Vector2.ZERO, false)
	assert_true(paddle.points[0].distance_to(Vector2(200, 20)) < 5.0, str(paddle.points[0]))
