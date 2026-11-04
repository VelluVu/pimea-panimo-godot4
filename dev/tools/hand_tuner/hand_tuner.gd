extends Node2D

## Dev tool, not shipped: tunes where each customer holds the glass while walking out.
## Run this scene (F6). All walk_towards frames are shown side by side, mirrored as in the
## game; the selected frame's glass moves with the keys and S writes hand_offsets and
## hand_flipped_frames into the customer's .tres.

const CUSTOMER_DIR : String = "res://src/resources/customers/"
const CUSTOMER_SCENE : PackedScene = preload("res://src/scenes/customer.tscn")
const CELL_WIDTH : float = 160.0
const FEET_Y : float = 300.0
## Arrows move one game unit; with Shift one body pixel (customer art is drawn at 4x).
const STEP : float = 1.0
const BIG_STEP : float = 4.0
const BACKGROUND : Color = Color(0.33, 0.33, 0.38)
const SELECTED_TINT : Color = Color(1.0, 0.85, 0.4, 0.18)
const THEME : Theme = preload("res://src/resources/themes/main_theme.tres")
const FONT_SIZE : int = 16
const HELP : String = "Q/E customer   1-4 or click: frame   arrows: move (Shift x4)\nF flip   H hide glass   S save   R revert"

var _datas : Array[CustomerData] = []
var _index : int = 0
var _frame : int = 0
var _offsets : Array[Vector2] = []
var _flips : Array[bool] = []
var _dirty : bool = false
var _glass_hidden : bool = false
var _customers : Array[Customer] = []

var _title_label : Label
var _status_label : Label
var _frame_labels : Array[Label] = []


func _ready() -> void:
	RenderingServer.set_default_clear_color(BACKGROUND)
	_load_customers()
	_title_label = _add_label(Vector2(6, 2))
	_status_label = _add_label(Vector2(6, 322))
	_status_label.text = HELP
	_show_customer()


func _draw() -> void:
	draw_rect(Rect2(_frame * CELL_WIDTH, 30.0, CELL_WIDTH, FEET_Y - 20.0), SELECTED_TINT)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_frame(int(get_local_mouse_position().x / CELL_WIDTH))
		return
	if not (event is InputEventKey and event.pressed):
		return
	var key : InputEventKey = event
	var step : float = BIG_STEP if key.shift_pressed else STEP
	match key.keycode:
		KEY_Q:
			_change_customer(-1)
		KEY_E:
			_change_customer(1)
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6:
			_select_frame(key.keycode - KEY_1)
		KEY_LEFT:
			_nudge(Vector2(-step, 0))
		KEY_RIGHT:
			_nudge(Vector2(step, 0))
		KEY_UP:
			_nudge(Vector2(0, -step))
		KEY_DOWN:
			_nudge(Vector2(0, step))
		KEY_F:
			_flips[_frame] = not _flips[_frame]
			_mark_dirty()
		KEY_H:
			_glass_hidden = not _glass_hidden
			_apply_glasses()
		KEY_S:
			_save()
		KEY_R:
			_show_customer()


func _load_customers() -> void:
	var names : PackedStringArray = DirAccess.get_files_at(CUSTOMER_DIR)
	names.sort()
	for file_name : String in names:
		var path : String = CUSTOMER_DIR + file_name.trim_suffix(".remap")
		if not path.ends_with(".tres"):
			continue
		var data : CustomerData = load(path) as CustomerData
		if data != null and data.sprite_frames != null and data.carries_glass_out and data.sprite_frames.has_animation(Customer.ANIM_WALK_TOWARDS):
			_datas.append(data)


## Rebuilds the row from the saved data, dropping unsaved changes.
func _show_customer() -> void:
	for customer : Customer in _customers:
		customer.queue_free()
	_customers.clear()
	for label : Label in _frame_labels:
		label.queue_free()
	_frame_labels.clear()
	var data : CustomerData = _datas[_index]
	var frame_count : int = data.sprite_frames.get_frame_count(Customer.ANIM_WALK_TOWARDS)
	_offsets.clear()
	_flips.clear()
	for frame : int in range(frame_count):
		_offsets.append(_on_grid(CustomerHandOffsets.position_for(data.title, frame, data.hand_offsets)))
		_flips.append(CustomerHandOffsets.is_flipped(frame, data.hand_flipped_frames, maxi(data.hand_offsets.size(), 4)))
		_customers.append(_add_customer(data, frame))
		_frame_labels.append(_add_label(Vector2(frame * CELL_WIDTH + 8.0, FEET_Y + 2.0)))
	# One palette for the row, so the frames compare like for like.
	for customer : Customer in _customers:
		customer.animated_sprite.material = _customers[0].animated_sprite.material
	_frame = mini(_frame, frame_count - 1)
	_dirty = false
	_apply_glasses()


func _add_customer(data: CustomerData, frame: int) -> Customer:
	var customer : Customer = CUSTOMER_SCENE.instantiate()
	add_child(customer)
	customer.set_process(false)
	customer.customer_data = data
	MirroredAnimation.play(customer.animated_sprite, Customer.ANIM_WALK_TOWARDS, true)
	customer.animated_sprite.pause()
	customer.animated_sprite.frame = frame
	customer.fill_glasses(20)
	customer.show_beer_glass()
	customer.position = Vector2(frame * CELL_WIDTH + CELL_WIDTH / 2.0, FEET_Y)
	return customer


func _apply_glasses() -> void:
	for frame : int in range(_customers.size()):
		var customer : Customer = _customers[frame]
		customer.bottle_hand_marker.position = _offsets[frame]
		customer.beer_glass_sprite.flip_h = _flips[frame]
		customer.beer_glass_sprite.visible = not _glass_hidden
	_update_labels()
	queue_redraw()


func _update_labels() -> void:
	var data : CustomerData = _datas[_index]
	_title_label.text = "%s  (%d/%d)%s" % [data.resource_path.get_file().get_basename(), _index + 1, _datas.size(), "  *unsaved*" if _dirty else ""]
	for frame : int in range(_frame_labels.size()):
		_frame_labels[frame].text = "%d: %d, %d%s" % [frame + 1, _offsets[frame].x, _offsets[frame].y, " F" if _flips[frame] else ""]


func _select_frame(frame: int) -> void:
	if frame >= 0 and frame < _customers.size():
		_frame = frame
		_update_labels()
		queue_redraw()


## A held item drawn at body pixel size (the bucket) moves a whole body pixel at a time and
## stays on the body's grid, as the game snaps it.
func _nudge(delta: Vector2) -> void:
	var item : Texture2D = _datas[_index].hand_item
	if item != null:
		delta = delta.sign() * BIG_STEP
	_offsets[_frame] = _on_grid(_offsets[_frame] + delta)
	_mark_dirty()


func _on_grid(offset: Vector2) -> Vector2:
	var item : Texture2D = _datas[_index].hand_item
	if item == null:
		return offset
	return CustomerHandOffsets.snap_to_art_grid(offset, item.get_size(), BIG_STEP)


func _mark_dirty() -> void:
	_dirty = true
	_apply_glasses()


func _change_customer(direction: int) -> void:
	if _dirty:
		_status_label.text = "Unsaved changes: S saves, R reverts, then switch."
		return
	_index = wrapi(_index + direction, 0, _datas.size())
	_status_label.text = HELP
	_show_customer()


func _save() -> void:
	var data : CustomerData = _datas[_index]
	var offsets : Array[Vector2] = []
	offsets.assign(_offsets)
	var flipped : Array[int] = []
	for frame : int in range(_flips.size()):
		if _flips[frame]:
			flipped.append(frame)
	data.hand_offsets = offsets
	data.hand_flipped_frames = flipped
	var error : Error = _write_hand_lines(data.resource_path, offsets, flipped)
	_dirty = error != OK
	_status_label.text = "Saved %s" % data.resource_path.get_file() if error == OK else "Save failed: %s" % error_string(error)
	_update_labels()


## Rewrites only the two hand lines in the .tres text: ResourceSaver outside the editor
## drops the file's uids.
func _write_hand_lines(path: String, offsets: Array[Vector2], flipped: Array[int]) -> Error:
	var text : String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		return FileAccess.get_open_error()
	var vectors : PackedStringArray = []
	for offset : Vector2 in offsets:
		vectors.append("Vector2(%d, %d)" % [offset.x, offset.y])
	var frames : PackedStringArray = []
	for frame : int in flipped:
		frames.append(str(frame))
	var new_lines : PackedStringArray = ["hand_offsets = Array[Vector2]([%s])" % ", ".join(vectors)]
	if not flipped.is_empty():
		new_lines.append("hand_flipped_frames = Array[int]([%s])" % ", ".join(frames))
	var kept : PackedStringArray = []
	for line : String in text.split("\n"):
		if line.begins_with("hand_offsets = ") or line.begins_with("hand_flipped_frames = "):
			continue
		if line.begins_with("metadata/_custom_type_script"):
			kept.append_array(new_lines)
			new_lines.clear()
		kept.append(line)
	if not new_lines.is_empty():
		return ERR_PARSE_ERROR
	var file : FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string("\n".join(kept))
	return OK


func _add_label(at: Vector2) -> Label:
	var label : Label = Label.new()
	label.theme = THEME
	label.position = at
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	add_child(label)
	return label
