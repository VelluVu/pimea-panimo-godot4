class_name HopSackButton
extends Button

## A hop or spice sack standing beside the kettle: its sprite (BrewDayArt.sack) going
## from full to half to almost empty, the pellets' colour showing at its neck, its key
## number, name and what is left. Holding it pours; while it is lifted over the kettle
## (KettleView draws that) only a dark shadow stays in its place.

const ART : BrewDayArt = preload("res://src/resources/brew_day/brew_day_art.tres")
const SIZE : Vector2 = Vector2(104, 40)
const FRAMES : int = 3
## Above these shares of the sack left, the full or the half frame shows.
const FULL_FROM : float = 0.66
const HALF_FROM : float = 0.2
## The top of each frame's neck, where the pellets' colour is painted in.
const NECK_TOPS : Array[int] = [1, 11, 20]
const NECK_PELLETS : Rect2 = Rect2(12, 1, 14, 3)
const SHADOW_MODULATE : Color = Color(0.3, 0.3, 0.3)
const TEXT_X : float = 40.0
const FONT_SIZE : int = 16
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
	var frame : int = 0 if fill > FULL_FROM else (1 if fill > HALF_FROM else 2)
	var frame_size := Vector2(ART.sack.get_width() / float(FRAMES), ART.sack.get_height())
	var region := Rect2(Vector2(frame * frame_size.x, 0), frame_size)
	draw_texture_rect_region(ART.sack, Rect2(Vector2.ZERO, frame_size), region, SHADOW_MODULATE if lifted else Color.WHITE)
	if not lifted and fill > 0.0:
		draw_rect(Rect2(NECK_PELLETS.position + Vector2(0, NECK_TOPS[frame]), NECK_PELLETS.size), pellet_color)
	var color : Color = DIM_COLOR if disabled else (HOVER_COLOR if is_hovered() else TEXT_COLOR)
	var font : Font = get_theme_font(&"font", &"Label")
	var width : float = SIZE.x - TEXT_X
	draw_string(font, Vector2(TEXT_X, 17), "%d %s" % [key_number, sack_name], HORIZONTAL_ALIGNMENT_LEFT, width, FONT_SIZE, color)
	draw_string(font, Vector2(TEXT_X, 34), amount_text, HORIZONTAL_ALIGNMENT_LEFT, width, FONT_SIZE, color)
