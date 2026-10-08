class_name SliderStepper
extends RefCounted

## Puts big - and + buttons around a slider and gives it a larger knob, so an exact amount
## is easy to pick with a finger. Holding a button keeps stepping.
##   SliderStepper.wrap(my_slider)

const BUTTON_SIZE: Vector2 = Vector2(26, 26)
const SLIDER_HEIGHT: float = 26.0
const GRABBER_SIZE: int = 18
## Pause before a held button starts repeating, then the time between steps.
const REPEAT_DELAY_SECONDS: float = 0.4
const REPEAT_INTERVAL_SECONDS: float = 0.08
const MINUS_TEXT: String = "-"
const PLUS_TEXT: String = "+"


## Moves `slider` into a new row [-] slider [+] at the slider's place and returns the row.
static func wrap(slider: Range, grabber_fill: Color = Color(0.93, 0.86, 0.72), grabber_outline: Color = Color(0.08, 0.05, 0.03)) -> HBoxContainer:
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

	var grabber := make_grabber(GRABBER_SIZE, grabber_fill, grabber_outline)
	slider.add_theme_icon_override(&"grabber", grabber)
	slider.add_theme_icon_override(&"grabber_highlight", grabber)
	return row


## The value one step away, kept inside the range.
static func stepped(value: float, direction: float, step: float, min_value: float, max_value: float) -> float:
	return clampf(value + direction * maxf(step, 1.0), min_value, max_value)


## A round pixel knob: `fill` inside a one-pixel `outline`.
static func make_grabber(size: int, fill: Color, outline: Color) -> ImageTexture:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size - 1, size - 1) / 2.0
	var radius: float = size / 2.0
	for y: int in size:
		for x: int in size:
			var distance: float = Vector2(x, y).distance_to(center)
			if distance <= radius - 1.5:
				image.set_pixel(x, y, fill)
			elif distance <= radius - 0.5:
				image.set_pixel(x, y, outline)
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
