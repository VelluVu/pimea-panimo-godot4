class_name DialogView
extends Control

## Speech bubbles (one per slot) and floating popups, independent of any game. Drive it
## with show_bubble(), close_bubble() and show_popup(). Everything that ties it to a
## project (its signals, its popup wording) lives in DialogWiring, which this adds as a child.

const SPEECH_BUBBLE_SCENE : PackedScene = preload("speech_bubble.tscn")

const SPAWN_POINT_NAME : String = "BubbleSpawnPoint"
const POPUP_FLOAT_DISTANCE : float = 35.0
const POPUP_DURATION_SECONDS : float = 1.8

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


## A brief flourish that drifts up and fades out. Independent of the bubble slots.
func show_popup(text : String, color : Color, global_pos : Vector2) -> void:
	var popup := Label.new()
	popup.text = text
	popup.modulate = color
	_spawn_point.add_child(popup)
	popup.global_position = global_pos

	var faded : Color = color
	faded.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(popup, "global_position", global_pos + Vector2(0.0, -POPUP_FLOAT_DISTANCE), POPUP_DURATION_SECONDS)
	tween.tween_property(popup, "modulate", faded, POPUP_DURATION_SECONDS)
	tween.chain().tween_callback(popup.queue_free)


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
