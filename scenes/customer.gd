class_name Customer
extends Node2D


## Fired once walk_complex_route's tween finishes, regardless of
## skip_interaction — lets an external controller (a group visit's shared
## chant/order) know precisely when this customer has actually arrived,
## instead of guessing the walk's duration from distance and speed.
signal walk_route_finished

const FADE_TIME_SECONDS : float = 1.0
const BASE_DISPLAY_TIME_SECONDS : float = 4.0
const PER_CHARACTER_DISPLAY_TIME_SECONDS : float = 0.04
const MAX_DISPLAY_TIME_SECONDS : float = 9.0

const PREVIEW_DELAY_SECONDS : float = 2.0
const BATCH_PREVIEW_FORMAT : String = "%s: Tuo %s kiinnostaisi..."
const NOTHING_AVAILABLE_TEXT_FORMAT : String = "%s: Eipä taida olla mitään sopivaa..."

const ANIM_IDLE : StringName = &"idle"
const ANIM_IDLE_UP : StringName = &"idle_up"
const ANIM_WALK_TOWARDS : StringName = &"walk_towards"
const ANIM_WALK_RIGHT : StringName = &"walk_right"

## How long a just-served glass sits on the counter before the customer
## picks it up and leaves — matched to Bartender's serve_beer animation
## length (src/resources/sprite_frames/baarimikko_anim.tres, 7 frames /
## speed 4.0 = 2.0s) so the glass visibly appears only once the bartender
## has actually finished pouring it, not the instant the sale resolves.
## A tuned constant rather than a live cross-node query: Bartender is a
## single fixed-position fixture with no per-sale/per-customer identity to
## hand back (BrewerySignals.bottles_sold carries only an amount), so
## there's nothing here to react to directly — see show_counter_glass()'s
## call sites.
const SERVE_BEER_WAIT_SECONDS : float = 2.0
## How long the counter-glass slide itself takes, once it starts — see
## show_counter_glass()'s call sites, which wait SERVE_BEER_WAIT_SECONDS
## first so the slide only begins once the bartender's pour animation has
## actually finished, not while it's still playing.
const GLASS_SLIDE_DURATION_SECONDS : float = 0.6

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var bottle_hand_marker: Marker2D = $BottleHandMarker
@onready var beer_glass_sprite: Sprite2D = $BottleHandMarker/BeerGlassSprite
@onready var counter_glass_sprite: Sprite2D = $CounterGlassSprite

var customer_data: CustomerData:
	set(value):
		customer_data = value
		_apply_visuals()
var assigned_slot: int = -1

## Set when process_auto_sale() actually sold this customer a beer — gates
## show_counter_glass()/show_beer_glass() so the glass only ever appears
## once a sale actually went through, and show_beer_glass() specifically
## only while walking away (see CustomerHandOffsets: the only pose
## it's positioned for), never during the counter-facing idle_up wait.
var made_purchase: bool = false

## Speech-bubble identity for DialogView, separate from assigned_slot.
## A group visit puts several customers on the same assigned_slot (they
## share one counter position and one CustomerManager occupancy slot), but
## DialogView keys its per-slot bubble/hide-timer bookkeeping by this value
## — reusing assigned_slot there would let two group members race each
## other's hide timers on the same bubble and crash on a freed reference.
## CustomerSpawner sets this explicitly for every customer (solo customers
## get the same value as assigned_slot, preserving their existing bubble
## behavior unchanged; group members each get a distinct value).
var dialogue_slot: int = -1

var generated_name: String = "Asiakas"


func _ready() -> void:
	animated_sprite.frame_changed.connect(_on_animated_sprite_frame_changed)


func _on_animated_sprite_frame_changed() -> void:
	var title : String = customer_data.title if customer_data != null else ""
	bottle_hand_marker.position = CustomerHandOffsets.position_for(title, animated_sprite.frame)


func _apply_visuals() -> void:
	animated_sprite.sprite_frames = customer_data.sprite_frames
	animated_sprite.material = CustomerRecolor.build_material(customer_data)
	_play_animation(ANIM_IDLE)


func _play_animation(anim_name: StringName, flip_horizontally: bool = false) -> void:
	if animated_sprite.sprite_frames == null or not animated_sprite.sprite_frames.has_animation(anim_name):
		return
	animated_sprite.flip_h = flip_horizontally
	animated_sprite.play(anim_name)


static func _get_display_time_for_text(text: String) -> float:
	return clampf(
		BASE_DISPLAY_TIME_SECONDS + text.length() * PER_CHARACTER_DISPLAY_TIME_SECONDS,
		BASE_DISPLAY_TIME_SECONDS,
		MAX_DISPLAY_TIME_SECONDS
	)


func get_customer_name() -> String:
	return generated_name


## skip_interaction is true for a group visit's members: they still walk and
## idle at the counter like any customer, but the group's shared controller
## drives the dialogue/order/departure for all of them at once instead of
## each one independently triggering its own (see CustomerSpawner).
func walk_complex_route(stairs_pos: Vector2, center_pos: Vector2, target_pos: Vector2, skip_interaction: bool = false) -> void:
	var tween = create_tween()
	var start_pos = global_position
	var stair_steps = 15

	tween.tween_callback(_play_animation.bind(ANIM_WALK_TOWARDS, true))
	for i in range(1, stair_steps + 1):
		var step_pos = start_pos.lerp(stairs_pos, float(i) / stair_steps)
		tween.tween_property(self, "global_position", step_pos, customer_data.stair_step_duration).set_trans(Tween.TRANS_LINEAR)
		tween.tween_interval(0.05)

	var walking_left_to_center = center_pos.x < stairs_pos.x
	tween.tween_callback(_play_animation.bind(ANIM_WALK_RIGHT, walking_left_to_center))
	var dist_to_center = stairs_pos.distance_to(center_pos)
	var duration_to_center = dist_to_center / customer_data.floor_walk_speed
	tween.tween_property(self, "global_position", center_pos, duration_to_center).set_trans(Tween.TRANS_LINEAR)

	tween.tween_callback(_play_animation.bind(ANIM_IDLE, false))
	tween.tween_interval(0.8)

	var walking_left_to_target = target_pos.x < center_pos.x
	tween.tween_callback(_play_animation.bind(ANIM_WALK_RIGHT, walking_left_to_target))
	var dist_to_target = center_pos.distance_to(target_pos)
	var duration_to_target = dist_to_target / customer_data.floor_walk_speed
	tween.tween_property(self, "global_position", target_pos, duration_to_target).set_trans(Tween.TRANS_LINEAR)

	if skip_interaction:
		tween.tween_callback(_play_animation.bind(ANIM_IDLE_UP, false))
	else:
		tween.tween_callback(_on_reached_counter)
	tween.tween_callback(walk_route_finished.emit)


func _on_reached_counter() -> void:
	_play_animation(ANIM_IDLE_UP)
	var intro_text = generated_name + ": " + customer_data.dialogue_intro
	var display_time = _get_display_time_for_text(intro_text)
	BrewerySignals.dialogue_pushed.emit(intro_text, false, dialogue_slot, global_position, display_time, FADE_TIME_SECONDS)
	var preview_timer = get_tree().create_timer(display_time)
	preview_timer.timeout.connect(_on_preview_timeout)


## Makes the customer's already-automatic batch choice visible before it
## resolves, instead of process_auto_sale() deciding and reporting the
## result in the same instant — the pick itself is still entirely the
## customer's (find_best_batch_for mirrors what process_auto_sale will
## actually choose), this just surfaces it as a beat the player can see.
func _on_preview_timeout() -> void:
	var previewed_batch : BrewBatch = CustomerManager.find_best_batch_for(customer_data)
	var preview_text : String

	if previewed_batch != null:
		preview_text = BATCH_PREVIEW_FORMAT % [generated_name, previewed_batch.get_style_name()]
	else:
		preview_text = NOTHING_AVAILABLE_TEXT_FORMAT % generated_name

	var preview_display_time = _get_display_time_for_text(preview_text)
	BrewerySignals.dialogue_pushed.emit(preview_text, false, dialogue_slot, global_position, preview_display_time, FADE_TIME_SECONDS)

	var sale_timer = get_tree().create_timer(preview_display_time)
	sale_timer.timeout.connect(_on_sale_timeout)


func _on_sale_timeout() -> void:
	# Captured around the call, same pattern dev_console.gd's "sell"
	# command already uses for beer_sale_breakdown — process_auto_sale()
	# is a single synchronous call, so whatever sale_xp_gained fires
	# during it is unambiguously this sale's, not some other customer's.
	# A Dictionary, not a plain local: a lambda captures locals by value,
	# so reassigning a captured int inside it can't ever reach back out
	# to this scope — mutating a key on a captured Dictionary (a
	# reference type) can.
	var xp_capture : Dictionary = {"amount": 0}
	var capture_xp := func(amount : int) -> void: xp_capture.amount = amount
	var reputation_capture : Dictionary = {"amount": 0}
	var capture_reputation := func(amount : int) -> void: reputation_capture.amount = amount
	var tip_capture : Dictionary = {"amount": 0.0}
	var capture_tip := func(amount : float) -> void: tip_capture.amount = amount

	BrewerySignals.sale_xp_gained.connect(capture_xp)
	BrewerySignals.sale_reputation_gained.connect(capture_reputation)
	BrewerySignals.sale_tip_gained.connect(capture_tip)
	var response_text = CustomerManager.process_auto_sale(customer_data)
	BrewerySignals.sale_xp_gained.disconnect(capture_xp)
	BrewerySignals.sale_reputation_gained.disconnect(capture_reputation)
	BrewerySignals.sale_tip_gained.disconnect(capture_tip)

	if xp_capture.amount > 0:
		made_purchase = true
		var glass_timer = get_tree().create_timer(SERVE_BEER_WAIT_SECONDS)
		glass_timer.timeout.connect(show_counter_glass)
		BrewerySignals.xp_popup_requested.emit(xp_capture.amount, global_position)
	if reputation_capture.amount != 0:
		BrewerySignals.reputation_popup_requested.emit(reputation_capture.amount, global_position)
	if tip_capture.amount > 0:
		BrewerySignals.tip_popup_requested.emit(tip_capture.amount, global_position)

	var final_text = generated_name + ": " + response_text
	var display_time = _get_display_time_for_text(final_text)
	BrewerySignals.dialogue_pushed.emit(final_text, false, dialogue_slot, global_position, display_time, FADE_TIME_SECONDS)

	var leave_timer = get_tree().create_timer(display_time + FADE_TIME_SECONDS)
	leave_timer.timeout.connect(leave_counter)


func show_beer_glass() -> void:
	_on_animated_sprite_frame_changed()
	beer_glass_sprite.show()


## Called once SERVE_BEER_WAIT_SECONDS after the sale resolves (see this
## function's call sites) — i.e. only once the bartender's pour animation
## has actually finished, not while it's still playing. Slides the glass
## from wherever the bartender is standing to its resting spot on the
## counter over GLASS_SLIDE_DURATION_SECONDS. Falls back to popping in at
## rest position directly if the Bartender can't be found (shouldn't
## happen — main.tscn always has exactly one — but cheap insurance). Hidden
## again the moment the customer picks it up to leave (leave_counter()), at
## which point show_beer_glass() puts the same glass in their hand instead.
## slide_duration_seconds lets a group order's rapid one-by-one serving
## burst (GroupVisitDirector._run_shared_group_order()) slide each glass in
## quicker than a solo customer's — defaults to the normal solo pacing.
## rest_position_override (global space) lets that same burst rest this
## glass in the bartender's on-counter stack (Bartender.get_stack_position())
## instead of this customer's own resting spot — a group's now-far-back
## members would otherwise each pull their glass all the way out to their
## seat, which read as beers flying across the room rather than a round
## being set down on the bar. Vector2.INF means "no override, use my own".
##
## Runs with top_level = true (global-space transform, ignoring this
## Customer's own) for as long as the glass sits on the counter — a group's
## standby members walk again before picking their glass up (see
## leave_counter()'s pickup walk), and without this the glass, still an
## ordinary local-space child, would drag along with them mid-walk instead
## of staying put on the counter until they actually arrive. Reset back to
## normal parent-relative positioning in hide_counter_glass() once the
## glass leaves the counter.
func show_counter_glass(slide_duration_seconds: float = GLASS_SLIDE_DURATION_SECONDS, rest_position_override: Vector2 = Vector2.INF) -> void:
	var rest_position : Vector2 = rest_position_override if rest_position_override != Vector2.INF else to_global(counter_glass_sprite.position)
	var bartender := get_tree().get_first_node_in_group(Bartender.BARTENDER_GROUP) as Bartender

	counter_glass_sprite.top_level = true

	if bartender == null:
		counter_glass_sprite.position = rest_position
		counter_glass_sprite.show()
		return

	counter_glass_sprite.position = bartender.serve_marker.global_position
	counter_glass_sprite.show()

	var tween := create_tween()
	tween.tween_property(counter_glass_sprite, "position", rest_position, slide_duration_seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func hide_counter_glass() -> void:
	counter_glass_sprite.hide()
	counter_glass_sprite.top_level = false


## pickup_position_override (global) lets a group order's standby members
## (see GroupVisitDirector._run_shared_group_order()) walk up to the counter
## and grab their round from the on-bar stack (Bartender.get_stack_position())
## before turning to leave, instead of the beer just appearing in their hand
## from wherever they'd been standing further back — a solo customer, and
## the group's own order-place representative, are already standing right
## at the counter, so Vector2.INF ("no pickup walk needed") is their default.
func leave_counter(pickup_position_override: Vector2 = Vector2.INF) -> void:
	if pickup_position_override != Vector2.INF:
		await _walk_to_pickup_spot(pickup_position_override)

	var exit_pos = global_position + Vector2(0.0, 150.0)
	var duration = 150.0 / customer_data.floor_walk_speed

	_play_animation(ANIM_WALK_TOWARDS, true)
	if made_purchase:
		hide_counter_glass()
		show_beer_glass()
	var tween = create_tween()
	tween.tween_property(self, "global_position", exit_pos, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)

	CustomerManager.free_slot_index(assigned_slot)


## Same walk-to-a-lateral-target shape walk_complex_route() already uses for
## its stairs-to-counter leg (ANIM_WALK_RIGHT, flip toward the target, then
## ANIM_IDLE_UP once arrived) — reused here for the short standby-to-counter
## hop instead of that bigger multi-leg route, since this is already
## standing on the floor with nothing to walk around.
func _walk_to_pickup_spot(target: Vector2) -> void:
	var distance = global_position.distance_to(target)
	if distance < 1.0:
		return

	var walking_left = target.x < global_position.x
	_play_animation(ANIM_WALK_RIGHT, walking_left)
	var duration = distance / customer_data.floor_walk_speed

	var tween = create_tween()
	tween.tween_property(self, "global_position", target, duration).set_trans(Tween.TRANS_LINEAR)
	await tween.finished

	_play_animation(ANIM_IDLE_UP)
