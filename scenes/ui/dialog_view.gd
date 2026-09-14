class_name DialogView
extends Control


const WARNING_CUSTOMER_MANAGER_NOT_FOUND : String = "DialogView: CustomerManager Autoload not found!"

const SPEECH_BUBBLE_SCENE : PackedScene = preload("res://scenes/ui/speech_bubble.tscn")
const SPECIAL_EVENT_WINDOW_SCENE : PackedScene = preload("res://scenes/ui/special_event_window.tscn")

const BUBBLE_OFFSET_Y : float = -180.0
const BUBBLE_STAIR_STEP : float = 34.0
const BUBBLE_MIN_VISIBLE_Y : float = 38.0
const BUBBLE_X_PROXIMITY_PX : float = 60.0

## Well below BUBBLE_OFFSET_Y (-180) so the "+X XP" popup reads as coming
## from the customer themselves, distinct from their speech bubble
## further up — see _on_xp_popup_requested().
const XP_POPUP_OFFSET_Y : float = -50.0
const XP_POPUP_FLOAT_DISTANCE : float = 35.0
const XP_POPUP_DURATION_SECONDS : float = 1.8
## Same gold accent BrewPreparationPanel uses for the brewing-side XP
## popup — one consistent color for "that was an XP gain" everywhere.
const XP_POPUP_COLOR : Color = Color(0.949, 0.788, 0.42, 1)
const XP_POPUP_FORMAT : String = "+%d XP"

## Sits between the XP popup (-50) and the customer sprite itself, so it
## reads as appearing "under" the XP popup rather than overlapping it.
const REPUTATION_POPUP_OFFSET_Y : float = -25.0
const REPUTATION_POPUP_FORMAT : String = "%+d Mainetta"

## Offset sideways instead of stacked, so a tip (money, not growth) reads
## as its own distinct beat next to the customer rather than part of the
## XP/reputation stack.
const TIP_POPUP_OFFSET : Vector2 = Vector2(40.0, -50.0)
const TIP_POPUP_COLOR : Color = Color.GREEN
const TIP_POPUP_FORMAT : String = "Tippi +%.1f €"

@onready var bubble_spawn_point: Control = $BubbleSpawnPoint
@onready var special_events_container: VBoxContainer = $SpecialEventsContainer

## Avain: int (dialogue slot) -> Arvo: {bubble: Node, x: float, height_step: int}.
## height_step is picked fresh each placement from which OTHER currently
## active bubbles are actually close by on the x axis, rather than a fixed
## pattern derived from the slot number — so a crowd only staggers bubble
## heights where two speakers are really about to overlap, and reclaims low
## heights the moment a nearby speaker's bubble goes away.
var active_bubbles: Dictionary = {}
var slot_display_tokens: Dictionary = {} # Avain: int (slot) -> Arvo: int (kasvava tunniste)


func _ready() -> void:
	BrewerySignals.dialogue_pushed.connect(_on_dialogue_pushed)
	SpecialEventManager.special_event_triggered.connect(_on_special_event_triggered)
	BrewerySignals.xp_popup_requested.connect(_on_xp_popup_requested)
	BrewerySignals.reputation_popup_requested.connect(_on_reputation_popup_requested)
	BrewerySignals.tip_popup_requested.connect(_on_tip_popup_requested)
	BrewerySignals.customer_evicted.connect(_on_customer_evicted)


## A thrown-out customer's bubble shouldn't sit there finishing its normal
## display/fade timing — close it immediately instead. Erasing the token
## (rather than just the bubble) also makes any already-in-flight
## _hide_bubble_after_delay() for this slot a safe no-op via
## _bubble_still_current()'s mismatch check, instead of it double-freeing
## the bubble this clears.
func _on_customer_evicted(slot: int) -> void:
	if not active_bubbles.has(slot):
		return

	var entry : Dictionary = active_bubbles[slot]
	var fade_tween : Tween = entry.get("fade_tween")
	if fade_tween != null and is_instance_valid(fade_tween):
		fade_tween.kill()
	if is_instance_valid(entry.get("bubble")):
		entry.bubble.queue_free()

	active_bubbles.erase(slot)
	slot_display_tokens.erase(slot)


## Emitted by Customer/CustomerSpawner once they've paired a captured
## sale_xp_gained amount with their own known position — see those
## files. Deliberately not routed through the speech-bubble machinery
## above (no slot tracking, no stacking): this is a brief, independent
## flourish, not a piece of dialogue.
func _on_xp_popup_requested(amount : int, character_global_pos : Vector2) -> void:
	var popup := Label.new()
	popup.text = XP_POPUP_FORMAT % amount
	popup.modulate = XP_POPUP_COLOR

	bubble_spawn_point.add_child(popup)
	popup.global_position = character_global_pos + Vector2(0, XP_POPUP_OFFSET_Y)

	var tween := create_tween().set_parallel(true)
	var target_pos := popup.global_position + Vector2(0, -XP_POPUP_FLOAT_DISTANCE)
	var target_color := popup.modulate
	target_color.a = 0.0

	tween.tween_property(popup, "global_position", target_pos, XP_POPUP_DURATION_SECONDS)
	tween.tween_property(popup, "modulate", target_color, XP_POPUP_DURATION_SECONDS)

	tween.chain().tween_callback(popup.queue_free)


## Same flourish as _on_xp_popup_requested(), positioned just below it so
## a sale's reputation change reads as paired with its XP gain rather than
## competing with the top panel's own reputation popup.
func _on_reputation_popup_requested(amount : int, character_global_pos : Vector2) -> void:
	var popup := Label.new()
	popup.text = REPUTATION_POPUP_FORMAT % amount
	popup.modulate = Color.GREEN if amount > 0 else Color.RED

	bubble_spawn_point.add_child(popup)
	popup.global_position = character_global_pos + Vector2(0, REPUTATION_POPUP_OFFSET_Y)

	var tween := create_tween().set_parallel(true)
	var target_pos := popup.global_position + Vector2(0, -XP_POPUP_FLOAT_DISTANCE)
	var target_color := popup.modulate
	target_color.a = 0.0

	tween.tween_property(popup, "global_position", target_pos, XP_POPUP_DURATION_SECONDS)
	tween.tween_property(popup, "modulate", target_color, XP_POPUP_DURATION_SECONDS)

	tween.chain().tween_callback(popup.queue_free)


## Same flourish as _on_xp_popup_requested(), offset sideways instead of
## stacked — a tip is money, not run growth, so it reads as its own beat
## next to the customer rather than part of the XP/reputation stack.
func _on_tip_popup_requested(amount : float, character_global_pos : Vector2) -> void:
	var popup := Label.new()
	popup.text = TIP_POPUP_FORMAT % amount
	popup.modulate = TIP_POPUP_COLOR

	bubble_spawn_point.add_child(popup)
	popup.global_position = character_global_pos + TIP_POPUP_OFFSET

	var tween := create_tween().set_parallel(true)
	var target_pos := popup.global_position + Vector2(0, -XP_POPUP_FLOAT_DISTANCE)
	var target_color := popup.modulate
	target_color.a = 0.0

	tween.tween_property(popup, "global_position", target_pos, XP_POPUP_DURATION_SECONDS)
	tween.tween_property(popup, "modulate", target_color, XP_POPUP_DURATION_SECONDS)

	tween.chain().tween_callback(popup.queue_free)


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

	if active_bubbles.has(slot) and is_instance_valid(active_bubbles[slot].bubble):
		var entry : Dictionary = active_bubbles[slot]
		var fade_tween : Tween = entry.get("fade_tween")
		if fade_tween != null and is_instance_valid(fade_tween):
			fade_tween.kill()
			entry.fade_tween = null
		entry.bubble.modulate.a = 1.0
		_set_bubble_text(entry.bubble, text)
		_place_bubble(entry, slot, character_global_pos)
		_hide_bubble_after_delay(entry.bubble, slot, token, display_time, fade_time)
		return

	var bubble = SPEECH_BUBBLE_SCENE.instantiate()
	bubble_spawn_point.add_child(bubble)
	var new_entry : Dictionary = {"bubble": bubble, "x": character_global_pos.x, "height_step": 0, "fade_tween": null}
	active_bubbles[slot] = new_entry

	_set_bubble_text(bubble, text)
	_place_bubble(new_entry, slot, character_global_pos)

	_hide_bubble_after_delay(bubble, slot, token, display_time, fade_time)


## Picks the lowest height step not already taken by another currently
## active bubble that's close enough on the x axis to actually collide with
## this one — so two speakers standing far apart always share the same
## (lowest) height, and stacking only kicks in between speakers who are
## genuinely near each other, however many total speakers are on screen.
func _place_bubble(entry: Dictionary, slot: int, character_global_pos: Vector2) -> void:
	entry.x = character_global_pos.x

	var base_y : float = character_global_pos.y + BUBBLE_OFFSET_Y
	var max_steps : int = maxi(0, floori((base_y - BUBBLE_MIN_VISIBLE_Y) / BUBBLE_STAIR_STEP))

	var used_steps : Dictionary = {}
	for other_slot in active_bubbles.keys():
		if other_slot == slot:
			continue
		var other : Dictionary = active_bubbles[other_slot]
		if not is_instance_valid(other.bubble):
			continue
		if absf(other.x - entry.x) < BUBBLE_X_PROXIMITY_PX:
			used_steps[other.height_step] = true

	var step := 0
	while used_steps.has(step) and step < max_steps:
		step += 1
	entry.height_step = step

	var target_y : float = base_y - step * BUBBLE_STAIR_STEP
	var bubble_size : Vector2 = entry.bubble.get_size()
	entry.bubble.global_position = Vector2(character_global_pos.x - bubble_size.x * 0.5, target_y)
	entry.bubble.z_index = slot


func _set_bubble_text(bubble: Node, text: String) -> void:
	if bubble.has_method("set_text"):
		bubble.set_text(text)
	elif bubble.has_node("Label"):
		var label = bubble.get_node("Label") as Label
		label.text = text
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


## is_instance_valid(bubble) is checked BEFORE every _bubble_still_current()
## call, not just inside it — a bubble freed elsewhere while this coroutine
## is parked on an await (e.g. DialogView._on_customer_evicted(), which can
## queue_free() the same bubble out from under an in-flight hide-after-
## delay) leaves `bubble` a stale reference. Passing a truly-freed Object
## into ANY typed parameter, including _bubble_still_current(bubble: Node,
## ...)'s own, throws a hard runtime error ("previously freed... not a
## subclass of the expected argument class") at the call site itself,
## before that function's own is_instance_valid() check ever gets to run —
## so the guard has to happen here, one level up, via short-circuiting
## `or` so the unsafe call never executes at all once bubble is invalid.
func _hide_bubble_after_delay(bubble: Node, slot: int, token: int, display_time: float, fade_time: float) -> void:
	await get_tree().create_timer(display_time).timeout

	if not is_instance_valid(bubble) or not _bubble_still_current(bubble, slot, token):
		return

	if fade_time > 0.0 and bubble is CanvasItem:
		var tween := bubble.create_tween()
		tween.tween_property(bubble, "modulate:a", 0.0, fade_time)
		if active_bubbles.has(slot) and active_bubbles[slot].get("bubble") == bubble:
			active_bubbles[slot].fade_tween = tween
		await tween.finished

	if not is_instance_valid(bubble) or not _bubble_still_current(bubble, slot, token):
		return

	bubble.queue_free()
	active_bubbles.erase(slot)
	slot_display_tokens.erase(slot)


func _bubble_still_current(bubble: Node, slot: int, token: int) -> bool:
	if slot_display_tokens.get(slot, -1) != token:
		return false

	var entry : Dictionary = active_bubbles.get(slot, {})
	return is_instance_valid(bubble) and entry.get("bubble") == bubble
