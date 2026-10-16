class_name HeatButton
extends Button

## The burner button as its own pixel frame: cold iron at rest, glowing through ember red
## to orange with the burner power, in a few hard palette steps. Iron cools slower than
## the burner and stays warm while the kettle is hot. It sinks while held (pointer or key).

## One row per heat step, coldest first: face, top edge, left edge, and the right edge with the lip.
const PALETTE : Array[Array] = [
	[Color("2e2b30"), Color("4d4852"), Color("3d3940"), Color("1c1a1f")],
	[Color("4a2a22"), Color("6e3a28"), Color("5a3226"), Color("2a1814")],
	[Color("7a2c18"), Color("b0451e"), Color("94391b"), Color("4a1a0e")],
	[Color("b4441a"), Color("e87a2c"), Color("cc5c22"), Color("6e2410")],
	[Color("e0702a"), Color("ffc060"), Color("f09038"), Color("9a3612")],
]
const OUTLINE_COLOR : Color = Color("0d0805")
const TEXT_COLOR : Color = Color(0.95, 0.9, 0.78)
const HOVER_COLOR : Color = Color(0.98, 0.85, 0.45)
const DIM_COLOR : Color = Color(0.6, 0.56, 0.5)
const TEXT_OUTLINE_COLOR : Color = Color("150e08")
const LIP : int = 2
const FONT_SIZE : int = 16
## Seconds for a full glow to fade back to cold iron.
const COOL_SECONDS : float = 1.5
## A hot kettle alone warms the button this far; only the burner makes it white hot.
const WARMTH_SHARE : float = 0.79

## The burner power, 0..1.
var heat : float = 0.0
## How hot the kettle is against its target, 0..1.
var warmth : float = 0.0
var _glow : float = 0.0
## Held down by the heating key, so it sinks as if pressed.
var held : bool = false
var label : String = ""


func _ready() -> void:
	flat = true
	focus_mode = Control.FOCUS_NONE
	text = ""


func _process(delta : float) -> void:
	_glow = maxf(heat, _glow - delta / COOL_SECONDS)
	queue_redraw()


func _draw() -> void:
	var colors : Array = PALETTE[0 if disabled else mini(int(maxf(_glow, warmth * WARMTH_SHARE) * PALETTE.size()), PALETTE.size() - 1)]
	var face : Color = colors[0]
	var top : Color = colors[1]
	var left : Color = colors[2]
	var shade : Color = colors[3]
	var w : int = int(size.x)
	var h : int = int(size.y)
	var down : bool = (held or is_pressed()) and not disabled
	draw_rect(Rect2(1, 0, w - 2, h), OUTLINE_COLOR)
	draw_rect(Rect2(0, 1, w, h - 2), OUTLINE_COLOR)
	var inner := Rect2(1, 1, w - 2, h - 2)
	draw_rect(inner, face)
	if down:
		# Pushed in: no lip, the top edge in shadow and the lit edges below.
		draw_rect(Rect2(inner.position, Vector2(inner.size.x, LIP)), shade)
		draw_rect(Rect2(inner.position.x, inner.end.y - 1, inner.size.x, 1), left)
		draw_rect(Rect2(inner.end.x - 1, inner.position.y + LIP, 1, inner.size.y - LIP), left)
	else:
		draw_rect(Rect2(inner.position.x, inner.position.y, 1, inner.size.y - LIP), left)
		draw_rect(Rect2(inner.position, Vector2(inner.size.x, 1)), top)
		draw_rect(Rect2(inner.end.x - 1, inner.position.y + 1, 1, inner.size.y - 1), shade)
		draw_rect(Rect2(inner.position.x, inner.end.y - LIP, inner.size.x, LIP), shade)
	var font : Font = get_theme_font(&"font")
	var color : Color = DIM_COLOR if disabled else (HOVER_COLOR if is_hovered() and not down else TEXT_COLOR)
	var ascent : float = font.get_ascent(FONT_SIZE)
	var baseline : float = roundf((h - LIP - font.get_height(FONT_SIZE)) / 2.0 + ascent) + (LIP if down else 0)
	var shown : String = tr(label)
	# Centred by hand on a whole pixel, so the text stays sharp.
	var origin := Vector2(roundf((w - font.get_string_size(shown, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x) / 2.0), baseline)
	draw_string_outline(font, origin, shown, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, 2, TEXT_OUTLINE_COLOR)
	draw_string(font, origin, shown, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color)
