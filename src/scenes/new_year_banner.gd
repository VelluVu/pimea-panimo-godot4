@tool
class_name NewYearBanner
extends Node2D

## A party banner of pennants on a string, one letter on each (PennantLayout): HYVÄÄ UUTTA
## VUOTTA, or with `shows_year` the year New Year greets, from the player's clock. Drawn at
## the room art's scale (1 px) in the game font, so the greeting is translated. Light from
## above left: each pennant's right column and point are its shade.

const GREETING : String = "HYVÄÄ UUTTA VUOTTA"
const THEME : Theme = preload("res://src/resources/themes/main_theme.tres")
## The pennant's rows as (indent, width): a body as tall as a letter and its dots, then
## a point. Each row's last pixel is the shade.
const PENNANT_ROWS : Array[Vector2i] = [
	Vector2i(0, 7), Vector2i(0, 7), Vector2i(0, 7), Vector2i(0, 7), Vector2i(0, 7),
	Vector2i(0, 7), Vector2i(0, 7), Vector2i(0, 7), Vector2i(0, 7), Vector2i(0, 7),
	Vector2i(1, 5), Vector2i(2, 3), Vector2i(3, 1),
]
## [colour, shade] pairs in turn, ENDESGA 32; light enough for the dark letters.
const COLOURS : Array = [
	[Color("fee761"), Color("feae34")],
	[Color("2ce8f5"), Color("0099db")],
	[Color("f6757a"), Color("b55088")],
	[Color("63c74d"), Color("3e8948")],
]
const LETTER_COLOR : Color = Color("181425")
const STRING_COLOR : Color = Color("8b9bb4")
const NAIL_COLOR : Color = Color("3a4466")
## The string reaches this far past the outer pennants to its nails.
const STRING_OVERHANG : int = 3
## The letter's baseline, rows below the pennant's top: low enough that the dots of an Ä
## land on the pennant's top row instead of on the string.
const BASELINE_ROW : int = 9

@export var shows_year : bool = false:
	set(value):
		shows_year = value
		queue_redraw()
## Which colour pair the first pennant takes, so two banners do not start alike.
@export var first_colour : int = 0:
	set(value):
		first_colour = value
		queue_redraw()


func _draw() -> void:
	var text : String = _text()
	var total : int = PennantLayout.width(text)
	for x : int in range(-STRING_OVERHANG, total + STRING_OVERHANG):
		_pixel(Vector2i(x, PennantLayout.sag(clampi(x, 0, total - 1), total)), STRING_COLOR)
	_pixel(Vector2i(-STRING_OVERHANG - 1, 0), NAIL_COLOR)
	_pixel(Vector2i(total + STRING_OVERHANG, 0), NAIL_COLOR)
	var font : Font = THEME.default_font
	var size : int = THEME.default_font_size
	var slots : Array = PennantLayout.slots(text)
	for index : int in slots.size():
		var x : int = slots[index][0]
		var top : int = PennantLayout.sag(x + PennantLayout.PENNANT_WIDTH / 2, total) + 1
		var pair : Array = COLOURS[(index + first_colour) % COLOURS.size()]
		_draw_pennant(Vector2i(x, top), pair[0], pair[1])
		var character : String = slots[index][1]
		var glyph_width : int = roundi(font.get_char_size(character.unicode_at(0), size).x)
		var left : int = x + (PennantLayout.PENNANT_WIDTH - glyph_width + 1) / 2
		draw_char(font, Vector2(left, top + BASELINE_ROW), character, size, LETTER_COLOR)


func _text() -> String:
	if shows_year:
		return str(SeasonRules.new_year_number(Time.get_date_dict_from_system()))
	return tr(GREETING)


func _draw_pennant(at : Vector2i, colour : Color, shade : Color) -> void:
	for row : int in PENNANT_ROWS.size():
		var span : Vector2i = PENNANT_ROWS[row]
		for column : int in range(span.x, span.x + span.y):
			_pixel(at + Vector2i(column, row), shade if column == span.x + span.y - 1 else colour)


func _pixel(at : Vector2i, color : Color) -> void:
	draw_rect(Rect2(Vector2(at), Vector2.ONE), color)
