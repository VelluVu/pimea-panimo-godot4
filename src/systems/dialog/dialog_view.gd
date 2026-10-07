class_name DialogView
extends Control

## Speech bubbles (one per slot) and floating popups, independent of any game. Drive it
## with show_bubble(), close_bubble() and show_popup(). Everything that ties it to a
## project (its signals, its popup wording) lives in DialogWiring, which this adds as a child.

## A popup appeared on screen, after its delay if it had one.
signal popup_shown(emphasis : Emphasis, global_pos : Vector2)

## How loud a popup is: BIG pops in larger with an outline, CRITICAL also shakes.
enum Emphasis { NORMAL, BIG, CRITICAL }

const SPEECH_BUBBLE_SCENE : PackedScene = preload("speech_bubble.tscn")

const SPAWN_POINT_NAME : String = "BubbleSpawnPoint"
const POPUP_FLOAT_DISTANCE : float = 35.0
const POPUP_DURATION_SECONDS : float = 1.8
## Loud popups stay a little longer so they can be read after the bounce.
const LOUD_POPUP_DURATION_SECONDS : float = 2.4
## Font size multiplier per Emphasis.
const POPUP_FONT_SCALES : Array[float] = [1.0, 1.4, 1.9]
const POPUP_OUTLINE_SIZE : int = 4
const POPUP_OUTLINE_COLOR : Color = Color(0.12, 0.06, 0.0, 1.0)
const POPUP_START_SCALE : float = 0.4
## Every popup pops out a little; loud ones overshoot further.
const POPUP_BOUNCE_SCALE : float = 1.15
const LOUD_POPUP_BOUNCE_SCALE : float = 1.3
const POPUP_BOUNCE_SECONDS : float = 0.16
const POPUP_SHAKE_PIXELS : float = 3.0
const POPUP_SHAKE_STEPS : int = 6
const POPUP_SHAKE_STEP_SECONDS : float = 0.035

## Dialogue slot (int) -> BubbleEntry.
var _bubbles : Dictionary = {}
var _spawn_point : Control


func _ready() -> void:
	_spawn_point = get_node_or_null(SPAWN_POINT_NAME) as Control
	if _spawn_point == null:
		_spawn_point = Control.new()
		_spawn_point.name = SPAWN_POINT_NAME
		_spawn_point.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_spawn_point)
	var wiring := DialogWiring.new()
	wiring.name = "DialogWiring"
	add_child(wiring)


## Shows `text` in the bubble of `slot`, above `speaker_pos` (global). Showing again on
## the same slot replaces the text and restarts the timer. A negative slot is ignored.
func show_bubble(text : String, slot : int, speaker_pos : Vector2, display_time : float, fade_time : float) -> void:
	if slot < 0:
		return

	var entry : BubbleEntry = _bubbles.get(slot)
	if entry != null and entry.is_alive():
		entry.stop_fade()
		entry.bubble.modulate.a = 1.0
	else:
		entry = BubbleEntry.new(SPEECH_BUBBLE_SCENE.instantiate() as SpeechBubble)
		_spawn_point.add_child(entry.bubble)
		_bubbles[slot] = entry

	entry.bubble.set_text(text)
	_place(entry, slot, speaker_pos)
	_hide_after_delay(entry, slot, entry.next_token(), display_time, fade_time)


## Closes the bubble of `slot` at once instead of letting it finish its fade.
func close_bubble(slot : int) -> void:
	var entry : BubbleEntry = _bubbles.get(slot)
	if entry == null:
		return
	entry.dispose()
	_bubbles.erase(slot)


## A brief flourish that pops out, drifts up and fades out. Independent of the bubble
## slots. A louder `emphasis` is bigger (and shakes when CRITICAL), like a critical hit.
## With `delay_seconds` the popup waits hidden first, so popups can follow each other.
func show_popup(text : String, color : Color, global_pos : Vector2, emphasis : Emphasis = Emphasis.NORMAL, delay_seconds : float = 0.0) -> void:
	var popup := Label.new()
	popup.text = text
	popup.modulate = color
	popup.visible = false
	_spawn_point.add_child(popup)
	popup.global_position = global_pos
	if emphasis != Emphasis.NORMAL:
		_enlarge(popup, POPUP_FONT_SCALES[emphasis])
	popup.reset_size()
	popup.pivot_offset = popup.size / 2.0

	var tween := create_tween()
	if delay_seconds > 0.0:
		tween.tween_interval(delay_seconds)
	tween.tween_callback(_reveal.bind(popup, emphasis, global_pos))
	_bounce_in(tween, popup, LOUD_POPUP_BOUNCE_SCALE if emphasis != Emphasis.NORMAL else POPUP_BOUNCE_SCALE)
	if emphasis == Emphasis.CRITICAL:
		_shake(tween, popup, global_pos)

	var faded : Color = color
	faded.a = 0.0
	var duration : float = popup_duration(emphasis)
	tween.tween_property(popup, "global_position", global_pos + Vector2(0.0, -POPUP_FLOAT_DISTANCE), duration)
	tween.parallel().tween_property(popup, "modulate", faded, duration)
	tween.tween_callback(popup.queue_free)


## How long a popup floats after popping out, for chaining popups one after another.
static func popup_duration(emphasis : Emphasis) -> float:
	return POPUP_DURATION_SECONDS if emphasis == Emphasis.NORMAL else LOUD_POPUP_DURATION_SECONDS


func _reveal(popup : Label, emphasis : Emphasis, global_pos : Vector2) -> void:
	popup.show()
	popup_shown.emit(emphasis, global_pos)


func _enlarge(popup : Label, font_scale : float) -> void:
	popup.add_theme_font_size_override(&"font_size", roundi(popup.get_theme_font_size(&"font_size") * font_scale))
	popup.add_theme_constant_override(&"outline_size", POPUP_OUTLINE_SIZE)
	popup.add_theme_color_override(&"font_outline_color", POPUP_OUTLINE_COLOR)


func _bounce_in(tween : Tween, popup : Label, bounce_scale : float) -> void:
	popup.scale = Vector2.ONE * POPUP_START_SCALE
	tween.tween_property(popup, "scale", Vector2.ONE * bounce_scale, POPUP_BOUNCE_SECONDS).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, "scale", Vector2.ONE, POPUP_BOUNCE_SECONDS)


func _shake(tween : Tween, popup : Label, global_pos : Vector2) -> void:
	for step : int in POPUP_SHAKE_STEPS:
		var jolt := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * POPUP_SHAKE_PIXELS
		tween.tween_property(popup, "global_position", global_pos + jolt, POPUP_SHAKE_STEP_SECONDS)
	tween.tween_property(popup, "global_position", global_pos, POPUP_SHAKE_STEP_SECONDS)


func _place(entry : BubbleEntry, slot : int, speaker_pos : Vector2) -> void:
	var neighbors : Array[BubbleEntry] = []
	for other_slot : int in _bubbles:
		var other : BubbleEntry = _bubbles[other_slot]
		if other_slot != slot and other.is_alive():
			neighbors.append(other)

	entry.x = speaker_pos.x
	entry.height_step = BubbleLayout.choose_step(speaker_pos, neighbors)
	entry.bubble.global_position = BubbleLayout.position_for(speaker_pos, entry.height_step, entry.bubble.get_size(), get_viewport_rect().size)
	entry.bubble.z_index = slot


func _hide_after_delay(entry : BubbleEntry, slot : int, token : int, display_time : float, fade_time : float) -> void:
	await get_tree().create_timer(display_time).timeout
	if not entry.is_current(token):
		return

	if fade_time > 0.0:
		entry.fade_tween = entry.bubble.create_tween()
		entry.fade_tween.tween_property(entry.bubble, "modulate:a", 0.0, fade_time)
		await entry.fade_tween.finished
		if not entry.is_current(token):
			return

	entry.dispose()
	_bubbles.erase(slot)
