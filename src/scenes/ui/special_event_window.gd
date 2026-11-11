class_name SpecialEventWindow
extends Panel

## One special request. "Joo" settles a payment at once; goods are waited for
## delivery_seconds, and the reward flies out of the window once they are there.

enum State { ASKING, DELIVERING, ANSWERED }

const DISPLAY_TIME_SECONDS = 3.5
## How often a delivering request looks at the stock.
const DELIVERY_CHECK_SECONDS : float = 0.25

const REWARD_STAGGER_SECONDS : float = 0.3
const REWARD_RISE_SECONDS : float = 1.6
const REWARD_DRIFT : Vector2 = Vector2(48.0, -14.0)
const REWARD_ROW_HEIGHT : float = 12.0
const REWARD_OUTLINE_SIZE : int = 4
const REWARD_OUTLINE_COLOR : Color = Color(0.05, 0.03, 0.02, 1)
const MONEY_COLOR : Color = Color(1.0, 0.84, 0.0, 1) # gold like the sale popups
const GOOD_COLOR : Color = Color.GREEN
const BAD_COLOR : Color = Color(1.0, 0.35, 0.3, 1)
const PERK_COLOR : Color = RunPerk.TIER_COLOR_RARE

const PORTRAIT_GAP : int = 6

@onready var text_label: Label = %SpecialLabel
@onready var joo_button: Button = %JooButton
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var time_label: Label = %TimeLabel
@onready var margin_container: MarginContainer = $MarginContainer

var event_data: SpecialEventData
var time_left: float = 10.0
var _state: State = State.ASKING
var _delivery_left: float = 0.0
var _check_clock: float = 0.0
var _fade_timer: SceneTreeTimer
## The portrait's current frame; null for a caller without one.
var _portrait_frame: AtlasTexture = null
## Seconds into typing the current text; negative when nothing is being typed.
var _typing_seconds: float = -1.0
var _babble_left: float = 0.0


func _ready() -> void:
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Wrapped for the whole text from the start, so the lines do not jump while typing.
	text_label.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING

	joo_button.visible = true
	joo_button.pressed.connect(_on_joo_button_pressed)


func _process(delta: float) -> void:
	# The player reads and answers in real seconds, whatever the game speed.
	var real_delta : float = GameSpeed.real_delta(delta)
	_advance_typing(real_delta)
	match _state:
		State.ASKING:
			time_left -= real_delta
			_show_time(time_left)
			if time_left <= 0.0:
				_timeout_event()
		State.DELIVERING:
			_delivery_left -= real_delta
			_show_time(_delivery_left)
			_check_clock += delta
			if _check_clock >= DELIVERY_CHECK_SECONDS:
				_check_clock = 0.0
				_check_delivery()
			if _state == State.DELIVERING and _delivery_left <= 0.0:
				_expire()


## `seconds_left` (a loaded run) is what was left of the time to answer.
func initialize_window(p_data: SpecialEventData, seconds_left: float = -1.0) -> void:
	event_data = p_data
	time_left = seconds_left if seconds_left >= 0.0 else event_data.timeout_seconds
	progress_bar.max_value = event_data.timeout_seconds
	_show_time(time_left)
	text_label.text = tr(event_data.event_caller_name) + ": " + event_data.intro_text()
	_show_portrait()
	_resize_to_fit_content()
	# A loaded window is already said.
	if seconds_left < 0.0:
		_type_text()


## Moves the text into a row beside the caller's portrait; a caller without one keeps the
## full width.
func _show_portrait() -> void:
	if event_data.portrait == null:
		return
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", PORTRAIT_GAP)
	var column : Node = text_label.get_parent()
	column.add_child(row)
	column.move_child(row, text_label.get_index())
	_portrait_frame = AtlasTexture.new()
	_portrait_frame.atlas = event_data.portrait
	_portrait_frame.region = PortraitTalk.frame_region(false)
	var portrait := TextureRect.new()
	portrait.texture = _portrait_frame
	portrait.stretch_mode = TextureRect.STRETCH_KEEP
	portrait.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(portrait)
	text_label.reparent(row)
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL


func _type_text() -> void:
	text_label.visible_characters = 0
	_typing_seconds = 0.0
	_babble_left = 0.0


func _advance_typing(real_delta: float) -> void:
	if _typing_seconds < 0.0:
		return
	_typing_seconds += real_delta
	var total: int = text_label.get_total_character_count()
	var shown: int = PortraitTalk.characters_shown(_typing_seconds, total)
	text_label.visible_characters = shown
	_set_mouth(PortraitTalk.is_mouth_open(shown, total))
	if shown >= total:
		_stop_typing()
	else:
		_babble(real_delta)


## Only a caller with a moving mouth babbles, so the stray cat stays quiet.
func _babble(real_delta: float) -> void:
	_babble_left -= real_delta
	if _portrait_frame != null and _babble_left <= 0.0:
		_babble_left = PortraitTalk.BABBLE_SECONDS
		GUISignals.special_event_spoke.emit(event_data.voice_pitch)


func _stop_typing() -> void:
	_typing_seconds = -1.0
	text_label.visible_characters = -1
	_set_mouth(false)


func _set_mouth(is_open: bool) -> void:
	if _portrait_frame != null:
		_portrait_frame.region = PortraitTalk.frame_region(is_open)


## Puts a saved window back: still asking, waiting for the goods, or showing the reply.
func resume(snap: SpecialEventSnapshot) -> void:
	initialize_window(snap.event_data, snap.time_left)
	if snap.delivering:
		_start_delivery(snap.delivery_left)
	elif not snap.answer_text.is_empty():
		_hide_button()
		_state = State.ANSWERED
		_stop_typing()
		text_label.text = snap.answer_text
		_start_fade_out(snap.fade_left)


func snapshot() -> SpecialEventSnapshot:
	var snap := SpecialEventSnapshot.new()
	snap.event_data = event_data
	snap.time_left = maxf(time_left, 0.0)
	match _state:
		State.DELIVERING:
			snap.delivering = true
			snap.delivery_left = maxf(_delivery_left, 0.0)
		State.ANSWERED:
			snap.answer_text = text_label.text
			snap.fade_left = _fade_timer.time_left if _fade_timer != null else 0.0
	return snap


## A Panel does not pass its children's minimum size to its VBoxContainer, so the window
## would ignore how tall the wrapped dialogue is.
func _resize_to_fit_content() -> void:
	await get_tree().process_frame
	custom_minimum_size = margin_container.get_combined_minimum_size()


func _on_joo_button_pressed() -> void:
	var brewery: Brewery = BrewEngine.current_brewery
	if brewery != null and event_data.waits_for_delivery() and not event_data.can_fulfill(brewery):
		_start_delivery(event_data.delivery_seconds)
		return
	_complete()


func _start_delivery(seconds: float) -> void:
	_state = State.DELIVERING
	joo_button.visible = false
	_delivery_left = seconds
	progress_bar.max_value = event_data.delivery_seconds
	_show_time(seconds)
	_check_delivery()


## Completes the request once the stock is there, else shows what is still missing.
func _check_delivery() -> void:
	var brewery: Brewery = BrewEngine.current_brewery
	if brewery == null:
		return
	if event_data.can_fulfill(brewery):
		_complete()
		return
	var text: String = tr(event_data.event_caller_name) + ": " + event_data.delivery_text(brewery.inventory)
	if text != text_label.text:
		_stop_typing()
		text_label.text = text
		_resize_to_fit_content()


## Settles the request; what it changed flies out of the window.
func _complete() -> void:
	var brewery: Brewery = BrewEngine.current_brewery
	var before: Array = _resources_of(brewery)
	var response: String = SpecialEventManager.process_accept(event_data)
	_answer(response)
	_pop_rewards(before, _resources_of(brewery), brewery)


## Only reached by letting the timer run out: there is no decline button.
func _timeout_event() -> void:
	_answer(SpecialEventManager.process_reject(event_data))


func _expire() -> void:
	var brewery: Brewery = BrewEngine.current_brewery
	var before: Array = _resources_of(brewery)
	_answer(SpecialEventManager.process_expired(event_data))
	_pop_rewards(before, _resources_of(brewery), brewery)


func _answer(response: String) -> void:
	_hide_button()
	_state = State.ANSWERED
	text_label.text = _caller_line(response)
	_resize_to_fit_content()
	_type_text()
	_start_fade_out()


func _show_time(seconds_left: float) -> void:
	progress_bar.value = seconds_left
	time_label.text = SpecialEventText.seconds(seconds_left)


func _caller_line(dialogue: String) -> String:
	return tr(event_data.event_caller_name) + ": " + tr(dialogue)


func _hide_button() -> void:
	joo_button.visible = false
	progress_bar.visible = false


func _start_fade_out(seconds: float = DISPLAY_TIME_SECONDS) -> void:
	_fade_timer = GameSpeed.reading_timer(get_tree(), seconds)
	await _fade_timer.timeout
	queue_free()


## Money, reputation, risk and perk count, compared before and after the request settles.
func _resources_of(brewery: Brewery) -> Array:
	if brewery == null:
		return [0.0, 0, 0, 0]
	return [brewery.money, brewery.reputation, brewery.risk, brewery.active_perks.size()]


func _pop_rewards(before: Array, after: Array, brewery: Brewery) -> void:
	var lines: Array = []
	var money: float = snappedf(after[0] - before[0], 0.1)
	if not is_zero_approx(money):
		lines.append([SpecialEventText.money(money), MONEY_COLOR])
	var reputation: int = after[1] - before[1]
	if reputation != 0:
		lines.append([SpecialEventText.reputation(reputation), GOOD_COLOR if reputation > 0 else BAD_COLOR])
	var risk: int = after[2] - before[2]
	if risk != 0:
		lines.append([SpecialEventText.risk(risk), BAD_COLOR if risk > 0 else GOOD_COLOR])
	if brewery != null:
		for perk : RunPerk in brewery.active_perks.slice(before[3]):
			lines.append([tr(perk.perk_name), PERK_COLOR])
	for i : int in lines.size():
		_pop_reward(lines[i][0], lines[i][1], i)


## Top level, so the window's layout leaves it alone while it flies out of the right edge.
func _pop_reward(text: String, color: Color, row: int) -> void:
	var label := Label.new()
	label.text = text
	label.top_level = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override(&"font_color", color)
	label.add_theme_constant_override(&"outline_size", REWARD_OUTLINE_SIZE)
	label.add_theme_color_override(&"font_outline_color", REWARD_OUTLINE_COLOR)
	label.modulate.a = 0.0
	add_child(label)
	var start: Vector2 = global_position + Vector2(size.x - 24.0, 12.0 + row * REWARD_ROW_HEIGHT)
	label.global_position = start

	var tween := label.create_tween()
	tween.tween_interval(row * REWARD_STAGGER_SECONDS)
	tween.tween_property(label, "modulate:a", 1.0, 0.1)
	PixelStepTween.move_property(tween.parallel(), label, &"global_position", start, start + REWARD_DRIFT, REWARD_RISE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, REWARD_RISE_SECONDS * 0.4).set_delay(REWARD_RISE_SECONDS * 0.6)
	tween.tween_callback(label.queue_free)
