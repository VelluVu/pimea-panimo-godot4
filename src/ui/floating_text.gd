class_name FloatingText
extends RefCounted

## A short label that rises off a button and fades: the "-8,00 €" of a purchase, or why a
## press did nothing. Pixel-stepped, so the font stays sharp while it moves.

const DURATION_SECONDS : float = 1.8
const FLOAT_DISTANCE : float = 35.0
## Why a press did nothing: readable on the dark panel, apart from the red of a cost.
const REASON_COLOR : Color = Color(1.0, 0.85, 0.45, 1.0)


## Floats `text` up from the top of `anchor`, centred, so it never covers the button
## beside it.
static func rise(anchor : Control, text : String, color : Color) -> void:
	var popup := Label.new()
	popup.text = text
	popup.modulate = color
	anchor.add_child(popup)
	var text_size : Vector2 = popup.get_minimum_size()
	popup.position = Vector2(floorf((anchor.size.x - text_size.x) / 2.0), -text_size.y)

	var tween : Tween = anchor.create_tween().set_parallel(true)
	var faded : Color = popup.modulate
	faded.a = 0.0
	PixelStepTween.move_property(tween, popup, &"position", popup.position, popup.position + Vector2(0, -FLOAT_DISTANCE), DURATION_SECONDS)
	tween.tween_property(popup, "modulate", faded, DURATION_SECONDS)
	tween.chain().tween_callback(popup.queue_free)


static func reason(anchor : Control, text : String) -> void:
	rise(anchor, text, REASON_COLOR)
