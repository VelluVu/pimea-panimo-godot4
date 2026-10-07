class_name Customer
extends Node2D

const STAIR_STEPS : int = 15
const STAIR_STEP_PAUSE_SECONDS : float = 0.05
const CENTER_PAUSE_SECONDS : float = 0.8
const EXIT_WALK_DISTANCE : float = 150.0
const MIN_WALK_DISTANCE : float = 1.0
const FADE_TIME_SECONDS : float = 1.0
const BASE_DISPLAY_TIME_SECONDS : float = 4.0
const PER_CHARACTER_DISPLAY_TIME_SECONDS : float = 0.04
const MAX_DISPLAY_TIME_SECONDS : float = 9.0

const PREVIEW_DELAY_SECONDS : float = 2.0

## Seconds between footsteps while a walk animation plays.
const FOOTSTEP_INTERVAL_SECONDS : float = 0.32
const AMBIENT_LOOP_VOLUME_DB : float = -12.0

## The legs of the walk in, in order (see walk_complex_route()).
enum Leg { STAIRS, TO_CENTER, CENTER_PAUSE, TO_COUNTER }

const ANIM_IDLE : StringName = &"idle"
const ANIM_IDLE_UP : StringName = &"idle_up"
const ANIM_WALK_TOWARDS : StringName = &"walk_towards"
const ANIM_WALK_RIGHT : StringName = &"walk_right"
const WALK_ANIMATIONS : Array[StringName] = [ANIM_WALK_TOWARDS, ANIM_WALK_RIGHT]

## How long a just-served glass sits on the counter before pickup; matches Bartender's
## serve_beer animation (2.0s) so the glass appears once the pour has finished.
const SERVE_BEER_WAIT_SECONDS : float = 2.0
## Duration of the counter-glass slide, which starts after SERVE_BEER_WAIT_SECONDS.
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

## Set when a sale went through. Gates the counter glass and the walk-away beer glass.
var made_purchase: bool = false

## Speech-bubble identity for DialogView, separate from assigned_slot: group members
## share one assigned_slot but need distinct bubbles, or their hide timers race.
## CustomerSpawner sets it (solo customers get the same value as assigned_slot).
var dialogue_slot: int = -1

var generated_name: String = "Asiakas"

## Where the visit is, kept so snapshot() can freeze it for a save and resume() can
## carry on from exactly there.
var _phase: CustomerSnapshot.Phase = CustomerSnapshot.Phase.WALKING_IN
## Group members are driven by GroupVisitDirector, which saves them with their group.
var _skip_interaction: bool = false
var _route: Array[Vector2] = []  # spawn, stairs bottom, room centre, counter spot
var _leg: int = Leg.STAIRS
var _pause_seconds: float = CENTER_PAUSE_SECONDS
var _pause_started_msec: int = 0
var _phase_timer: SceneTreeTimer
var _glass_timer: SceneTreeTimer
var _bubble_text: String = ""
var _beer_ebc: int = -1
var _exit_position: Vector2
## Where a group member walks for their glass before leaving; INF when not.
var _pickup_target: Vector2 = Vector2.INF

## The glass as drawn, before fill_glasses() colours its beer.
var _glass_texture: Texture2D
var _footstep_clock: float = 0.0
var _ambient_player: AudioStreamPlayer2D


func _ready() -> void:
	animated_sprite.frame_changed.connect(_on_animated_sprite_frame_changed)
	_glass_texture = beer_glass_sprite.texture


func _process(delta: float) -> void:
	if customer_data == null or not customer_data.makes_footsteps:
		return
	if not (animated_sprite.is_playing() and animated_sprite.animation in WALK_ANIMATIONS):
		_footstep_clock = 0.0
		return
	_footstep_clock += delta
	if _footstep_clock >= FOOTSTEP_INTERVAL_SECONDS:
		_footstep_clock -= FOOTSTEP_INTERVAL_SECONDS
		BrewerySignals.customer_stepped.emit(global_position)


func _on_animated_sprite_frame_changed() -> void:
	var title : String = customer_data.title if customer_data != null else ""
	bottle_hand_marker.position = CustomerHandOffsets.position_for(title, animated_sprite.frame)


func _apply_visuals() -> void:
	animated_sprite.sprite_frames = customer_data.sprite_frames
	animated_sprite.material = CustomerRecolor.build_material(customer_data)
	_play_animation(ANIM_IDLE)
	_start_ambient_loop()


## The loop follows the customer, so it is a child player rather than AudioManager's.
## Restarted on finish: the WAV files are not imported as loops.
func _start_ambient_loop() -> void:
	if customer_data.ambient_loop == null or _ambient_player != null:
		return
	_ambient_player = AudioStreamPlayer2D.new()
	_ambient_player.stream = customer_data.ambient_loop
	_ambient_player.bus = &"SFX"
	_ambient_player.volume_db = AMBIENT_LOOP_VOLUME_DB
	_ambient_player.finished.connect(_ambient_player.play)
	add_child(_ambient_player)
	_ambient_player.play()


func _play_animation(anim_name: StringName, flip_horizontally: bool = false) -> void:
	if animated_sprite.sprite_frames == null or not animated_sprite.sprite_frames.has_animation(anim_name):
		return
	animated_sprite.flip_h = flip_horizontally
	animated_sprite.play(anim_name)


static func get_display_time_for_text(text: String) -> float:
	return clampf(
		BASE_DISPLAY_TIME_SECONDS + text.length() * PER_CHARACTER_DISPLAY_TIME_SECONDS,
		BASE_DISPLAY_TIME_SECONDS,
		MAX_DISPLAY_TIME_SECONDS
	)


func get_customer_name() -> String:
	return generated_name


## skip_interaction is true for group members: the group's controller drives their
## dialogue, order and departure instead (see CustomerSpawner).
func walk_complex_route(stairs_pos: Vector2, center_pos: Vector2, target_pos: Vector2, skip_interaction: bool = false) -> void:
	_skip_interaction = skip_interaction
	_route = [global_position, stairs_pos, center_pos, target_pos]
	_walk_route_from(Leg.STAIRS, CENTER_PAUSE_SECONDS)


## Queues the walk in from `first_leg` on, starting where the customer stands now: a
## fresh visit starts at the top, a loaded one mid-way (resume()).
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
	for i in range(1, steps + 1):
		var step_pos := from_pos.lerp(stairs_pos, float(i) / steps)
		tween.tween_property(self, "global_position", step_pos, customer_data.stair_step_duration).set_trans(Tween.TRANS_LINEAR)
		tween.tween_interval(STAIR_STEP_PAUSE_SECONDS)


func _queue_floor_walk(tween: Tween, from_pos: Vector2, to_pos: Vector2) -> void:
	tween.tween_callback(_play_animation.bind(ANIM_WALK_RIGHT, to_pos.x < from_pos.x))
	var duration := from_pos.distance_to(to_pos) / customer_data.floor_walk_speed
	tween.tween_property(self, "global_position", to_pos, duration).set_trans(Tween.TRANS_LINEAR)


## The visit frozen for a save. A group member's goes into its group's snapshot.
func snapshot() -> CustomerSnapshot:
	var snap := CustomerSnapshot.new()
	snap.data = customer_data
	snap.generated_name = generated_name
	snap.slot = assigned_slot
	snap.phase = _phase
	snap.group_member = _skip_interaction
	snap.position = global_position
	snap.route = _route.duplicate()
	snap.leg = _leg
	snap.pause_left = _pause_seconds
	if _leg == Leg.CENTER_PAUSE:
		snap.pause_left = maxf(0.0, _pause_seconds - (Time.get_ticks_msec() - _pause_started_msec) / 1000.0)
	snap.bubble_text = _bubble_text
	snap.time_left = _phase_timer.time_left if _phase_timer != null else 0.0
	snap.made_purchase = made_purchase
	snap.beer_ebc = _beer_ebc
	snap.glass_time_left = _glass_timer.time_left if _glass_timer != null and _glass_timer.time_left > 0.0 else -1.0
	snap.glass_shown = counter_glass_sprite.visible
	snap.glass_position = counter_glass_sprite.position
	snap.exit_position = _exit_position
	snap.walks_to_pickup = _pickup_target != Vector2.INF
	snap.pickup_position = _pickup_target if snap.walks_to_pickup else Vector2.ZERO
	return snap


## Carries on a visit from a save exactly where snapshot() left it. Call after the
## customer is in the tree with its data, name and slots set.
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


## The sale is already in the saved money and stock: only the glass, the reply and
## the wait before leaving carry on.
func _resume_served(snap: CustomerSnapshot) -> void:
	_phase = CustomerSnapshot.Phase.SERVED
	_play_animation(ANIM_IDLE_UP)
	if made_purchase and snap.glass_time_left >= 0.0:
		_glass_timer = get_tree().create_timer(snap.glass_time_left)
		_glass_timer.timeout.connect(show_counter_glass)
	_bubble_text = snap.bubble_text
	if snap.time_left > FADE_TIME_SECONDS:
		_say(snap.bubble_text, false, snap.time_left - FADE_TIME_SECONDS)
	_phase_timer = get_tree().create_timer(maxf(snap.time_left, 0.01))
	_phase_timer.timeout.connect(leave_counter)


func _on_reached_counter() -> void:
	_play_animation(ANIM_IDLE_UP)
	_enter_counter_phase(CustomerSnapshot.Phase.GREETING, generated_name + ": " + tr(customer_data.dialogue_intro), _on_preview_timeout)


## Says `text` and moves on to `next` once it has been up long enough; `seconds` (when
## resuming) is what was left of it.
func _enter_counter_phase(phase: CustomerSnapshot.Phase, text: String, next: Callable, seconds: float = -1.0) -> void:
	_phase = phase
	_bubble_text = text
	var display_time := _say(text, true, seconds)
	_phase_timer = get_tree().create_timer(display_time)
	_phase_timer.timeout.connect(next)


## Shows the batch the customer will pick before the sale resolves.
func _on_preview_timeout() -> void:
	var previewed_batch : BrewBatch = CustomerManager.find_best_batch_for(customer_data)
	var preview_text : String
	if previewed_batch != null:
		preview_text = tr(customer_data.dialogue_preview_format) % previewed_batch.get_style_name()
	else:
		preview_text = tr(customer_data.dialogue_nothing_available)

	_enter_counter_phase(CustomerSnapshot.Phase.PREVIEWING, generated_name + ": " + preview_text, _on_sale_timeout)


func _on_sale_timeout() -> void:
	_phase = CustomerSnapshot.Phase.SERVED
	# process_auto_sale() is synchronous, so signals fired during it belong to this sale.
	var outcome := SaleOutcomeCapture.new()
	outcome.start()
	var response_text := CustomerManager.process_auto_sale(customer_data)
	outcome.stop()

	fill_glasses(outcome.beer_ebc)
	_show_sale_popups(outcome)

	_bubble_text = generated_name + ": " + response_text
	var display_time := _say(_bubble_text)
	var leave_after: float = display_time + FADE_TIME_SECONDS
	if outcome.bar_fight_bottles >= 0:
		BarFightRampage.play(self, animated_sprite, beer_glass_sprite.texture, outcome.bar_fight_bottles)
		leave_after = maxf(leave_after, BarFightRampage.DURATION_SECONDS)
	_phase_timer = get_tree().create_timer(leave_after)
	_phase_timer.timeout.connect(leave_counter)


func _show_sale_popups(outcome: SaleOutcomeCapture) -> void:
	if outcome.xp > 0:
		made_purchase = true
		_glass_timer = get_tree().create_timer(SERVE_BEER_WAIT_SECONDS)
		_glass_timer.timeout.connect(show_counter_glass)
		outcome.emit_xp_popup(global_position)
	outcome.emit_reputation_and_money_popups(global_position)


## Pushes a speech bubble for this customer and returns how long it stays up. A
## `skippable` line (greeting, order) stays silent at a crowded counter, leaving only the
## reaction, but still takes its time, so a crowd is served at the same pace.
## `seconds` overrides the time (a resumed line keeps what it had left).
func _say(text: String, skippable: bool = false, seconds: float = -1.0) -> float:
	var display_time := seconds if seconds >= 0.0 else get_display_time_for_text(text)
	if skippable and CustomerManager.is_counter_crowded():
		return display_time
	BrewerySignals.dialogue_pushed.emit(text, false, dialogue_slot, global_position, display_time, FADE_TIME_SECONDS)
	BrewerySignals.customer_spoke.emit(global_position, customer_data.voice_pitch)
	return display_time


## Colours the beer in this customer's glasses to match what they bought. A negative
## `ebc` (nothing sold) leaves the glass as drawn.
func fill_glasses(ebc: int) -> void:
	_beer_ebc = ebc
	if ebc < 0 or _glass_texture == null:
		return
	var filled: Texture2D = BeerColor.glass_texture(_glass_texture, ebc)
	beer_glass_sprite.texture = filled
	counter_glass_sprite.texture = filled


func show_beer_glass() -> void:
	_on_animated_sprite_frame_changed()
	beer_glass_sprite.show()


## Slides the glass from the bartender to its resting spot on the counter. Pops in at
## rest position if there is no Bartender. Runs top_level so it stays put if the
## customer walks (undone in hide_counter_glass()).
## rest_position_override (global) rests it in the bartender's stack instead; group
## orders use this, and a shorter slide_duration_seconds. Vector2.INF means no override.
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


## pickup_position_override (global) makes a group's standby member walk to the
## bar stack and grab their round first. Vector2.INF means no pickup walk.
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
	tween.tween_property(self, "global_position", exit_position, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
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
	tween.tween_property(self, "global_position", target, duration).set_trans(Tween.TRANS_LINEAR)
	await tween.finished

	_play_animation(ANIM_IDLE_UP)
