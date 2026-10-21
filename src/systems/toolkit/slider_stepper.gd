class_name SliderStepper
extends RefCounted

## Puts big - and + buttons around a slider and gives it a larger knob, so an exact amount
## is easy to pick with a finger. Holding a button keeps stepping. The knob is the theme's
## own, scaled up in whole steps so its pixels stay square.
##   SliderStepper.wrap(my_slider)

const BUTTON_SIZE: Vector2 = Vector2(26, 26)
const SLIDER_HEIGHT: float = 26.0
## The knob is scaled until it is at least this tall.
const GRABBER_SIZE: int = 18
## Pause before a held button starts repeating, then the time between steps.
const REPEAT_DELAY_SECONDS: float = 0.4
const REPEAT_INTERVAL_SECONDS: float = 0.08
const MINUS_TEXT: String = "-"
const PLUS_TEXT: String = "+"


## Moves `slider` into a new row [-] slider [+] at the slider's place and returns the row.
static func wrap(slider: Range) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = slider.size_flags_horizontal
	var parent: Node = slider.get_parent()
	var index: int = slider.get_index()
	parent.remove_child(slider)
	parent.add_child(row)
	parent.move_child(row, index)

	row.add_child(_make_button(slider, MINUS_TEXT, -1.0))
	row.add_child(slider)
	row.add_child(_make_button(slider, PLUS_TEXT, 1.0))
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.custom_minimum_size.y = SLIDER_HEIGHT

	for icon: StringName in [&"grabber", &"grabber_highlight"]:
		var texture: Texture2D = slider.get_theme_icon(icon)
		slider.add_theme_icon_override(icon, scaled(texture, grabber_scale(texture.get_height(), GRABBER_SIZE)))
	return row


## The value one step away, kept inside the range.
static func stepped(value: float, direction: float, step: float, min_value: float, max_value: float) -> float:
	return clampf(value + direction * maxf(step, 1.0), min_value, max_value)


## The smallest whole factor that makes a knob `height` pixels tall reach `min_height`.
static func grabber_scale(height: int, min_height: int) -> int:
	return maxi(1, ceili(float(min_height) / float(maxi(height, 1))))


## `texture` enlarged `factor` times with nearest-neighbour sampling.
static func scaled(texture: Texture2D, factor: int) -> Texture2D:
	if factor <= 1:
		return texture
	var image: Image = texture.get_image()
	image.resize(image.get_width() * factor, image.get_height() * factor, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(image)


static func _make_button(slider: Range, text: String, direction: float) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = BUTTON_SIZE
	var timer := Timer.new()
	button.add_child(timer)
	var step_once := func() -> void:
		slider.value = stepped(slider.value, direction, slider.step, slider.min_value, slider.max_value)
	button.button_down.connect(func() -> void:
		step_once.call()
		timer.start(REPEAT_DELAY_SECONDS))
	button.button_up.connect(timer.stop)
	timer.timeout.connect(func() -> void:
		step_once.call()
		timer.start(REPEAT_INTERVAL_SECONDS))
	return button
