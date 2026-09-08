class_name DialogView
extends Control


const WARNING_CUSTOMER_MANAGER_NOT_FOUND : String = "DialogView: CustomerManager Autoload not found!"

const SPEECH_BUBBLE_SCENE : PackedScene = preload("res://scenes/ui/speech_bubble.tscn")
const SPECIAL_EVENT_WINDOW_SCENE : PackedScene = preload("res://scenes/ui/special_event_window.tscn")

const BUBBLE_OFFSET_Y : float = -180.0
const BUBBLE_STAIR_STEP : float = 34.0
const BUBBLE_MIN_VISIBLE_Y : float = 38.0

@onready var bubble_spawn_point: Control = $BubbleSpawnPoint
@onready var special_events_container: VBoxContainer = $SpecialEventsContainer

var active_slot_bubbles: Dictionary = {}
var slot_display_tokens: Dictionary = {} # Avain: int (slot) -> Arvo: int (kasvava tunniste)


func _ready() -> void:
	BrewerySignals.dialogue_pushed.connect(_on_dialogue_pushed)
	SpecialEventManager.special_event_triggered.connect(_on_special_event_triggered)
	

func _on_customer_ready_at_counter(_customer: CustomerData, _character_global_pos: Vector2, _slot: int) -> void:
	pass


func _on_special_event_triggered(event_data: SpecialEventData) -> void:
	var window = SPECIAL_EVENT_WINDOW_SCENE.instantiate()
	special_events_container.add_child(window)
	window.initialize_window(event_data)


func _on_dialogue_pushed(text: String, is_special: bool, slot: int, character_global_pos: Vector2, display_time: float, fade_time: float) -> void:
	if not is_special:
		_update_or_create_speech_bubble(text, slot, character_global_pos, display_time, fade_time)


func _update_or_create_speech_bubble(text: String, slot: int, character_global_pos: Vector2, display_time: float, fade_time: float) -> void:
	if slot < 0:
		return

	var token : int = slot_display_tokens.get(slot, 0) + 1
	slot_display_tokens[slot] = token

	if active_slot_bubbles.has(slot) and is_instance_valid(active_slot_bubbles[slot]):
		var existing_bubble = active_slot_bubbles[slot]
		existing_bubble.modulate.a = 1.0
		_set_bubble_text(existing_bubble, text)
		_place_bubble(existing_bubble, slot, character_global_pos)
		_hide_bubble_after_delay(existing_bubble, slot, token, display_time, fade_time)
		return

	var bubble = SPEECH_BUBBLE_SCENE.instantiate()
	bubble_spawn_point.add_child(bubble)
	active_slot_bubbles[slot] = bubble

	_set_bubble_text(bubble, text)
	_place_bubble(bubble, slot, character_global_pos)

	_hide_bubble_after_delay(bubble, slot, token, display_time, fade_time)


func _place_bubble(bubble: Node, slot: int, character_global_pos: Vector2) -> void:
	var bubble_size : Vector2 = bubble.get_size()
	var base_y : float = character_global_pos.y + BUBBLE_OFFSET_Y
	var max_steps : int = maxi(0, floori((base_y - BUBBLE_MIN_VISIBLE_Y) / BUBBLE_STAIR_STEP))
	var step_index : int = _get_zigzag_step(slot, max_steps)
	var target_y : float = base_y - step_index * BUBBLE_STAIR_STEP

	bubble.global_position = Vector2(character_global_pos.x - bubble_size.x * 0.5, target_y)
	bubble.z_index = slot


func _get_zigzag_step(slot: int, max_steps: int) -> int:
	if max_steps <= 0:
		return 0

	var period : int = max_steps * 2
	var phase : int = slot % period

	if phase <= max_steps:
		return phase

	return period - phase


func _set_bubble_text(bubble: Node, text: String) -> void:
	if bubble.has_method("set_text"):
		bubble.set_text(text)
	elif bubble.has_node("Label"):
		var label = bubble.get_node("Label") as Label
		label.text = text
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _hide_bubble_after_delay(bubble: Node, slot: int, token: int, display_time: float, fade_time: float) -> void:
	await get_tree().create_timer(display_time).timeout

	if not _bubble_still_current(bubble, slot, token):
		return

	if fade_time > 0.0 and bubble is CanvasItem:
		var tween := bubble.create_tween()
		tween.tween_property(bubble, "modulate:a", 0.0, fade_time)
		await tween.finished

	if not _bubble_still_current(bubble, slot, token):
		return

	bubble.queue_free()
	active_slot_bubbles.erase(slot)
	slot_display_tokens.erase(slot)


func _bubble_still_current(bubble: Node, slot: int, token: int) -> bool:
	if slot_display_tokens.get(slot, -1) != token:
		return false

	return is_instance_valid(bubble) and active_slot_bubbles.get(slot) == bubble
