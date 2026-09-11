class_name Customer
extends Node2D


## Fired once walk_complex_route's tween finishes, regardless of
## skip_interaction — lets an external controller (a group visit's shared
## chant/order) know precisely when this customer has actually arrived,
## instead of guessing the walk's duration from distance and speed.
signal walk_route_finished

const FADE_TIME_SECONDS : float = 1.0
const BASE_DISPLAY_TIME_SECONDS : float = 5.0
const PER_CHARACTER_DISPLAY_TIME_SECONDS : float = 0.05
const MAX_DISPLAY_TIME_SECONDS : float = 12.0

const PREVIEW_DELAY_SECONDS : float = 2.0
const BATCH_PREVIEW_FORMAT : String = "%s: Tuo %s kiinnostaisi..."
const NOTHING_AVAILABLE_TEXT_FORMAT : String = "%s: Eipä taida olla mitään sopivaa..."

const ANIM_IDLE : StringName = &"idle"
const ANIM_IDLE_UP : StringName = &"idle_up"
const ANIM_WALK_TOWARDS : StringName = &"walk_towards"
const ANIM_WALK_RIGHT : StringName = &"walk_right"

const RECOLOR_SHADER : Shader = preload("res://assets/shaders/customer_recolor.gdshader")
const RECOLOR_HAIR_SATURATION_RANGE : Vector2 = Vector2(0.55, 0.9)
const RECOLOR_CLOTHES_SATURATION_RANGE : Vector2 = Vector2(0.55, 0.9)
const RECOLOR_SHOES_SATURATION_RANGE : Vector2 = Vector2(0.4, 0.75)
const RECOLOR_SKIN_HUE_RANGE : Vector2 = Vector2(0.03, 0.09)
const RECOLOR_SKIN_SATURATION_RANGE : Vector2 = Vector2(0.35, 0.6)
const RECOLOR_SKIN_VALUE_RANGE : Vector2 = Vector2(0.6, 0.95)

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var customer_data: CustomerData:
	set(value):
		customer_data = value
		_apply_visuals()
var assigned_slot: int = -1

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

	tween.tween_callback(_play_animation.bind(ANIM_WALK_TOWARDS, false))
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
	var response_text = CustomerManager.process_auto_sale(customer_data)
	var final_text = generated_name + ": " + response_text
	var display_time = _get_display_time_for_text(final_text)
	BrewerySignals.dialogue_pushed.emit(final_text, false, dialogue_slot, global_position, display_time, FADE_TIME_SECONDS)

	var leave_timer = get_tree().create_timer(display_time + FADE_TIME_SECONDS)
	leave_timer.timeout.connect(leave_counter)


func leave_counter() -> void:
	var exit_pos = global_position + Vector2(0.0, 150.0)
	var duration = 150.0 / customer_data.floor_walk_speed

	_play_animation(ANIM_WALK_TOWARDS)
	var tween = create_tween()
	tween.tween_property(self, "global_position", exit_pos, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)

	CustomerManager.free_slot_index(assigned_slot)