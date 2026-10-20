class_name BannerPresenter
extends RefCounted

## Flash, hold and fade for one passive Label (a banner, hint or toast), one presenter per
## banner. Purely visual. The label must be in the tree when present() is called.

## After the fade-out, natural or early; not when a new present() cuts the old one off.
signal finished

const FLASH_COLOR : Color = Color(1.4, 1.4, 1.0, 1.0)
const SETTLED_COLOR : Color = Color(1.0, 1.0, 1.0, 1.0)
const TRANSPARENT_COLOR : Color = Color(1.0, 1.0, 1.0, 0.0)

## Offsets are a half-height around the centred anchor (_fit_height()); this floor keeps a
## two-line box.
const MIN_HALF_HEIGHT : float = 50.0
const VERTICAL_PADDING : float = 6.0
## A dark box behind a banner over the busy bar, so bubbles behind it do not mix into the
## text. Fades with the label.
const BACKING_COLOR : Color = Color(0.05, 0.035, 0.02, 0.82)
const BACKING_BORDER_COLOR : Color = Color(0.36, 0.27, 0.15, 0.9)
const BACKING_MARGIN : float = 10.0
const BACKING_CORNER_RADIUS : int = 3

var _label : Label
var _flash_seconds : float
var _hold_seconds : float
var _fade_seconds : float
var _fit_to_text : bool
var _bright_flash : bool
var _hide_when_done : bool
var _on_finished : Callable
var _tween : Tween


## Gives `label` the dark backing box, see BACKING_COLOR.
static func add_backing(label : Label) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = BACKING_COLOR
	box.border_color = BACKING_BORDER_COLOR
	box.set_border_width_all(1)
	box.set_corner_radius_all(BACKING_CORNER_RADIUS)
	box.set_content_margin_all(BACKING_MARGIN)
	label.add_theme_stylebox_override(&"normal", box)


## bright_flash: an overexposed flash instead of a fade-in. fit_to_text: grow to the wrapped
## text. hide_when_done: hide() at the end. on_finished runs after the fade.
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

	# Real seconds, so a sped-up game does not cut the reading time.
	_tween = _label.create_tween().set_ignore_time_scale()
	if _bright_flash:
		_tween.tween_property(_label, "modulate", flash_opaque, _flash_seconds)
		_tween.tween_property(_label, "modulate", SETTLED_COLOR, _flash_seconds)
	else:
		_tween.tween_property(_label, "modulate:a", 1.0, _flash_seconds)
	_tween.tween_interval(_hold_seconds)
	_append_fade_out(_tween)


## Cuts the hold short and fades out now. No-op if nothing is showing.
func dismiss_early() -> void:
	if _tween == null or not _tween.is_running():
		return
	_kill_tween()
	_tween = _label.create_tween().set_ignore_time_scale()
	_append_fade_out(_tween)


func is_running() -> bool:
	return _tween != null and _tween.is_running()


func _append_fade_out(tween : Tween) -> void:
	tween.tween_property(_label, "modulate:a", 0.0, _fade_seconds)
	if _hide_when_done:
		tween.tween_callback(_label.hide)
	if _on_finished.is_valid():
		tween.tween_callback(_on_finished)
	tween.tween_callback(finished.emit)


func _kill_tween() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null


## A Label never resizes its own rect, so wrapped text grows the offsets here. Anchored at
## the bottom (anchor_top = 1) it grows upward from offset_bottom, padded by its box;
## otherwise it is a half-height around the centred anchor.
func _fit_height() -> void:
	var font : Font = _label.get_theme_font("font")
	var font_size : int = _label.get_theme_font_size("font_size")
	if _label.anchor_top >= 1.0:
		var padding : Vector2 = _label.get_theme_stylebox(&"normal").get_minimum_size()
		var text_height : float = font.get_multiline_string_size(
			_label.text, HORIZONTAL_ALIGNMENT_CENTER, _label.size.x - padding.x, font_size
		).y
		_label.offset_top = _label.offset_bottom - text_height - padding.y
		return

	var wrapped_height : float = font.get_multiline_string_size(
		_label.text, HORIZONTAL_ALIGNMENT_CENTER, _label.size.x, font_size
	).y
	var half_height : float = maxf(MIN_HALF_HEIGHT, wrapped_height * 0.5 + VERTICAL_PADDING)
	_label.offset_top = -half_height
	_label.offset_bottom = half_height
