class_name ThermoColumn
extends Control

## The brew day's information column beside the kettle, all of it around one vertical
## thermometer: the accuracy and clumps on top, the needle and target band on the bar,
## the steps (mash) or hop marks (boil) beside it, the burner strip under it.

const BAR_RECT : Rect2 = Rect2(8, 34, 16, 176)
const FLAME_RECT : Rect2 = Rect2(8, 214, 16, 6)
const MASH_RANGE : Vector2 = Vector2(20, 80)
const BOIL_RANGE : Vector2 = Vector2(90, 106)
const NEAR : float = 3.0
const ROW_X : float = 32.0
const ROW_HEIGHT : float = 16.0
const BAR_COLOR : Color = Color(0.12, 0.1, 0.11)
const BAND_COLOR : Color = Color(0.3, 0.75, 0.35, 0.45)
const FOAM_ZONE_COLOR : Color = Color(0.9, 0.5, 0.2, 0.35)
const GREEN : Color = Color(0.45, 0.9, 0.45)
const YELLOW : Color = Color(0.95, 0.8, 0.3)
const RED : Color = Color(0.95, 0.35, 0.3)
const TEXT_COLOR : Color = Color(0.95, 0.9, 0.78)
const DIM_COLOR : Color = Color(0.6, 0.56, 0.5)
const FLAME_COLOR : Color = Color(0.98, 0.55, 0.15)
const FONT_SIZE : int = 16

const ACCURACY_TEXT : String = "Lämpötilassa %d %%"
const CLUMPS_TEXT : String = "Paakkuja: %d"
const MALT_MARKER_TEXT : String = "Mallas %d°"
const STEP_TEXT : String = "%d° · %d s"
const TIMER_TEXT : String = "%.1f s"
const FOAM_TEXT : String = "Vaahto %d %%"
const BITTERING_TEXT : String = "KATKERO"
const FLAVOR_TEXT : String = "MAKU"
const AROMA_TEXT : String = "AROMI"
const SPICE_TEXT : String = "MAUSTE"
const MARK_TEXT : String = "%s %d %s"

var mash : MashSession
var boil : BoilSession
var piece_ids : Array[int] = []


func _ready() -> void:
	custom_minimum_size = Vector2(150, 230)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta : float) -> void:
	if is_visible_in_tree():
		queue_redraw()


## The needle's colour: in the band, close to it, or far off.
static func needle_color(distance_out : float) -> Color:
	if distance_out <= 0.0:
		return GREEN
	return YELLOW if distance_out <= NEAR else RED


func current_needle_color() -> Color:
	if boil != null:
		var temperature : float = boil.heat.temperature
		var out : float = maxf(BoilSession.BOIL_MIN - temperature, temperature - BoilSession.FOAM_FROM)
		return needle_color(out)
	if mash != null:
		return needle_color(absf(mash.heat.temperature - mash.target()) - mash.band)
	return GREEN


func _draw() -> void:
	if boil != null:
		_draw_boil()
	elif mash != null:
		_draw_mash()


func _draw_mash() -> void:
	if mash.phase != MashSession.Phase.WATER:
		_text(Vector2(0, 12), tr(ACCURACY_TEXT) % roundi(mash.accuracy() * 100.0), TEXT_COLOR)
	if mash.clumps_left() > 0:
		_text(Vector2(0, 28), tr(CLUMPS_TEXT) % mash.clumps_left(), YELLOW)
	draw_rect(BAR_RECT, BAR_COLOR)
	var target : float = mash.target()
	_band(MASH_RANGE, target - mash.band, target + mash.band, BAND_COLOR)
	var rows : int = 0
	if mash.phase == MashSession.Phase.WATER:
		_row(rows, tr(MALT_MARKER_TEXT) % roundi(mash.malt_marker()), TEXT_COLOR)
		rows += 1
	for i : int in mash.steps.size():
		var color : Color = DIM_COLOR
		if mash.phase != MashSession.Phase.WATER and i == mash.step_index and mash.phase != MashSession.Phase.DONE:
			color = TEXT_COLOR
		elif mash.phase == MashSession.Phase.DONE or i < mash.step_index:
			color = GREEN
		_row(rows, tr(STEP_TEXT) % [roundi(mash.steps[i]), roundi(mash.step_seconds[i])], color)
		_tick(MASH_RANGE, mash.steps[i], color)
		rows += 1
	if mash.phase == MashSession.Phase.HOLD:
		var left : float = maxf(0.0, mash.step_seconds[mash.step_index] - mash.step_elapsed)
		_row(rows + 1, tr(TIMER_TEXT) % left, TEXT_COLOR)
	_needle(MASH_RANGE, mash.heat.temperature)
	_flame(mash.heat.power)


func _draw_boil() -> void:
	_text(Vector2(0, 12), tr(FOAM_TEXT) % roundi(boil.foam * 100.0), RED if boil.foam > 0.6 else TEXT_COLOR)
	draw_rect(BAR_RECT, BAR_COLOR)
	_band(BOIL_RANGE, BoilSession.BOIL_MIN, BoilSession.FOAM_FROM, BAND_COLOR)
	_band(BOIL_RANGE, BoilSession.FOAM_FROM, BOIL_RANGE.y, FOAM_ZONE_COLOR)
	var left : float = maxf(0.0, BoilSchedule.BOIL_SECONDS - boil.counted)
	var timer_color : Color = TEXT_COLOR if boil.is_boiling() else DIM_COLOR
	# In the hop stand the timer counts the stand down, in flame colour.
	if boil.phase == BoilSession.Phase.HOP_STAND:
		left = maxf(0.0, BoilSchedule.end_time() - boil.counted)
		timer_color = FLAME_COLOR
	_row(0, tr(TIMER_TEXT) % left, timer_color)
	for i : int in boil.marks.size():
		var mark : BoilMark = boil.marks[i]
		var unit : String = StringContainer.KPL if piece_ids.has(mark.ingredient_id) else StringContainer.G
		var text : String = tr(MARK_TEXT) % [kind_label(mark.kind), mark.grams, tr(unit)]
		_row(i + 2, text, _mark_color(mark))
	_needle(BOIL_RANGE, boil.heat.temperature)
	_flame(boil.heat.power)


static func kind_label(kind : HopAddition.Kind) -> String:
	match kind:
		HopAddition.Kind.BITTERING: return UiText.of(BITTERING_TEXT)
		HopAddition.Kind.FLAVOR: return UiText.of(FLAVOR_TEXT)
		HopAddition.Kind.AROMA: return UiText.of(AROMA_TEXT)
		HopAddition.Kind.SPICE: return UiText.of(SPICE_TEXT)
		_: return ""


func _mark_color(mark : BoilMark) -> Color:
	match mark.result:
		BoilMark.Result.FULL: return GREEN
		BoilMark.Result.HALF: return YELLOW
		BoilMark.Result.MISS: return RED
	if boil.is_boiling() and BoilSchedule.in_window(mark.kind, boil.counted, boil.window_widen):
		# Blinks in steps while its window is open.
		return TEXT_COLOR if floori(Time.get_ticks_msec() / 150.0) % 2 == 0 else FLAME_COLOR
	return DIM_COLOR


func _y_for(range_c : Vector2, temperature : float) -> float:
	var t : float = clampf((temperature - range_c.x) / (range_c.y - range_c.x), 0.0, 1.0)
	return roundf(BAR_RECT.end.y - t * BAR_RECT.size.y)


func _band(range_c : Vector2, low : float, high : float, color : Color) -> void:
	var top : float = _y_for(range_c, high)
	var bottom : float = _y_for(range_c, low)
	draw_rect(Rect2(BAR_RECT.position.x, top, BAR_RECT.size.x, bottom - top), color)


func _tick(range_c : Vector2, temperature : float, color : Color) -> void:
	var y : float = _y_for(range_c, temperature)
	draw_line(Vector2(BAR_RECT.end.x, y), Vector2(BAR_RECT.end.x + 4, y), color, 1.0)


func _needle(range_c : Vector2, temperature : float) -> void:
	var y : float = _y_for(range_c, temperature)
	var color : Color = current_needle_color()
	draw_rect(Rect2(BAR_RECT.position.x - 3, y - 1, BAR_RECT.size.x + 6, 3), color)


func _flame(power : float) -> void:
	draw_rect(FLAME_RECT, BAR_COLOR)
	draw_rect(Rect2(FLAME_RECT.position, Vector2(roundf(FLAME_RECT.size.x * clampf(power, 0.0, 1.0)), FLAME_RECT.size.y)), FLAME_COLOR)


func _row(index : int, text : String, color : Color) -> void:
	_text(Vector2(ROW_X, BAR_RECT.position.y + 10 + index * ROW_HEIGHT), text, color)


func _text(at : Vector2, text : String, color : Color) -> void:
	draw_string(get_theme_font(&"font", &"Label"), at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color)
