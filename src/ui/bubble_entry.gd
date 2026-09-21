class_name BubbleEntry
extends RefCounted

## One speaker's live speech bubble. Anything that can run after the bubble was freed
## (an eviction, a display timer that expires) asks the entry, never the bubble: passing
## a freed Object into a typed parameter is a hard runtime error.

var bubble : SpeechBubble
var x : float = 0.0
var height_step : int = 0
var fade_tween : Tween = null

var _token : int = 0


func _init(new_bubble : SpeechBubble) -> void:
	bubble = new_bubble


func is_alive() -> bool:
	return is_instance_valid(bubble)


## Every display invalidates the hides still waiting on an earlier one.
func next_token() -> int:
	_token += 1
	return _token


func is_current(token : int) -> bool:
	return token == _token and is_alive()


func stop_fade() -> void:
	if fade_tween != null and is_instance_valid(fade_tween):
		fade_tween.kill()
	fade_tween = null


## Closes the bubble at once and voids any hide still in flight.
func dispose() -> void:
	_token += 1
	stop_fade()
	if is_alive():
		bubble.queue_free()
