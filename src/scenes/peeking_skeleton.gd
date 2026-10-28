class_name PeekingSkeleton
extends AnimatedSprite2D

## A skeleton that now and then peeks out of its hiding place (the barrel, a wall corner,
## behind a tank), looks around and hides again. The frames are cut to the spot by
## dev/tools/sprites/make_barrel_skeleton.py. Lives under HalloweenDecor, so it is only up
## in the season.

const ANIM_PEEK : StringName = &"peek"
## The first peek comes soon, so a short session still meets the skeletons.
const FIRST_PEEK_SECONDS : Vector2 = Vector2(4.0, 15.0)

@export var min_interval_seconds : float = 30.0 * DayPace.SCALE
@export var max_interval_seconds : float = 70.0 * DayPace.SCALE

var _timer : Timer


func _ready() -> void:
	visible = false
	animation_finished.connect(_on_peek_finished)
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(peek)
	add_child(_timer)
	_timer.start(randf_range(FIRST_PEEK_SECONDS.x, FIRST_PEEK_SECONDS.y))


func peek() -> void:
	visible = true
	play(ANIM_PEEK)


func _on_peek_finished() -> void:
	visible = false
	_start_next_timer()


func _start_next_timer() -> void:
	_timer.start(randf_range(min_interval_seconds, max_interval_seconds))
