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

## Per-frame hand position for ANIM_WALK_TOWARDS (Customer-local space,
## matching AnimatedSprite2D's centered=false/offset=(-16,-32)/scale=4
## transform). ANIM_WALK_TOWARDS is now always played with flip_h=true (see
## its two _play_animation() call sites) specifically so the customer's own
## RIGHT hand — the one that stays steady at hip height across all 4
## frames for a plain walk cycle — ends up on OUR left, screen-negative-x,
## the correct mirror for a character facing the camera. These x values are
## the STEADY hand's unflipped texture position run back through the same
## mirror flip_h itself applies (screen_x = 64 - 4*tx, tx sampled from the
## sprite), so the marker and the actual (now-mirrored) rendered pixel line
## up. Since this table is shared by every archetype that doesn't get its
## own override below, "the hand that doesn't gesture" is the only choice
## that holds up across all of them. +9 on top of the derived x: a small
## manual nudge back toward center so the held glass doesn't read as
## floating too far off the body. Archetypes whose walk_towards pose
## doesn't fit this assumption (both arms swinging, a big one-sided gesture,
## crossed arms, ...) get a dedicated offsets table instead — see
## RAKSAMIES_HAND_OFFSETS, LEIJONAFANI_HAND_OFFSETS, ZGEN_CHEST_GLASS_OFFSETS.
const WALK_TOWARDS_HAND_OFFSETS : Array[Vector2] = [
	Vector2(-23, -46),
	Vector2(-7, -46),
	Vector2(-23, -46),
	Vector2(-25, -50),
]

## Zgen's walk_towards frames keep both arms crossed at the chest the whole
## cycle (no swinging hand to track — see Zgen_32.png), so instead of a
## hand position this is a small hand-authored sway around chest height.
const ZGEN_TITLE : String = "Zgen"
const ZGEN_CHEST_GLASS_OFFSETS : Array[Vector2] = [
	Vector2(-4, -68),
	Vector2(0, -66),
	Vector2(4, -68),
	Vector2(0, -66),
]

## Raksamies (and raksamies_naaras, sharing the same title) swing BOTH arms
## through walk_towards, unlike the single-swinging-hand assumption baked
## into WALK_TOWARDS_HAND_OFFSETS — checked pixel-by-pixel against
## raksamies_32.png's walk_towards row (y=64..95). Tracking the customer's
## own left hand (screen-left after this animation's flip_h=true, same
## side WALK_TOWARDS_HAND_OFFSETS uses) across all 4 frames: it rests at
## hip height on frames 0/2, tucks in near the belt on frame 1 while the
## other arm swings out, then swings out itself on frame 3.
const RAKSAMIES_TITLE : String = "Raksamies"
const RAKSAMIES_HAND_OFFSETS : Array[Vector2] = [
	Vector2(-30, -46),
	Vector2(-4, -51),
	Vector2(-30, -44),
	Vector2(-28, -58),
]

## Leijonafani (and leijonafani_naaras, sharing the same title) throws one
## arm into a raised fist-pump cheer on walk_towards — checked pixel-by-
## pixel against leijonafani_32.png's walk_towards row (y=64..95): the
## customer's own left hand rests at hip height on frames 0/2, then swings
## all the way up into the cheer on frame 1, while frame 3 catches it
## partway back down. Tracking that actual excursion (instead of pretending
## the hand stays put, like WALK_TOWARDS_HAND_OFFSETS does for archetypes
## that share this array) so the held glass visibly punches the air with him.
const LEIJONAFANI_TITLE : String = "Leijonafani"
const LEIJONAFANI_HAND_OFFSETS : Array[Vector2] = [
	Vector2(-30, -50),
	Vector2(-46, -66),
	Vector2(-30, -50),
	Vector2(-22, -58),
]

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

const RECOLOR_SHADER : Shader = preload("res://assets/shaders/customer_recolor.gdshader")
const RECOLOR_HAIR_SATURATION_RANGE : Vector2 = Vector2(0.55, 0.9)
const RECOLOR_CLOTHES_SATURATION_RANGE : Vector2 = Vector2(0.55, 0.9)
const RECOLOR_SHOES_SATURATION_RANGE : Vector2 = Vector2(0.4, 0.75)
const RECOLOR_SKIN_HUE_RANGE : Vector2 = Vector2(0.03, 0.09)
const RECOLOR_SKIN_SATURATION_RANGE : Vector2 = Vector2(0.35, 0.6)
const RECOLOR_SKIN_VALUE_RANGE : Vector2 = Vector2(0.6, 0.95)

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
## only while walking away (see WALK_TOWARDS_HAND_OFFSETS: the only pose
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
	var offsets := WALK_TOWARDS_HAND_OFFSETS
	if customer_data != null:
		if customer_data.title == ZGEN_TITLE:
			offsets = ZGEN_CHEST_GLASS_OFFSETS
		elif customer_data.title == RAKSAMIES_TITLE:
			offsets = RAKSAMIES_HAND_OFFSETS
		elif customer_data.title == LEIJONAFANI_TITLE:
			offsets = LEIJONAFANI_HAND_OFFSETS
	bottle_hand_marker.position = offsets[animated_sprite.frame % offsets.size()]


func _apply_visuals() -> void:
	animated_sprite.sprite_frames = customer_data.sprite_frames
	_apply_random_colors()
	_play_animation(ANIM_IDLE)


func _apply_random_colors() -> void:
	var recolor_material : ShaderMaterial = ShaderMaterial.new()
	recolor_material.shader = RECOLOR_SHADER
	recolor_material.set_shader_parameter("skin_base_color", customer_data.skin_base_color)
	recolor_material.set_shader_parameter("hair_base_color", customer_data.hair_base_color)
	recolor_material.set_shader_parameter("clothes_base_color", customer_data.clothes_base_color)
	recolor_material.set_shader_parameter("shoes_base_color", customer_data.shoes_base_color)
	recolor_material.set_shader_parameter("skin_target_color", _random_skin_tone() if customer_data.randomize_skin else customer_data.skin_base_color)
	recolor_material.set_shader_parameter("hair_target_color", _random_color_in_range(RECOLOR_HAIR_SATURATION_RANGE, 0.9) if customer_data.randomize_hair else customer_data.hair_base_color)
	recolor_material.set_shader_parameter("clothes_target_color", _random_color_in_range(RECOLOR_CLOTHES_SATURATION_RANGE, 0.85) if customer_data.randomize_clothes else customer_data.clothes_base_color)
	recolor_material.set_shader_parameter("shoes_target_color", _random_color_in_range(RECOLOR_SHOES_SATURATION_RANGE, 0.6) if customer_data.randomize_shoes else customer_data.shoes_base_color)
	animated_sprite.material = recolor_material


func _random_color_in_range(saturation_range: Vector2, value: float) -> Color:
	return Color.from_hsv(randf(), randf_range(saturation_range.x, saturation_range.y), value)


func _random_skin_tone() -> Color:
	var hue : float = randf_range(RECOLOR_SKIN_HUE_RANGE.x, RECOLOR_SKIN_HUE_RANGE.y)
	var saturation : float = randf_range(RECOLOR_SKIN_SATURATION_RANGE.x, RECOLOR_SKIN_SATURATION_RANGE.y)
	var value : float = randf_range(RECOLOR_SKIN_VALUE_RANGE.x, RECOLOR_SKIN_VALUE_RANGE.y)
	return Color.from_hsv(hue, saturation, value)


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
func show_counter_glass() -> void:
	var rest_position : Vector2 = counter_glass_sprite.position
	var bartender := get_tree().get_first_node_in_group(Bartender.BARTENDER_GROUP) as Bartender

	if bartender == null:
		counter_glass_sprite.show()
		return

	counter_glass_sprite.position = to_local(bartender.serve_marker.global_position)
	counter_glass_sprite.show()

	var tween := create_tween()
	tween.tween_property(counter_glass_sprite, "position", rest_position, GLASS_SLIDE_DURATION_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func hide_counter_glass() -> void:
	counter_glass_sprite.hide()


func leave_counter() -> void:
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
