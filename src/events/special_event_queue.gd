class_name SpecialEventQueue
extends RefCounted

## Holds special events back while the screen already shows enough of their windows, so a
## burst of callers never stacks windows off the screen. A held event's answer time only
## starts when its window opens.

## Two long windows still fit above Pate's box at 640x360; a third did not.
const MAX_OPEN_WINDOWS : int = 2

var _waiting : Array[SpecialEventData] = []


## True when the event may open now; otherwise it waits for next().
func offer(event_data : SpecialEventData, open_windows : int) -> bool:
	if open_windows < MAX_OPEN_WINDOWS and _waiting.is_empty():
		return true
	_waiting.append(event_data)
	return false


## The next waiting event once a window has closed, or null.
func next(open_windows : int) -> SpecialEventData:
	if open_windows >= MAX_OPEN_WINDOWS or _waiting.is_empty():
		return null
	return _waiting.pop_front()


func waiting() -> Array[SpecialEventData]:
	return _waiting.duplicate()


func clear() -> void:
	_waiting.clear()
