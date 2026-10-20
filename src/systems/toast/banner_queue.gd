class_name BannerQueue
extends RefCounted

## One screen spot shared by several BannerPresenters: texts are shown one after another,
## the next as soon as the current one has faded out, so two banners never overlap.

## [presenter, text, on_shown], oldest first.
var _pending : Array[Array] = []
var _current : BannerPresenter = null


## Shows `text` on `presenter` now if the spot is free, else after the queued ones.
## `on_shown` runs when it actually appears.
func show(presenter : BannerPresenter, text : String, on_shown : Callable = Callable()) -> void:
	_pending.append([presenter, text, on_shown])
	if _current == null:
		_show_next()


func pending_count() -> int:
	return _pending.size()


func is_showing() -> bool:
	return _current != null


func _show_next() -> void:
	if _pending.is_empty():
		_current = null
		return
	var entry : Array = _pending.pop_front()
	_current = entry[0]
	_current.finished.connect(_show_next, CONNECT_ONE_SHOT)
	_current.present(entry[1])
	var on_shown : Callable = entry[2]
	if on_shown.is_valid():
		on_shown.call()
