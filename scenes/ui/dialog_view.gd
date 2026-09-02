class_name DialogView
extends Control


const WARNING_CUSTOMER_MANAGER_NOT_FOUND : String = "DialogView: CustomerManager Autoload not found!"

const DISPLAY_TIME_SECONDS : float = 10.0
const FADE_OUT_TIME_SECONDS : float = 3.5

const SPEECH_BUBBLE_SCENE : PackedScene = preload("res://scenes/ui/speech_bubble.tscn")
const SPECIAL_EVENT_WINDOW_SCENE : PackedScene = preload("res://scenes/ui/special_event_window.tscn")

const BUBBLE_OFFSET_Y : float = -248.0

@onready var special_events_container: VBoxContainer = $SpecialEventsContainer	
@onready var bubble_spawn_point: Control = $BubbleSpawnPoint

var active_slot_bubbles: Dictionary = {}


func _ready() -> void:
	BrewerySignals.dialogue_pushed.connect(_on_dialogue_pushed)
	SpecialEventManager.special_event_triggered.connect(_on_special_event_triggered)
	

func _on_customer_ready_at_counter(_customer: CustomerData, _character_global_pos: Vector2, _slot: int) -> void:
	pass


func _on_special_event_triggered(event_data: SpecialEventData) -> void:
	if special_events_container == null: return
	
	var window = SPECIAL_EVENT_WINDOW_SCENE.instantiate()
	special_events_container.add_child(window)
	window.initialize_window(event_data)


func _on_dialogue_pushed(text: String, is_special: bool, slot: int, character_global_pos: Vector2) -> void:
	if not is_special:
		_update_or_create_speech_bubble(text, slot, character_global_pos)


func _update_or_create_speech_bubble(text: String, slot: int, character_global_pos: Vector2) -> void:
	if slot < 0:
		return
		
	if active_slot_bubbles.has(slot) and is_instance_valid(active_slot_bubbles[slot]):
		var existing_bubble = active_slot_bubbles[slot]
		_set_bubble_text(existing_bubble, text)
		_fade_out_bubble_delayed(existing_bubble, slot)
		return
		
	var bubble = SPEECH_BUBBLE_SCENE.instantiate()
	bubble_spawn_point.add_child(bubble)
	active_slot_bubbles[slot] = bubble
	
	_set_bubble_text(bubble, text)
	
	bubble.global_position = character_global_pos + Vector2(-bubble.get_size().x * 0.5, BUBBLE_OFFSET_Y)
	
	_fade_out_bubble_delayed(bubble, slot)


func _set_bubble_text(bubble: Node, text: String) -> void:
	if bubble.has_method("set_text"):
		bubble.set_text(text)
	elif bubble.has_node("Label"):
		var label = bubble.get_node("Label") as Label
		label.text = text
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _fade_out_bubble_delayed(bubble: Node, slot: int) -> void:
	await get_tree().create_timer(DISPLAY_TIME_SECONDS).timeout
	
	if is_instance_valid(bubble) and active_slot_bubbles.get(slot) == bubble:
		bubble.queue_free()
		active_slot_bubbles.erase(slot)
