class_name PopupCardStack
extends Control

## Boxed cards (icon, heading, text) that rise in at this control's position, hold while
## drifting up and fade. A burst is queued and shown one by one; each new card pushes the
## older ones up. Runs in real seconds and while the tree is paused, so neither game speed
## nor a pause window cuts the reading time. Never takes the mouse.

const RISE_DISTANCE : float = 14.0
const DRIFT_DISTANCE : float = 8.0
const PUSH_SECONDS : float = 0.25
const EARLY_FADE_SECONDS : float = 0.25
const ICON_SIZE : Vector2 = Vector2(32, 32)
const CONTENT_SEPARATION : int = 6

var rise_seconds : float = 0.3
var hold_seconds : float = 3.0
var fade_seconds : float = 0.6
var spawn_gap_seconds : float = 0.4
var card_separation : float = 4.0
## A new card makes the oldest fade out early past this many, but waits until that one has
## been readable for min_read_seconds.
var max_visible : int = 3
var min_read_seconds : float = 2.0
var card_width : float = 180.0
## Null keeps the theme's PanelContainer panel.
var card_style : StyleBox = null
var heading_color : Color = Color(0.95, 0.79, 0.42)
var heading_font_size : int = 0
var text_font_size : int = 0

var _queue : Array[Dictionary] = []
## Holders, newest first. A holder takes the push up the stack; the card inside it rises
## and drifts, so the two tweens never fight over one position.
var _holders : Array[Control] = []
var _spawning : bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS


## Queues a card; it shows at once unless another card is still rising in.
func show_card(icon : Texture2D, heading : String, text : String) -> void:
	_queue.append({"icon": icon, "heading": heading, "text": text})
	if not _spawning:
		_spawn_next()


func queued_count() -> int:
	return _queue.size()


## The bottom edge of each card above this control's position, newest first.
static func stacked_bottoms(heights : Array[float], separation : float) -> Array[float]:
	var bottoms : Array[float] = []
	var bottom : float = 0.0
	for height : float in heights:
		bottoms.append(bottom)
		bottom += height + separation
	return bottoms


func _spawn_next() -> void:
	if _queue.is_empty():
		_spawning = false
		return
	_spawning = true
	var wait : float = _seconds_until_oldest_read()
	if wait > 0.0:
		get_tree().create_timer(wait, true, false, true).timeout.connect(_spawn_next)
		return
	var entry : Dictionary = _queue.pop_front()

	var holder := Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.set_meta(&"shown_msec", Time.get_ticks_msec())
	var card : PanelContainer = _build_card(entry["icon"], entry["heading"], entry["text"])
	card.modulate.a = 0.0
	holder.add_child(card)
	add_child(holder)
	_holders.push_front(holder)

	# The wrapped label reports its height only after a layout pass.
	await get_tree().process_frame
	if not is_instance_valid(holder):
		_spawn_next()
		return
	card.size = card.get_combined_minimum_size()
	holder.size = card.size
	_restack()
	_animate_in(holder, card)
	while _holders.size() > max_visible:
		_dismiss(_holders.pop_back())

	get_tree().create_timer(spawn_gap_seconds, true, false, true).timeout.connect(_spawn_next)


## Zero while there is room; otherwise how long the oldest card still needs on screen.
func _seconds_until_oldest_read() -> float:
	if _holders.size() < max_visible:
		return 0.0
	var shown_msec : int = _holders.back().get_meta(&"shown_msec", 0)
	return seconds_left_to_read(shown_msec, Time.get_ticks_msec(), min_read_seconds)


static func seconds_left_to_read(shown_msec : int, now_msec : int, read_seconds : float) -> float:
	return maxf(0.0, read_seconds - (now_msec - shown_msec) / 1000.0)


func _build_card(icon : Texture2D, heading : String, text : String) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size.x = card_width
	if card_style != null:
		card.add_theme_stylebox_override(&"panel", card_style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", CONTENT_SEPARATION)
	card.add_child(row)

	var icon_rect := TextureRect.new()
	icon_rect.custom_minimum_size = ICON_SIZE
	icon_rect.texture = icon
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon_rect)

	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	texts.add_theme_constant_override(&"separation", 0)
	row.add_child(texts)
	texts.add_child(_build_label(heading, heading_font_size, heading_color))
	texts.add_child(_build_label(text, text_font_size, Color.WHITE))

	_ignore_mouse(card)
	return card


func _build_label(text : String, font_size : int, color : Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override(&"font_color", color)
	if font_size > 0:
		label.add_theme_font_size_override(&"font_size", font_size)
	return label


func _ignore_mouse(node : Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child : Node in node.get_children():
		_ignore_mouse(child)


## Slides every card to its slot; a fresh holder jumps straight there.
func _restack() -> void:
	var heights : Array[float] = []
	for holder : Control in _holders:
		heights.append(holder.size.y)
	var bottoms : Array[float] = stacked_bottoms(heights, card_separation)
	for index : int in _holders.size():
		var holder : Control = _holders[index]
		var target_y : float = -bottoms[index] - holder.size.y
		if index == 0:
			holder.position.y = target_y
		else:
			holder.create_tween().set_ignore_time_scale().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT) \
				.tween_property(holder, "position:y", target_y, PUSH_SECONDS)


func _animate_in(holder : Control, card : PanelContainer) -> void:
	card.position.y = RISE_DISTANCE
	var tween : Tween = card.create_tween().set_ignore_time_scale()
	tween.tween_property(card, "position:y", 0.0, rise_seconds).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(card, "modulate:a", 1.0, rise_seconds)
	tween.tween_property(card, "position:y", -DRIFT_DISTANCE, hold_seconds + fade_seconds)
	tween.parallel().tween_property(card, "modulate:a", 0.0, fade_seconds).set_delay(hold_seconds)
	tween.tween_callback(_remove.bind(holder))
	holder.set_meta(&"tween", tween)


func _dismiss(holder : Control) -> void:
	var running : Tween = holder.get_meta(&"tween", null)
	if running != null:
		running.kill()
	var card : Control = holder.get_child(0)
	var tween : Tween = card.create_tween().set_ignore_time_scale()
	tween.tween_property(card, "modulate:a", 0.0, EARLY_FADE_SECONDS)
	tween.tween_callback(holder.queue_free)


func _remove(holder : Control) -> void:
	_holders.erase(holder)
	holder.queue_free()
