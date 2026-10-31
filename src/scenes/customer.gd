class_name Customer
extends Node2D

const EXIT_WALK_DISTANCE : float = 150.0
## Where an outburst happens when the walk's route is gone (a resumed visit).
const OUTBURST_STEP_OUT : Vector2 = Vector2(0.0, 60.0)

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
		_walker.data = value
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
var _phase_timer: SceneTreeTimer
## The walk down to the counter, so flee() can stop it halfway.
var _walk_in: Tween
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
var _walker: CustomerWalker
var _sway: CustomerSway = CustomerSway.new()
var _sprite_home_x: float = 0.0


func _ready() -> void:
	animated_sprite.frame_changed.connect(_on_animated_sprite_frame_changed)
	_glasses = CustomerGlasses.new(self, beer_glass_sprite, counter_glass_sprite)
	_walker = CustomerWalker.new(self, animated_sprite, _play_animation)
	_sprite_home_x = animated_sprite.position.x


func _process(delta: float) -> void:
	_sounds.tick(delta, self, animated_sprite, customer_data, WALK_ANIMATIONS)
	if _phase == CustomerSnapshot.Phase.LEAVING and _sway.tick(delta, _walker.art_pixel()):
		animated_sprite.position.x = _sprite_home_x + _sway.x
		_on_animated_sprite_frame_changed()


func _on_animated_sprite_frame_changed() -> void:
	var title : String = customer_data.title if customer_data != null else ""
	bottle_hand_marker.position = CustomerHandOffsets.position_for(title, animated_sprite.frame) + Vector2(_sway.x, 0.0)


func _apply_visuals() -> void:
	animated_sprite.sprite_frames = customer_data.sprite_frames
	animated_sprite.material = CustomerRecolor.build_material(customer_data)
	var glass_region : Rect2 = CustomerHandOffsets.glass_region_for(customer_data.title)
	beer_glass_sprite.region_enabled = glass_region.has_area()
	beer_glass_sprite.region_rect = glass_region
	if customer_data.hand_item != null:
		_glasses.carry_instead(customer_data.hand_item, animated_sprite.scale)
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
	_phase = CustomerSnapshot.Phase.WALKING_IN
	_end_walk_in(_walker.start(stairs_pos, center_pos, target_pos))


## At the counter a group member waits for its group; anyone else greets.
func _end_walk_in(walk_in: Tween) -> void:
	_walk_in = walk_in
	if _skip_interaction:
		walk_in.tween_callback(_wait_with_group)
	else:
		walk_in.tween_callback(_on_reached_counter)


func _wait_with_group() -> void:
	_phase = CustomerSnapshot.Phase.WAITING
	_play_animation(ANIM_IDLE_UP)


func is_group_member() -> bool:
	return _skip_interaction


func is_walking_in() -> bool:
	return _phase == CustomerSnapshot.Phase.WALKING_IN


func is_leaving() -> bool:
	return _phase == CustomerSnapshot.Phase.LEAVING


## The visit frozen for a save. A group member's goes into its group's snapshot.
func snapshot() -> CustomerSnapshot:
	var snap := CustomerSnapshot.new()
	snap.data = customer_data
	snap.generated_name = generated_name
	snap.slot = assigned_slot
	snap.phase = _phase
	snap.group_member = _skip_interaction
	snap.position = global_position if _rampage_glasses < 0 else _rampage_home
	snap.route = _walker.route.duplicate()
	snap.leg = _walker.leg
	snap.pause_left = _walker.pause_left()
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
			_phase = CustomerSnapshot.Phase.WALKING_IN
			_walker.route = snap.route.duplicate()
			_end_walk_in(_walker.walk_route_from(snap.leg, snap.pause_left))
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
		_say(snap.bubble_text, false, snap.time_left - SpeechTiming.FADE_SECONDS, false)
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
	_sway.steps = TipsyRules.sway_steps(outcome.servings, outcome.strongest_abv)

	_bubble_text = generated_name + ": " + response_text
	var display_time := _say(_bubble_text)
	var leave_after: float = display_time + SpeechTiming.FADE_SECONDS
	if outcome.bar_fight_bottles >= 0:
		play_rampage(outcome.bar_fight_bottles)
		leave_after = maxf(leave_after, BarFightRampage.DURATION_SECONDS)
	if outcome.servings > 0 and not customer_data.dialogue_sale_toast.is_empty():
		BrewerySignals.customer_sale_narrated.emit(tr(customer_data.dialogue_sale_toast))
	if outcome.servings == 0 and customer_data.outburst_animation != &"":
		var spot : Vector2 = _outburst_spot()
		leave_after = maxf(leave_after, _seconds_to(spot) + _animation_seconds(customer_data.outburst_animation))
		_burst_out(spot)
	_phase_timer = get_tree().create_timer(leave_after, false)
	_phase_timer.timeout.connect(leave_counter)


## Left with nothing: walks out to `spot` where the whole cellar sees, and plays the
## outburst. On its next frame (the shot) the toast and shake come and every other solo
## customer runs (CustomerManager.scatter_counter()).
func _burst_out(spot: Vector2) -> void:
	await _walker.walk_to(spot)
	animated_sprite.flip_h = false
	animated_sprite.play(customer_data.outburst_animation)
	await animated_sprite.frame_changed
	BrewerySignals.customer_outburst.emit(tr(customer_data.dialogue_outburst))
	CustomerManager.scatter_counter(self)


## The middle of the cellar, where customers pause on the way in; a resumed visit without
## its route steps out from the counter instead.
func _outburst_spot() -> Vector2:
	if _walker.route.size() > CustomerWalker.ROOM_CENTRE_LEG:
		return _walker.route[CustomerWalker.ROOM_CENTRE_LEG]
	return global_position + OUTBURST_STEP_OUT


func _seconds_to(spot: Vector2) -> float:
	return global_position.distance_to(spot) / customer_data.floor_walk_speed


func _animation_seconds(anim_name: StringName) -> float:
	var frames : SpriteFrames = animated_sprite.sprite_frames
	var total : float = 0.0
	for i : int in frames.get_frame_count(anim_name):
		total += frames.get_frame_duration(anim_name, i)
	return total / frames.get_animation_speed(anim_name)


## Drops whatever it was doing and runs out with nothing bought. A group member stays: its
## visit is run by GroupVisitDirector.
func flee() -> void:
	if _skip_interaction or _phase == CustomerSnapshot.Phase.LEAVING:
		return
	if _walk_in != null and _walk_in.is_valid():
		_walk_in.kill()
	if _phase_timer != null:
		for connection : Dictionary in _phase_timer.timeout.get_connections():
			_phase_timer.timeout.disconnect(connection.callable)
	BrewerySignals.customer_evicted.emit(dialogue_slot)
	leave_counter()


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
## overrides the time. `typed` false shows a restored line whole.
func _say(text: String, skippable: bool = false, seconds: float = -1.0, typed: bool = true) -> float:
	var display_time := seconds if seconds >= 0.0 else SpeechTiming.seconds_for(text)
	if skippable and CustomerManager.is_counter_crowded():
		return display_time
	BrewerySignals.dialogue_pushed.emit(text, false, dialogue_slot, global_position, display_time, SpeechTiming.FADE_SECONDS, typed)
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
		await _walker.walk_to(pickup_position_override)
		_play_animation(ANIM_IDLE_UP)
		_pickup_target = Vector2.INF

	_walk_out(global_position + Vector2(0.0, EXIT_WALK_DISTANCE))
	CustomerManager.free_slot_index(assigned_slot)


## Walks from here to `exit_position` and is gone; resume() calls it mid-way.
func _walk_out(exit_position: Vector2) -> void:
	_exit_position = exit_position
	var walk: Tween = _walker.walk_out(exit_position)
	if made_purchase:
		hide_counter_glass()
		if customer_data.carries_glass_out:
			show_beer_glass()
	walk.tween_callback(queue_free)
