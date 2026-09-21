class_name DialogView
extends Control

## Shows customer speech bubbles (one per dialogue slot), the floating XP, reputation
## and tip popups, and special event windows. Placement lives in BubbleLayout and each
## bubble's lifecycle in BubbleEntry.

const SPEECH_BUBBLE_SCENE : PackedScene = preload("res://scenes/ui/speech_bubble.tscn")
const SPECIAL_EVENT_WINDOW_SCENE : PackedScene = preload("res://scenes/ui/special_event_window.tscn")

const POPUP_FLOAT_DISTANCE : float = 35.0
const POPUP_DURATION_SECONDS : float = 1.8

## Popups sit well below the speech bubble so they read as coming from the customer:
## XP highest, reputation just under it, the tip beside them.
const XP_POPUP_OFFSET : Vector2 = Vector2(0.0, -50.0)
const XP_POPUP_COLOR : Color = Color(0.949, 0.788, 0.42, 1) # same gold as BrewPreparationPanel
const XP_POPUP_FORMAT : String = "+%d XP"

const REPUTATION_POPUP_OFFSET : Vector2 = Vector2(0.0, -25.0)
const REPUTATION_POPUP_FORMAT : String = "%+d Mainetta"

const TIP_POPUP_OFFSET : Vector2 = Vector2(40.0, -50.0)
const TIP_POPUP_COLOR : Color = Color.GREEN
const TIP_POPUP_FORMAT : String = "Tippi +%.1f €"

@onready var bubble_spawn_point : Control = $BubbleSpawnPoint
@onready var special_events_container : VBoxContainer = $SpecialEventsContainer

## Dialogue slot (int) -> BubbleEntry.
var _bubbles : Dictionary = {}


func _ready() -> void:
	BrewerySignals.dialogue_pushed.connect(_on_dialogue_pushed)
	BrewerySignals.customer_evicted.connect(_on_customer_evicted)
	BrewerySignals.xp_popup_requested.connect(_on_xp_popup_requested)
	BrewerySignals.reputation_popup_requested.connect(_on_reputation_popup_requested)
	BrewerySignals.tip_popup_requested.connect(_on_tip_popup_requested)
	SpecialEventManager.special_event_triggered.connect(_on_special_event_triggered)


func _on_dialogue_pushed(text : String, is_special : bool, slot : int, speaker_pos : Vector2, display_time : float, fade_time : float) -> void:
	if not is_special:
		_show_bubble(text, slot, speaker_pos, display_time, fade_time)


## A thrown-out customer's bubble closes at once instead of finishing its fade.
func _on_customer_evicted(slot : int) -> void:
	var entry : BubbleEntry = _bubbles.get(slot)
	if entry == null:
		return
	entry.dispose()
	_bubbles.erase(slot)


func _on_special_event_triggered(event_data : SpecialEventData) -> void:
	var window : Node = SPECIAL_EVENT_WINDOW_SCENE.instantiate()
	special_events_container.add_child(window)
	window.initialize_window(event_data)


func _on_xp_popup_requested(amount : int, character_pos : Vector2) -> void:
	_float_popup(XP_POPUP_FORMAT % amount, XP_POPUP_COLOR, character_pos + XP_POPUP_OFFSET)


func _on_reputation_popup_requested(amount : int, character_pos : Vector2) -> void:
	_float_popup(REPUTATION_POPUP_FORMAT % amount, Color.GREEN if amount > 0 else Color.RED, character_pos + REPUTATION_POPUP_OFFSET)


func _on_tip_popup_requested(amount : float, character_pos : Vector2) -> void:
	_float_popup(TIP_POPUP_FORMAT % amount, TIP_POPUP_COLOR, character_pos + TIP_POPUP_OFFSET)


## A brief flourish that drifts up and fades out. Independent of the bubble slots.
func _float_popup(text : String, color : Color, global_pos : Vector2) -> void:
	var popup := Label.new()
	popup.text = text
	popup.modulate = color
	bubble_spawn_point.add_child(popup)
	popup.global_position = global_pos

	var faded : Color = color
	faded.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(popup, "global_position", global_pos + Vector2(0.0, -POPUP_FLOAT_DISTANCE), POPUP_DURATION_SECONDS)
	tween.tween_property(popup, "modulate", faded, POPUP_DURATION_SECONDS)
	tween.chain().tween_callback(popup.queue_free)


func _show_bubble(text : String, slot : int, speaker_pos : Vector2, display_time : float, fade_time : float) -> void:
	if slot < 0:
		return

	var entry : BubbleEntry = _bubbles.get(slot)
	if entry != null and entry.is_alive():
		entry.stop_fade()
		entry.bubble.modulate.a = 1.0
	else:
		entry = BubbleEntry.new(SPEECH_BUBBLE_SCENE.instantiate() as SpeechBubble)
		bubble_spawn_point.add_child(entry.bubble)
		_bubbles[slot] = entry

	entry.bubble.set_text(text)
	_place(entry, slot, speaker_pos)
	_hide_after_delay(entry, slot, entry.next_token(), display_time, fade_time)


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
