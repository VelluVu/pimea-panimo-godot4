class_name DialogView
extends Control


const SET_TEXT_METHOD_NAME : String = "set_text"
const LABEL_COMPONENT_NAME : String = "Label"
const PATH_CUSTOMER_MANAGER = "/root/CustomerManager"
const WARNING_CUSTOMER_MANAGER_NOT_FOUND = "DialogView: CustomerManager Autoload not found!"

const DISPLAY_TIME_SECONDS = 3.5

const SPEECH_BUBBLE_SCENE = preload("res://scenes/ui/speech_bubble.tscn")

const BUBBLE_OFFSET_Y = -180.0

@export var counter_positions_parent: Node

@onready var bubble_spawn_point: Control = $BubbleSpawnPoint
@onready var special_panel: Panel = $SpecialPanel
@onready var special_label: Label = $SpecialPanel/SpecialLabel
@onready var accept_button: Button = $SpecialPanel/AcceptButton
@onready var reject_button: Button = $SpecialPanel/RejectButton

var special_fade_timer: Timer
var counter_markers: Array[Node2D] = []
var active_slot_bubbles: Dictionary = {}


func _ready() -> void:
	_setup_timers()
	_setup_positions()
	_setup_label_wrapping()
	
	if has_node(PATH_CUSTOMER_MANAGER):
		var cm = get_node(PATH_CUSTOMER_MANAGER)
		cm.customer_arrived.connect(_on_customer_arrived)
		cm.dialogue_pushed.connect(_on_dialogue_pushed)
		
		accept_button.pressed.connect(
			func():
				_hide_special_buttons()
				cm.accept_special_request()
		)
		reject_button.pressed.connect(
			func():
				_hide_special_buttons()
				cm.reject_special_request()
		)
	else:
		push_warning(WARNING_CUSTOMER_MANAGER_NOT_FOUND)
		
	special_panel.visible = false


func _setup_timers() -> void:
	special_fade_timer = Timer.new()
	special_fade_timer.process_callback = Timer.TIMER_PROCESS_IDLE
	special_fade_timer.one_shot = true
	special_fade_timer.timeout.connect(_on_special_fade_timeout)
	add_child(special_fade_timer)


func _setup_positions() -> void:
	if counter_positions_parent:
		for child in counter_positions_parent.get_children():
			if child is Node2D:
				counter_markers.append(child)


func _setup_label_wrapping() -> void:
	special_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _on_customer_arrived(_customer: CustomerData, is_special: bool, _slot: int) -> void:
	if is_special:
		special_fade_timer.stop()
		accept_button.visible = true
		reject_button.visible = true
		special_panel.visible = true


func _on_dialogue_pushed(text: String, is_special: bool, slot: int) -> void:
	if is_special and special_panel.visible:
		special_label.text = text
		special_fade_timer.start(DISPLAY_TIME_SECONDS)
	else:
		_update_or_create_speech_bubble(text, slot)


func _update_or_create_speech_bubble(text: String, slot: int) -> void:
	if slot < 0 or slot >= counter_markers.size():
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
	
	var marker = counter_markers[slot]
	bubble.global_position = marker.global_position + Vector2(0.0, BUBBLE_OFFSET_Y)
	
	_fade_out_bubble_delayed(bubble, slot)


func _set_bubble_text(bubble: Node, text: String) -> void:
	if bubble.has_method(SET_TEXT_METHOD_NAME):
		bubble.set_text(text)
	elif bubble.has_node(LABEL_COMPONENT_NAME):
		var label = bubble.get_node(LABEL_COMPONENT_NAME) as Label
		label.text = text
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _fade_out_bubble_delayed(bubble: Node, slot: int) -> void:
	await get_tree().create_timer(DISPLAY_TIME_SECONDS).timeout
	
	if is_instance_valid(bubble) and active_slot_bubbles.get(slot) == bubble:
		bubble.queue_free()
		active_slot_bubbles.erase(slot)


func _hide_special_buttons() -> void:
	accept_button.visible = false
	reject_button.visible = false


func _on_special_fade_timeout() -> void:
	special_panel.visible = false

	special_panel.visible = false
