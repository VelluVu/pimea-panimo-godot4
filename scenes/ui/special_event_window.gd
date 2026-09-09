class_name SpecialEventWindow
extends Panel


const DISPLAY_TIME_SECONDS = 3.5

@onready var text_label: Label = $MarginContainer/MainVBox/SpecialLabel
@onready var accept_button: Button = $MarginContainer/MainVBox/ButtonRow/AcceptButton
@onready var reject_button: Button = $MarginContainer/MainVBox/ButtonRow/RejectButton
@onready var progress_bar: ProgressBar = $MarginContainer/MainVBox/ProgressBar
@onready var margin_container: MarginContainer = $MarginContainer

var event_data: SpecialEventData
var time_left: float = 10.0
var is_active: bool = true


func _ready() -> void:
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	accept_button.visible = true
	reject_button.visible = true

	accept_button.pressed.connect(_on_accept_pressed)
	reject_button.pressed.connect(_on_reject_pressed)


func _process(delta: float) -> void:
	if not is_active: return
	
	time_left -= delta
	progress_bar.value = time_left
	
	if time_left <= 0.0:
		_timeout_event()


func initialize_window(p_data: SpecialEventData) -> void:
	event_data = p_data
	time_left = event_data.timeout_seconds
	progress_bar.max_value = event_data.timeout_seconds
	progress_bar.value = event_data.timeout_seconds
	text_label.text = event_data.event_caller_name + ": " + event_data.intro_dialogue
	_resize_to_fit_content()


## Panel doesn't extend Container, so it never relays its children's
## computed minimum size to the VBoxContainer that positions it — without
## this, the window's on-screen size ignores how tall the wrapped dialogue
## actually is. Setting custom_minimum_size is what the parent respects.
func _resize_to_fit_content() -> void:
	await get_tree().process_frame
	custom_minimum_size = margin_container.get_combined_minimum_size()


func _on_accept_pressed() -> void:
	_hide_buttons()
	var response = SpecialEventManager.process_accept(event_data)
	text_label.text = event_data.event_caller_name + ": " + response
	_start_fade_out()


func _on_reject_pressed() -> void:
	_hide_buttons()
	var response = SpecialEventManager.process_reject(event_data)
	text_label.text = event_data.event_caller_name + ": " + response
	_start_fade_out()


func _timeout_event() -> void:
	_hide_buttons()
	var response = SpecialEventManager.process_reject(event_data)
	text_label.text = event_data.event_caller_name + ": " + response
	_start_fade_out()


func _hide_buttons() -> void:
	reject_button.visible = false
	accept_button.visible = false
	is_active = false
	progress_bar.visible = false


func _start_fade_out() -> void:
	var fade_timer = get_tree().create_timer(DISPLAY_TIME_SECONDS)
	await fade_timer.timeout
	queue_free()
