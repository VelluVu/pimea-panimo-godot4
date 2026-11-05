class_name WindowPop
extends RefCounted

## Fades a window in each time it opens, in a few hard alpha steps instead of a smooth
## glide, so it arrives like a pixel-art sprite frame and never looks smeared. Runs while
## the game is paused, since many windows pause it.
##   WindowPop.attach(self)

const STEPS : int = 3
const SECONDS : float = 0.09
const TWEEN_META : StringName = &"window_pop_tween"


static func attach(window : CanvasItem) -> void:
	window.visibility_changed.connect(func() -> void:
		if window.visible:
			play(window))


static func play(window : CanvasItem) -> void:
	# Reopened mid-fade: the old steps must not land after the new ones.
	if window.has_meta(TWEEN_META):
		var old : Tween = window.get_meta(TWEEN_META)
		if old != null and old.is_valid():
			old.kill()
	window.modulate.a = alpha_at(0)
	var tween : Tween = window.create_tween()
	window.set_meta(TWEEN_META, tween)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	for step : int in range(1, STEPS + 1):
		tween.tween_interval(SECONDS / STEPS)
		tween.tween_callback(func() -> void: window.modulate.a = alpha_at(step))


## Alpha after `step` of STEPS: a visible first frame, full at the last.
static func alpha_at(step : int) -> float:
	return clampf(float(step + 1) / float(STEPS + 1), 0.0, 1.0)
