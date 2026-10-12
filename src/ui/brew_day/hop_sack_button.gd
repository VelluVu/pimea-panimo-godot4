class_name HopSackButton
extends Button

## A hop or spice sack standing beside the kettle, drawn with placeholder shapes: a
## burlap sack that shrinks as it empties, the pellets showing at its mouth, its key
## number, name and what is left. Holding it pours; while it is lifted over the kettle
## (KettleView draws that) only an empty outline stays in its place.

const SIZE : Vector2 = Vector2(104, 40)
const SACK_RECT : Rect2 = Rect2(4, 6, 30, 32)
const NECK_SIZE : Vector2 = Vector2(16, 6)
## An empty sack keeps this much of its height.
const MIN_FILL : float = 0.4
const TEXT_X : float = 40.0
const FONT_SIZE : int = 16
const SACK_COLOR : Color = Color(0.62, 0.5, 0.32)
const SACK_SHADE : Color = Color(0.45, 0.35, 0.2)
const TIE_COLOR : Color = Color(0.3, 0.22, 0.12)
const TEXT_COLOR : Color = Color(0.95, 0.9, 0.78)
const DIM_COLOR : Color = Color(0.6, 0.56, 0.5)
const HOVER_COLOR : Color = Color(0.98, 0.85, 0.45)

var key_number : int = 1
var sack_name : String = ""
var amount_text : String = ""
## 0..1 of the sack still full.
var fill : float = 1.0
var lifted : bool = false
var pellet_color : Color = Color.GREEN


func _ready() -> void:
	flat = true
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = SIZE
	text = ""


func _process(_delta : float) -> void:
	queue_redraw()


func _draw() -> void:
	var height : float = roundf(SACK_RECT.size.y * lerpf(MIN_FILL, 1.0, clampf(fill, 0.0, 1.0)))
	var body := Rect2(SACK_RECT.position.x, SACK_RECT.end.y - height, SACK_RECT.size.x, height)
	if lifted:
		draw_rect(body, SACK_SHADE, false, 1.0)
	else:
		draw_rect(body.grow(1), TIE_COLOR)
		draw_rect(body, SACK_COLOR)
		draw_rect(Rect2(body.position + Vector2(body.size.x - 6, 0), Vector2(6, body.size.y)), SACK_SHADE)
		var neck := Rect2(body.get_center().x - NECK_SIZE.x / 2.0, body.position.y - NECK_SIZE.y + 1, NECK_SIZE.x, NECK_SIZE.y)
		draw_rect(neck, pellet_color if fill > 0.0 else SACK_SHADE)
		draw_rect(Rect2(neck.position.x - 1, neck.end.y - 1, neck.size.x + 2, 2), TIE_COLOR)
	var color : Color = DIM_COLOR if disabled else (HOVER_COLOR if is_hovered() else TEXT_COLOR)
	var font : Font = get_theme_font(&"font", &"Label")
	var width : float = SIZE.x - TEXT_X
	draw_string(font, Vector2(TEXT_X, 17), "%d %s" % [key_number, sack_name], HORIZONTAL_ALIGNMENT_LEFT, width, FONT_SIZE, color)
	draw_string(font, Vector2(TEXT_X, 34), amount_text, HORIZONTAL_ALIGNMENT_LEFT, width, FONT_SIZE, color)
