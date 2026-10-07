class_name Customer
extends Node2D


## Fired when walk_complex_route's tween finishes, whether or not skip_interaction is set.
signal walk_route_finished

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
## Set once the sale has run; until then the customer can be saved and seated again.
var _sale_done: bool = false

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
	var tween := create_tween()

	_queue_stair_descent(tween, global_position, stairs_pos)
	_queue_floor_walk(tween, stairs_pos, center_pos)
	tween.tween_callback(_play_animation.bind(ANIM_IDLE, false))
	tween.tween_interval(CENTER_PAUSE_SECONDS)
	_queue_floor_walk(tween, center_pos, target_pos)

	if skip_interaction:
		tween.tween_callback(_play_animation.bind(ANIM_IDLE_UP, false))
	else:
		tween.tween_callback(_on_reached_counter)
	tween.tween_callback(walk_route_finished.emit)


func _queue_stair_descent(tween: Tween, from_pos: Vector2, stairs_pos: Vector2) -> void:
	tween.tween_callback(_play_animation.bind(ANIM_WALK_TOWARDS, true))
	for i in range(1, STAIR_STEPS + 1):
		var step_pos := from_pos.lerp(stairs_pos, float(i) / STAIR_STEPS)
		tween.tween_property(self, "global_position", step_pos, customer_data.stair_step_duration).set_trans(Tween.TRANS_LINEAR)
		tween.tween_interval(STAIR_STEP_PAUSE_SECONDS)


func _queue_floor_walk(tween: Tween, from_pos: Vector2, to_pos: Vector2) -> void:
	tween.tween_callback(_play_animation.bind(ANIM_WALK_RIGHT, to_pos.x < from_pos.x))
	var duration := from_pos.distance_to(to_pos) / customer_data.floor_walk_speed
	tween.tween_property(self, "global_position", to_pos, duration).set_trans(Tween.TRANS_LINEAR)


## Seats a customer restored from a save straight at their counter spot.
func arrive_at_counter(counter_position: Vector2) -> void:
	global_position = counter_position
	_on_reached_counter()


func is_waiting_to_order() -> bool:
	return not _sale_done


func _on_reached_counter() -> void:
	_play_animation(ANIM_IDLE_UP)
	var display_time := _say(generated_name + ": " + tr(customer_data.dialogue_intro), true)
	get_tree().create_timer(display_time).timeout.connect(_on_preview_timeout)


## Shows the batch the customer will pick before the sale resolves.
func _on_preview_timeout() -> void:
	var previewed_batch : BrewBatch = CustomerManager.find_best_batch_for(customer_data)
	var preview_text : String
	if previewed_batch != null:
		preview_text = tr(customer_data.dialogue_preview_format) % previewed_batch.get_style_name()
	else:
		preview_text = tr(customer_data.dialogue_nothing_available)

	var display_time := _say(generated_name + ": " + preview_text, true)
	get_tree().create_timer(display_time).timeout.connect(_on_sale_timeout)


func _on_sale_timeout() -> void:
	_sale_done = true
	# process_auto_sale() is synchronous, so signals fired during it belong to this sale.
	var outcome := SaleOutcomeCapture.new()
	outcome.start()
	var response_text := CustomerManager.process_auto_sale(customer_data)
	outcome.stop()

	fill_glasses(outcome.beer_ebc)
	_show_sale_popups(outcome)

	var display_time := _say(generated_name + ": " + response_text)
	var leave_after: float = display_time + FADE_TIME_SECONDS
	if outcome.bar_fight_bottles >= 0:
		BarFightRampage.play(self, animated_sprite, beer_glass_sprite.texture, outcome.bar_fight_bottles)
		leave_after = maxf(leave_after, BarFightRampage.DURATION_SECONDS)
	get_tree().create_timer(leave_after).timeout.connect(leave_counter)


func _show_sale_popups(outcome: SaleOutcomeCapture) -> void:
	if outcome.xp > 0:
		made_purchase = true
		get_tree().create_timer(SERVE_BEER_WAIT_SECONDS).timeout.connect(show_counter_glass)
		outcome.emit_xp_popup(global_position)
	outcome.emit_reputation_and_money_popups(global_position)


## Pushes a speech bubble for this customer and returns how long it stays up. A
## `skippable` line (greeting, order) stays silent at a crowded counter, leaving only the
## reaction, but still takes its time, so a crowd is served at the same pace.
func _say(text: String, skippable: bool = false) -> float:
	var display_time := get_display_time_for_text(text)
	if skippable and CustomerManager.is_counter_crowded():
		return display_time
	BrewerySignals.dialogue_pushed.emit(text, false, dialogue_slot, global_position, display_time, FADE_TIME_SECONDS)
	BrewerySignals.customer_spoke.emit(global_position, customer_data.voice_pitch)
	return display_time


## Colours the beer in this customer's glasses to match what they bought. A negative
## `ebc` (nothing sold) leaves the glass as drawn.
func fill_glasses(ebc: int) -> void:
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
	if pickup_position_override != Vector2.INF:
		await _walk_to_pickup_spot(pickup_position_override)

	var exit_pos := global_position + Vector2(0.0, EXIT_WALK_DISTANCE)
	var duration := EXIT_WALK_DISTANCE / customer_data.floor_walk_speed

	_play_animation(ANIM_WALK_TOWARDS, true)
	if made_purchase:
		hide_counter_glass()
		if customer_data.carries_glass_out:
			show_beer_glass()
	var tween := create_tween()
	tween.tween_property(self, "global_position", exit_pos, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)

	CustomerManager.free_slot_index(assigned_slot)


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
