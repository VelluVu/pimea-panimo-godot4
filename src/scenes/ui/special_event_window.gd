class_name SpecialEventWindow
extends Panel


const DISPLAY_TIME_SECONDS = 3.5

@onready var text_label: Label = %SpecialLabel
@onready var joo_button: Button = %JooButton
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var margin_container: MarginContainer = $MarginContainer

var event_data: SpecialEventData
var time_left: float = 10.0
var is_active: bool = true
var _fade_timer: SceneTreeTimer


func _ready() -> void:
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	joo_button.visible = true
	joo_button.pressed.connect(_on_joo_button_pressed)


func _process(delta: float) -> void:
	if not is_active: return
	
	time_left -= delta
	progress_bar.value = time_left
	
	if time_left <= 0.0:
		_timeout_event()


## `seconds_left` (a loaded run) is what was left of the time to answer.
func initialize_window(p_data: SpecialEventData, seconds_left: float = -1.0) -> void:
	event_data = p_data
	time_left = seconds_left if seconds_left >= 0.0 else event_data.timeout_seconds
	progress_bar.max_value = event_data.timeout_seconds
	progress_bar.value = time_left
	text_label.text = tr(event_data.event_caller_name) + ": " + tr(event_data.intro_dialogue)
	_resize_to_fit_content()


## Puts a saved window back: still waiting for an answer, or showing the reply.
func resume(snap: SpecialEventSnapshot) -> void:
	initialize_window(snap.event_data, snap.time_left)
	if not snap.answer_text.is_empty():
		_hide_button()
		text_label.text = snap.answer_text
		_start_fade_out(snap.fade_left)


func snapshot() -> SpecialEventSnapshot:
	var snap := SpecialEventSnapshot.new()
	snap.event_data = event_data
	snap.time_left = maxf(time_left, 0.0)
	if not is_active:
		snap.answer_text = text_label.text
		snap.fade_left = _fade_timer.time_left if _fade_timer != null else 0.0
	return snap


## Panel doesn't extend Container, so it never relays its children's
## computed minimum size to the VBoxContainer that positions it — without
## this, the window's on-screen size ignores how tall the wrapped dialogue
## actually is. Setting custom_minimum_size is what the parent respects.
func _resize_to_fit_content() -> void:
	await get_tree().process_frame
	custom_minimum_size = margin_container.get_combined_minimum_size()


func _on_joo_button_pressed() -> void:
	_hide_button()
	var response: String = SpecialEventManager.process_accept(event_data)
	text_label.text = tr(event_data.event_caller_name) + ": " + tr(response)
	_start_fade_out()


## Only reached by inaction (the player let the timer run out without
## pressing "Joo") — there's no decline button anymore, since the brewery
## never turns down business on purpose; see process_reject's docstring.
func _timeout_event() -> void:
	_hide_button()
	var response: String = SpecialEventManager.process_reject(event_data)
	text_label.text = tr(event_data.event_caller_name) + ": " + tr(response)
	_start_fade_out()


func _hide_button() -> void:
	joo_button.visible = false
	is_active = false
	progress_bar.visible = false


func _start_fade_out(seconds: float = DISPLAY_TIME_SECONDS) -> void:
	_fade_timer = get_tree().create_timer(seconds)
	await _fade_timer.timeout
	queue_free()
