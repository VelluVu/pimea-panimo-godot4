class_name PixelClockHand
extends Control

## The day clock's hand, drawn pixel by pixel from the hub (PixelLine), so it never bends
## the way a rotated texture does. It ticks whenever its tip reaches the next pixel.

## As in the old clockhand_32.png: a 13 px line up from a 2x2 hub in a 32 px face.
const HAND_COLOR : Color = Color8(62, 39, 49)
const HUB : Vector2i = Vector2i(16, 16)
const LENGTH : float = 13.0

var _tip : Vector2i = PixelLine.tip(HUB, 0.0, LENGTH)


## `progress` is the day's share passed, 0 to 1, once round the face.
func set_progress(progress : float) -> void:
	var tip : Vector2i = PixelLine.tip(HUB, progress * TAU, LENGTH)
	if tip != _tip:
		_tip = tip
		queue_redraw()


func _draw() -> void:
	for pixel : Vector2i in PixelLine.points(HUB, _tip):
		draw_rect(Rect2(pixel, Vector2.ONE), HAND_COLOR)
	draw_rect(Rect2(HUB - Vector2i.ONE, Vector2(2.0, 2.0)), HAND_COLOR)
