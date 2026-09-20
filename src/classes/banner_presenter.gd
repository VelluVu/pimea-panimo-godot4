class_name BannerPresenter
extends RefCounted

## Flash / hold / fade presentation for one passive Label (group-visit banner,
## day-event banner, first-brew hint, discovery toast). GUI used to carry a
## hand-copied version of this tween sequence per banner; each banner is now
## one presenter configured with its own timing and look, so a new banner is
## one constructor call instead of another copy of the sequence.
##
## Purely visual: no input, no gameplay state. The label must already be in
## the scene tree when present() is called (its tween is created on it).

const FLASH_COLOR : Color = Color(1.4, 1.4, 1.0, 1.0)
const SETTLED_COLOR : Color = Color(1.0, 1.0, 1.0, 1.0)
const TRANSPARENT_COLOR : Color = Color(1.0, 1.0, 1.0, 0.0)

## Banners are anchored top == bottom == 0.5 in main.tscn, so
## offset_top/offset_bottom are a half-height around the anchor rather than a
## real box height (see _fit_height()). 50.0 matches the original hand-tuned
## two-line box and is kept as the floor so a short banner never shrinks
## below the original design.
const MIN_HALF_HEIGHT : float = 50.0
const VERTICAL_PADDING : float = 6.0

var _label : Label
var _flash_seconds : float
var _hold_seconds : float
var _fade_seconds : float
var _fit_to_text : bool
var _bright_flash : bool
var _hide_when_done : bool
var _on_finished : Callable
var _tween : Tween


## bright_flash: overexposed FLASH_COLOR flash that settles to normal (group
## banner, toast, hint) versus a plain alpha fade-in (day-event banner).
## fit_to_text: grow the label's offsets to its wrapped text height (banners
## only, not the toast). hide_when_done: also hide() the label at the end.
## on_finished runs after the fade, and after dismiss_early()'s fade too.
func _init(label : Label, flash_seconds : float, hold_seconds : float, fade_seconds : float, bright_flash : bool = true, fit_to_text : bool = true, hide_when_done : bool = false, on_finished : Callable = Callable()) -> void:
	_label = label
	_flash_seconds = flash_seconds
	_hold_seconds = hold_seconds
	_fade_seconds = fade_seconds
	_bright_flash = bright_flash
	_fit_to_text = fit_to_text
	_hide_when_done = hide_when_done
	_on_finished = on_finished


## flash_color tints the overexposed flash (e.g. a red one for a rejection);
## ignored when the presenter was built without bright_flash.
func present(text : String, flash_color : Color = FLASH_COLOR) -> void:
	_label.text = text
	if _fit_to_text:
		_fit_height()

	_kill_tween()
	var flash_opaque : Color = Color(flash_color, 1.0)
	_label.modulate = Color(flash_color, 0.0) if _bright_flash else TRANSPARENT_COLOR

	_tween = _label.create_tween()
	if _bright_flash:
		_tween.tween_property(_label, "modulate", flash_opaque, _flash_seconds)
		_tween.tween_property(_label, "modulate", SETTLED_COLOR, _flash_seconds)
	else:
		_tween.tween_property(_label, "modulate:a", 1.0, _flash_seconds)
	_tween.tween_interval(_hold_seconds)
	_append_fade_out(_tween)


## Cuts the hold short and fades out now (e.g. the hint that explains "doors
## are closed" once the doors open). No-op if nothing is showing.
func dismiss_early() -> void:
	if _tween == null or not _tween.is_running():
		return
	_kill_tween()
	_tween = _label.create_tween()
	_append_fade_out(_tween)


func is_running() -> bool:
	return _tween != null and _tween.is_running()


func _append_fade_out(tween : Tween) -> void:
	tween.tween_property(_label, "modulate:a", 0.0, _fade_seconds)
	if _hide_when_done:
		tween.tween_callback(_label.hide)
	if _on_finished.is_valid():
		tween.tween_callback(_on_finished)


func _kill_tween() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null


## Free-authored text (group-event .tres, long hints) can word-wrap into more
## lines than the editor-sized box holds, and a Label never clips or resizes
## its own rect. Re-measure the wrapped height at the label's fixed width and
## grow the symmetric offsets to match, keeping the block on-screen and centered.
func _fit_height() -> void:
	var font : Font = _label.get_theme_font("font")
	var font_size : int = _label.get_theme_font_size("font_size")
	var wrapped_height : float = font.get_multiline_string_size(
		_label.text, HORIZONTAL_ALIGNMENT_CENTER, _label.size.x, font_size
	).y
	var half_height : float = maxf(MIN_HALF_HEIGHT, wrapped_height * 0.5 + VERTICAL_PADDING)
	_label.offset_top = -half_height
	_label.offset_bottom = half_height
