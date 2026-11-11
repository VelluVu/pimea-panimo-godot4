class_name StrikeThrough
extends Control

## A line through a right-aligned label's text, after its mark. Labels cannot strike text
## themselves; this child draws it in the label's colour.

## Through the middle of m5x7's lower-case letters, which stand 4 rows on the baseline.
const ROWS_ABOVE_BASELINE : float = 3.0

var _label : Label
var _prefix : String = ""


static func attach(label : Label) -> StrikeThrough:
	var line := StrikeThrough.new()
	line._label = label
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.visible = false
	line.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.add_child(line)
	label.resized.connect(line.queue_redraw)
	return line


## `prefix` is the mark at the start of the text, which stays unstruck.
func strike(active : bool, prefix : String = "") -> void:
	visible = active
	_prefix = prefix
	queue_redraw()


func _draw() -> void:
	var font : Font = _label.get_theme_font(&"font")
	var font_size : int = _label.get_theme_font_size(&"font_size")
	var text_width : float = font.get_string_size(_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var prefix_width : float = font.get_string_size(_prefix, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x if not _prefix.is_empty() else 0.0
	var span : Vector2 = GoalMarks.strike_span(_label.size.x, text_width, prefix_width)
	if span.y <= span.x:
		return
	var baseline : float = floorf((_label.size.y - font.get_height(font_size)) / 2.0) + font.get_ascent(font_size)
	draw_rect(Rect2(span.x, baseline - ROWS_ABOVE_BASELINE, span.y - span.x, 1), _label.get_theme_color(&"font_color"))
