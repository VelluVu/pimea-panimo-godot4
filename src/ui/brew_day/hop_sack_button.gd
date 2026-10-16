class_name HopSackButton
extends Button

## A sack beside the kettle: its sprite emptying in three steps, its pellet colour, key,
## name and amount left. Holding it pours; lifted, only its shadow stays. A sack whose
## mark is coming wobbles with a yellow frame; while the mark is open it blinks green.

const ART : BrewDayArt = preload("res://src/resources/brew_day/brew_day_art.tres")
const SIZE : Vector2 = Vector2(124, 40)
const FRAMES : int = 3
## Above these shares of the sack left, the full or the half frame shows.
const FULL_FROM : float = 0.66
const HALF_FROM : float = 0.2
## Where each frame's neck shows the pellets' colour, in sprite pixels.
const NECK_TOPS : Array[int] = [1, 6, 10]
const NECK_PELLETS : Rect2 = Rect2(7, 0, 6, 2)
const SHADOW_MODULATE : Color = Color(0.3, 0.3, 0.3)
const TEXT_X : float = 40.0
const FONT_SIZE : int = 16
const TEXT_COLOR : Color = Color(0.95, 0.9, 0.78)
const DIM_COLOR : Color = Color(0.6, 0.56, 0.5)
const HOVER_COLOR : Color = Color(0.98, 0.85, 0.45)
const SOON_COLOR : Color = Color(0.98, 0.8, 0.3)
const NOW_COLOR : Color = Color(0.5, 1.0, 0.45)
const CUE_BLINK_FPS : float = 8.0

enum Cue { NONE, SOON, NOW }

## 0 for a sack without a key (the malts).
var key_number : int = 1
var sack_name : String = ""
var amount_text : String = ""
## 0..1 of the sack still full.
var fill : float = 1.0
var lifted : bool = false
var pellet_color : Color = Color.GREEN
var cue : Cue = Cue.NONE
## The sack's mark ("AROMI"), shown before the amount; brighter while cued.
var cue_label : String = ""


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
	var scale : float = BrewDayArt.PROP_SCALE
	var blink : bool = int(Time.get_ticks_msec() / 1000.0 * CUE_BLINK_FPS) % 2 == 0
	var wobble := Vector2.ZERO
	if cue != Cue.NONE and not lifted:
		wobble.x = 1.0 if blink else -1.0
	draw_texture_rect_region(ART.sack, Rect2(wobble, frame_size * scale), region, SHADOW_MODULATE if lifted else Color.WHITE)
	if not lifted and fill > 0.0:
		var neck := Rect2((NECK_PELLETS.position + Vector2(0, NECK_TOPS[frame])) * scale + wobble, NECK_PELLETS.size * scale)
		draw_rect(neck, pellet_color)
	var cue_color : Color = SOON_COLOR if cue == Cue.SOON else NOW_COLOR
	if cue != Cue.NONE and not lifted and (cue == Cue.SOON or blink):
		draw_rect(Rect2(Vector2.ZERO, frame_size * scale).grow(-1), cue_color, false, 2.0)
	var color : Color = DIM_COLOR if disabled else (HOVER_COLOR if is_hovered() else TEXT_COLOR)
	var font : Font = get_theme_font(&"font", &"Label")
	var width : float = SIZE.x - TEXT_X
	var first_line : String = sack_name if key_number <= 0 else "%d %s" % [key_number, sack_name]
	draw_string(font, Vector2(TEXT_X, 17), first_line, HORIZONTAL_ALIGNMENT_LEFT, width, FONT_SIZE, color)
	var second_line : String = amount_text if cue_label.is_empty() else cue_label + " " + amount_text
	if cue != Cue.NONE:
		color = cue_color
	draw_string(font, Vector2(TEXT_X, 34), second_line, HORIZONTAL_ALIGNMENT_LEFT, width, FONT_SIZE, color)
