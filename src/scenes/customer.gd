class_name Customer
extends Node2D

const STAIR_STEPS : int = 15
const STAIR_STEP_PAUSE_SECONDS : float = 0.05
const CENTER_PAUSE_SECONDS : float = 0.8
const EXIT_WALK_DISTANCE : float = 150.0
const MIN_WALK_DISTANCE : float = 1.0

## The legs of the walk in, in order (see walk_complex_route()).
enum Leg { STAIRS, TO_CENTER, CENTER_PAUSE, TO_COUNTER }

const ANIM_IDLE : StringName = &"idle"
const ANIM_IDLE_UP : StringName = &"idle_up"
const ANIM_WALK_TOWARDS : StringName = &"walk_towards"
const ANIM_WALK_RIGHT : StringName = &"walk_right"
const WALK_ANIMATIONS : Array[StringName] = [ANIM_WALK_TOWARDS, ANIM_WALK_RIGHT]

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var bottle_hand_marker: Marker2D = $BottleHandMarker
@onready var beer_glass_sprite: Sprite2D = $BottleHandMarker/BeerGlassSprite
@onready var counter_glass_sprite: Sprite2D = $CounterGlassSprite

var customer_data: CustomerData:
	set(value):
		customer_data = value
		_apply_visuals()
var assigned_slot: int = -1

## Set when a sale went through. Gates the counter glass and the walk-away beer glass.
var made_purchase: bool = false

## Speech-bubble identity, apart from assigned_slot: group members share a slot but need
## their own bubbles, or their hide timers race.
var dialogue_slot: int = -1

var generated_name: String = "Asiakas"

## Where the visit is, so snapshot() can freeze it and resume() carry on.
var _phase: CustomerSnapshot.Phase = CustomerSnapshot.Phase.WALKING_IN
## Group members are driven by GroupVisitDirector, which saves them with their group.
var _skip_interaction: bool = false
var _route: Array[Vector2] = []  # spawn, stairs bottom, room centre, counter spot
var _leg: int = Leg.STAIRS
var _pause_seconds: float = CENTER_PAUSE_SECONDS
var _pause_started_msec: int = 0
var _phase_timer: SceneTreeTimer
var _bubble_text: String = ""
## The batches named in the preview, so the sale buys the same ones.
var _picked_batches: Array[BrewBatch] = []
var _exit_position: Vector2
## Where a group member walks for their glass before leaving; INF when not.
var _pickup_target: Vector2 = Vector2.INF

## A bar fight under way: glasses left (-1 when none), the next stomp and its spot, for the
## save.
var _rampage_glasses: int = -1
var _rampage_stomp: int = 0
var _rampage_home: Vector2

var _glasses: CustomerGlasses
var _sounds := CustomerSounds.new()

## A strong or big round sways them on the way out, see TipsyRules.
var _sway_steps: int = 0
var _sway_seconds: float = 0.0
var _sway_x: float = 0.0
var _sprite_home_x: float = 0.0


func _ready() -> void:
	animated_sprite.frame_changed.connect(_on_animated_sprite_frame_changed)
	_glasses = CustomerGlasses.new(self, beer_glass_sprite, counter_glass_sprite)
	_sprite_home_x = animated_sprite.position.x


func _process(delta: float) -> void:
	_sounds.tick(delta, self, animated_sprite, customer_data, WALK_ANIMATIONS)
	if _phase == CustomerSnapshot.Phase.LEAVING and _sway_steps > 0:
		_sway(delta)


## Body and hand step sideways together, a whole art pixel at a time.
func _sway(delta: float) -> void:
	_sway_seconds += delta
	var x : float = TipsyRules.sway_offset(_sway_seconds, _sway_steps) * _art_pixel()
	if is_equal_approx(x, _sway_x):
		return
	_sway_x = x
	animated_sprite.position.x = _sprite_home_x + x
	_on_animated_sprite_frame_changed()


func _on_animated_sprite_frame_changed() -> void:
	var title : String = customer_data.title if customer_data != null else ""
	bottle_hand_marker.position = CustomerHandOffsets.position_for(title, animated_sprite.frame) + Vector2(_sway_x, 0.0)


func _apply_visuals() -> void:
	animated_sprite.sprite_frames = customer_data.sprite_frames
	animated_sprite.material = CustomerRecolor.build_material(customer_data)
	_play_animation(ANIM_IDLE)
	_sounds.start_ambient_loop(self, customer_data)


func _play_animation(anim_name: StringName, flip_horizontally: bool = false) -> void:
	MirroredAnimation.play(animated_sprite, anim_name, flip_horizontally)
	animated_sprite.speed_scale = WalkCadence.for_sprite(animated_sprite, customer_data.floor_walk_speed, WALK_ANIMATIONS)


func get_customer_name() -> String:
	return generated_name


## skip_interaction is true for group members, whose group drives their dialogue, order and
## departure.
func walk_complex_route(stairs_pos: Vector2, center_pos: Vector2, target_pos: Vector2, skip_interaction: bool = false) -> void:
	_skip_interaction = skip_interaction
	_route = [global_position, stairs_pos, center_pos, target_pos]
	_walk_route_from(Leg.STAIRS, CENTER_PAUSE_SECONDS)


## Queues the walk from `first_leg` on, from where the customer stands: a fresh visit at the
## top, a loaded one mid-way.
func _walk_route_from(first_leg: int, pause_seconds: float) -> void:
	_phase = CustomerSnapshot.Phase.WALKING_IN
	var tween := create_tween()
	var from := global_position
	if first_leg <= Leg.STAIRS:
		tween.tween_callback(_set_leg.bind(Leg.STAIRS))
		_queue_stair_descent(tween, from, _route[1], CustomerRoute.stair_steps_left(_route[0], _route[1], from, STAIR_STEPS))
		from = _route[1]
	if first_leg <= Leg.TO_CENTER:
		tween.tween_callback(_set_leg.bind(Leg.TO_CENTER))
		_queue_floor_walk(tween, from, _route[2])
		from = _route[2]
	if first_leg <= Leg.CENTER_PAUSE:
		_pause_seconds = pause_seconds
		tween.tween_callback(_set_leg.bind(Leg.CENTER_PAUSE))
		tween.tween_callback(_play_animation.bind(ANIM_IDLE, false))
		tween.tween_interval(pause_seconds)
	tween.tween_callback(_set_leg.bind(Leg.TO_COUNTER))
	_queue_floor_walk(tween, from, _route[3])

	if _skip_interaction:
		tween.tween_callback(_wait_with_group)
	else:
		tween.tween_callback(_on_reached_counter)


func _wait_with_group() -> void:
	_phase = CustomerSnapshot.Phase.WAITING
	_play_animation(ANIM_IDLE_UP)


func is_group_member() -> bool:
	return _skip_interaction


func is_walking_in() -> bool:
	return _phase == CustomerSnapshot.Phase.WALKING_IN


func is_leaving() -> bool:
	return _phase == CustomerSnapshot.Phase.LEAVING


func _set_leg(leg: int) -> void:
	_leg = leg
	if leg == Leg.CENTER_PAUSE:
		_pause_started_msec = Time.get_ticks_msec()


func _queue_stair_descent(tween: Tween, from_pos: Vector2, stairs_pos: Vector2, steps: int) -> void:
	if steps <= 0:
		return
	tween.tween_callback(_play_animation.bind(ANIM_WALK_TOWARDS, true))
	var step_from := from_pos
	for i in range(1, steps + 1):
		var step_pos := from_pos.lerp(stairs_pos, float(i) / steps)
		PixelStepTween.move(tween, self, step_from, step_pos, customer_data.stair_step_duration, _art_pixel())
		tween.tween_interval(STAIR_STEP_PAUSE_SECONDS)
		step_from = step_pos


func _queue_floor_walk(tween: Tween, from_pos: Vector2, to_pos: Vector2) -> void:
	tween.tween_callback(_play_animation.bind(ANIM_WALK_RIGHT, to_pos.x < from_pos.x))
	var duration := from_pos.distance_to(to_pos) / customer_data.floor_walk_speed
	PixelStepTween.move(tween, self, from_pos, to_pos, duration, _art_pixel())


## One pixel of the scaled-up art: walks step by it, see PixelStepTween.
func _art_pixel() -> float:
	return animated_sprite.scale.x


## The visit frozen for a save. A group member's goes into its group's snapshot.
func snapshot() -> CustomerSnapshot:
	var snap := CustomerSnapshot.new()
	snap.data = customer_data
	snap.generated_name = generated_name
	snap.slot = assigned_slot
	snap.phase = _phase
	snap.group_member = _skip_interaction
	snap.position = global_position if _rampage_glasses < 0 else _rampage_home
	snap.route = _route.duplicate()
	snap.leg = _leg
	snap.pause_left = _pause_seconds
	if _leg == Leg.CENTER_PAUSE:
		snap.pause_left = maxf(0.0, _pause_seconds - (Time.get_ticks_msec() - _pause_started_msec) / 1000.0)
	snap.bubble_text = _bubble_text
	snap.time_left = _phase_timer.time_left if _phase_timer != null else 0.0
	snap.made_purchase = made_purchase
	snap.beer_ebc = _glasses.beer_ebc
	snap.glass_time_left = _glasses.serve_time_left()
	snap.glass_shown = _glasses.is_on_counter()
	snap.glass_position = _glasses.counter_position()
	snap.exit_position = _exit_position
	snap.rampage_glasses = _rampage_glasses
	snap.rampage_stomp = _rampage_stomp
	snap.walks_to_pickup = _pickup_target != Vector2.INF
	snap.pickup_position = _pickup_target if snap.walks_to_pickup else Vector2.ZERO
	return snap


## Carries on a saved visit where snapshot() left it. Call once in the tree with data, name
## and slots set.
func resume(snap: CustomerSnapshot) -> void:
	global_position = snap.position
	made_purchase = snap.made_purchase
	_skip_interaction = snap.group_member
	fill_glasses(snap.beer_ebc)
	# Shown before a walk out, which hides it again once under way.
	if snap.glass_shown:
		show_counter_glass(0.0, snap.glass_position)
	match snap.phase:
		CustomerSnapshot.Phase.WALKING_IN:
			_route = snap.route.duplicate()
			_walk_route_from(snap.leg, snap.pause_left)
		CustomerSnapshot.Phase.GREETING:
			_play_animation(ANIM_IDLE_UP)
			_enter_counter_phase(CustomerSnapshot.Phase.GREETING, snap.bubble_text, _on_preview_timeout, snap.time_left)
		CustomerSnapshot.Phase.PREVIEWING:
			_play_animation(ANIM_IDLE_UP)
			_enter_counter_phase(CustomerSnapshot.Phase.PREVIEWING, snap.bubble_text, _on_sale_timeout, snap.time_left)
		CustomerSnapshot.Phase.SERVED:
			_resume_served(snap)
		CustomerSnapshot.Phase.WAITING:
			_wait_with_group()
		CustomerSnapshot.Phase.LEAVING:
			if snap.walks_to_pickup:
				leave_counter(snap.pickup_position)
			else:
				_phase = CustomerSnapshot.Phase.LEAVING
				_walk_out(snap.exit_position)
	if snap.rampage_glasses >= 0:
		play_rampage(snap.rampage_glasses, snap.rampage_stomp)


## The sale is already in the saved money and stock; only the glass, the reply and the wait
## carry on.
func _resume_served(snap: CustomerSnapshot) -> void:
	_phase = CustomerSnapshot.Phase.SERVED
	_play_animation(ANIM_IDLE_UP)
	if made_purchase and snap.glass_time_left >= 0.0:
		_glasses.serve_after(snap.glass_time_left)
	_bubble_text = snap.bubble_text
	if snap.time_left > SpeechTiming.FADE_SECONDS:
		_say(snap.bubble_text, false, snap.time_left - SpeechTiming.FADE_SECONDS)
	_phase_timer = get_tree().create_timer(maxf(snap.time_left, 0.01), false)
	_phase_timer.timeout.connect(leave_counter)


func _on_reached_counter() -> void:
	_play_animation(ANIM_IDLE_UP)
	_enter_counter_phase(CustomerSnapshot.Phase.GREETING, generated_name + ": " + tr(customer_data.dialogue_intro), _on_preview_timeout)


## Says `text`, then moves on to `next`; `seconds` (resuming) is what was left.
func _enter_counter_phase(phase: CustomerSnapshot.Phase, text: String, next: Callable, seconds: float = -1.0) -> void:
	_phase = phase
	_bubble_text = text
	var display_time := _say(text, true, seconds)
	_phase_timer = get_tree().create_timer(display_time, false)
	_phase_timer.timeout.connect(next)


## Shows the batch the customer will pick before the sale resolves.
func _on_preview_timeout() -> void:
	_picked_batches = CustomerManager.pick_batches_for(customer_data)
	var style_names : PackedStringArray = []
	for batch : BrewBatch in _picked_batches:
		style_names.append(batch.get_style_name())
	var line := generated_name + ": " + CustomerPreviewText.line(customer_data, style_names)
	_enter_counter_phase(CustomerSnapshot.Phase.PREVIEWING, line, _on_sale_timeout, SpeechTiming.seconds_for(line, SpeechTiming.PREVIEW_BASE_SECONDS))


func _on_sale_timeout() -> void:
	_phase = CustomerSnapshot.Phase.SERVED
	# process_auto_sale() is synchronous, so signals fired during it belong to this sale.
	var outcome := SaleOutcomeCapture.new()
	outcome.start()
	var response_text := CustomerManager.process_auto_sale(customer_data, _picked_batches)
	outcome.stop()

	fill_glasses(outcome.beer_ebc)
	_show_sale_popups(outcome)
	_sway_steps = TipsyRules.sway_steps(outcome.servings, outcome.strongest_abv)

	_bubble_text = generated_name + ": " + response_text
	var display_time := _say(_bubble_text)
	var leave_after: float = display_time + SpeechTiming.FADE_SECONDS
	if outcome.bar_fight_bottles >= 0:
		play_rampage(outcome.bar_fight_bottles)
		leave_after = maxf(leave_after, BarFightRampage.DURATION_SECONDS)
	_phase_timer = get_tree().create_timer(leave_after, false)
	_phase_timer.timeout.connect(leave_counter)


## Stomps around in place throwing `glass_count` glasses, see BarFightRampage; a loaded
## fight picks up at `first_stomp`.
func play_rampage(glass_count: int, first_stomp: int = 0) -> void:
	_rampage_glasses = glass_count
	_rampage_stomp = first_stomp
	_rampage_home = global_position
	await BarFightRampage.play(self, animated_sprite, _glasses.hand_texture(), glass_count, first_stomp, func(next_stomp: int) -> void: _rampage_stomp = next_stomp)
	_rampage_glasses = -1


func _show_sale_popups(outcome: SaleOutcomeCapture) -> void:
	if outcome.xp > 0:
		made_purchase = true
		_glasses.serve_after()
		outcome.emit_xp_popup(global_position)
	outcome.emit_reputation_and_money_popups(global_position)


## Pushes a speech bubble and returns how long it stays. A `skippable` line stays silent at
## a crowded counter but takes its time, so a crowd is served at the same pace. `seconds`
## overrides the time.
func _say(text: String, skippable: bool = false, seconds: float = -1.0) -> float:
	var display_time := seconds if seconds >= 0.0 else SpeechTiming.seconds_for(text)
	if skippable and CustomerManager.is_counter_crowded():
		return display_time
	BrewerySignals.dialogue_pushed.emit(text, false, dialogue_slot, global_position, display_time, SpeechTiming.FADE_SECONDS)
	BrewerySignals.customer_spoke.emit(global_position, customer_data.voice_pitch)
	return display_time


## Colours the glasses' beer; a negative `ebc` leaves them as drawn.
func fill_glasses(ebc: int) -> void:
	_glasses.fill(ebc)


func show_beer_glass() -> void:
	_on_animated_sprite_frame_changed()
	_glasses.show_in_hand()


## See CustomerGlasses.slide_to_counter(); a group order passes its stack spot.
func show_counter_glass(slide_duration_seconds: float = CustomerGlasses.SLIDE_DURATION_SECONDS, rest_position_override: Vector2 = Vector2.INF) -> void:
	_glasses.slide_to_counter(slide_duration_seconds, rest_position_override)


func hide_counter_glass() -> void:
	_glasses.hide_counter()


## A pickup_position_override (global) sends a group member to the bar stack for their round
## first.
func leave_counter(pickup_position_override: Vector2 = Vector2.INF) -> void:
	_phase = CustomerSnapshot.Phase.LEAVING
	if pickup_position_override != Vector2.INF:
		_pickup_target = pickup_position_override
		await _walk_to_pickup_spot(pickup_position_override)
		_pickup_target = Vector2.INF

	_walk_out(global_position + Vector2(0.0, EXIT_WALK_DISTANCE))
	CustomerManager.free_slot_index(assigned_slot)


## Walks from here to `exit_position` and is gone; resume() calls it mid-way.
func _walk_out(exit_position: Vector2) -> void:
	_exit_position = exit_position
	var duration := CustomerRoute.seconds_left(global_position, exit_position, customer_data.floor_walk_speed)

	_play_animation(ANIM_WALK_TOWARDS, true)
	if made_purchase:
		hide_counter_glass()
		if customer_data.carries_glass_out:
			show_beer_glass()
	var tween := create_tween()
	PixelStepTween.move(tween, self, global_position, exit_position, duration, _art_pixel()).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)


## Short lateral walk to the counter, like walk_complex_route()'s last leg.
func _walk_to_pickup_spot(target: Vector2) -> void:
	var distance := global_position.distance_to(target)
	if distance < MIN_WALK_DISTANCE:
		return

	var walking_left := target.x < global_position.x
	_play_animation(ANIM_WALK_RIGHT, walking_left)
	var duration := distance / customer_data.floor_walk_speed

	var tween := create_tween()
	PixelStepTween.move(tween, self, global_position, target, duration, _art_pixel())
	await tween.finished

	_play_animation(ANIM_IDLE_UP)
