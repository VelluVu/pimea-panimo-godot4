class_name SpeechBubble
extends Control


const MIN_WIDTH : float = 60.0
const MAX_WIDTH : float = 220.0
const PADDING : float = 12.0
const TAIL_WIDTH : float = 22.0
const TAIL_HEIGHT : float = 16.0
const CORNER_RADIUS : int = 16
const BORDER_WIDTH : int = 3

const BUBBLE_COLOR : Color = Color(0.97, 0.94, 0.85)
const BORDER_COLOR : Color = Color(0.2, 0.13, 0.08)
const TEXT_COLOR : Color = Color(0.14, 0.09, 0.05)

@onready var label : Label = $Label

var bubble_style := StyleBoxFlat.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", TEXT_COLOR)
	label.add_theme_color_override("font_outline_color", BUBBLE_COLOR)
	label.add_theme_constant_override("outline_size", 0)

	bubble_style.bg_color = BUBBLE_COLOR
	bubble_style.border_color = BORDER_COLOR
	bubble_style.set_border_width_all(BORDER_WIDTH)
	bubble_style.set_corner_radius_all(CORNER_RADIUS)
	bubble_style.shadow_color = Color(0.0, 0.0, 0.0, 0.25)
	bubble_style.shadow_size = 4


func set_text(text : String) -> void:
	label.text = text
	_resize_to_fit(text)
	queue_redraw()


func _resize_to_fit(text : String) -> void:
	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")

	var natural_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var content_width := clampf(natural_size.x, MIN_WIDTH, MAX_WIDTH)

	var content_height : float = natural_size.y
	if natural_size.x > MAX_WIDTH:
		content_height = font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, content_width, font_size).y

	var body_width := content_width + PADDING * 2.0
	var body_height := content_height + PADDING * 2.0

	size = Vector2(body_width, body_height + TAIL_HEIGHT)
	custom_minimum_size = size

	label.offset_left = PADDING
	label.offset_top = PADDING
	label.offset_right = -PADDING
	label.offset_bottom = -(PADDING + TAIL_HEIGHT)


func _draw() -> void:
	var body_height := size.y - TAIL_HEIGHT
	draw_style_box(bubble_style, Rect2(Vector2.ZERO, Vector2(size.x, body_height)))

	var tip := Vector2(size.x * 0.5, size.y)
	var base_left := Vector2(size.x * 0.5 - TAIL_WIDTH * 0.5, body_height)
	var base_right := Vector2(size.x * 0.5 + TAIL_WIDTH * 0.5, body_height)

	draw_colored_polygon(PackedVector2Array([base_left, base_right, tip]), BUBBLE_COLOR)
	draw_polyline(PackedVector2Array([base_left, tip, base_right]), BORDER_COLOR, BORDER_WIDTH, true)
