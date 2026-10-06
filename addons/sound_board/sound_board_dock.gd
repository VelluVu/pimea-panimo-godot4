@tool
extends VBoxContainer

## Lists every AudioStream slot (and Array[AudioStream]) exported by the resources under
## SCAN_ROOTS, grouped by file. Drop audio files from the FileSystem dock onto a slot to
## swap it (saved at once), ▶ previews it, ✕ clears it or removes it from a list.
## Only reads exported properties, so it works for any project's custom resources.

const SCAN_ROOTS: PackedStringArray = ["res://src/resources/"]
const AUDIO_EXTENSIONS: PackedStringArray = ["wav", "ogg", "mp3"]
const NAME_COLUMN_WIDTH: float = 130.0
const EMPTY_SLOT_TEXT: String = "(empty, drop a sound)"
const APPEND_SLOT_TEXT: String = "+ drop to add"

var _filter: LineEdit
var _list: VBoxContainer
var _preview: AudioStreamPlayer
var _preview_path: String = ""
## Global script path -> whether its exported properties hold any sound.
var _class_has_audio: Dictionary = {}


func _ready() -> void:
	var bar := HBoxContainer.new()
	add_child(bar)
	_filter = LineEdit.new()
	_filter.placeholder_text = "Filter by file or slot"
	_filter.clear_button_enabled = true
	_filter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_filter.text_changed.connect(func(_text: String) -> void: refresh())
	bar.add_child(_filter)
	var refresh_button := Button.new()
	refresh_button.text = "Refresh"
	refresh_button.pressed.connect(refresh)
	bar.add_child(refresh_button)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)

	_preview = AudioStreamPlayer.new()
	_preview.finished.connect(func() -> void: _preview_path = "")
	add_child(_preview)
	refresh()


func refresh() -> void:
	for child: Node in _list.get_children():
		child.queue_free()
	_class_has_audio.clear()
	var needle: String = _filter.text.strip_edges().to_lower()
	for root: String in SCAN_ROOTS:
		for path: String in _find_resource_files(root):
			_add_resource(path, needle)


func _find_resource_files(dir_path: String) -> PackedStringArray:
	var found := PackedStringArray()
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return found
	for file: String in dir.get_files():
		if file.get_extension() == "tres":
			found.append(dir_path.path_join(file))
	for sub: String in dir.get_directories():
		found.append_array(_find_resource_files(dir_path.path_join(sub)))
	return found


func _add_resource(path: String, needle: String) -> void:
	# Loading every .tres would be slow (sprite frames), so the script is checked first.
	var script_path: String = _script_path_of(path)
	if script_path.is_empty() or not _script_has_audio(script_path):
		return
	var resource: Resource = load(path)
	if resource == null:
		return
	var slots: Array[Dictionary] = _audio_properties(resource.get_property_list())
	var file_matches: bool = needle.is_empty() or path.to_lower().contains(needle)
	var shown: Array = slots.filter(func(slot: Dictionary) -> bool:
		return file_matches or String(slot.name).to_lower().contains(needle))
	if shown.is_empty():
		return

	var header := Label.new()
	header.text = path.trim_prefix("res://src/resources/")
	header.add_theme_color_override("font_color", get_theme_color("accent_color", "Editor"))
	header.tooltip_text = path
	header.mouse_filter = Control.MOUSE_FILTER_PASS
	_list.add_child(header)
	for slot: Dictionary in shown:
		if slot.type == TYPE_ARRAY:
			_add_array_rows(resource, slot.name)
		else:
			_add_row(resource, slot.name, -1)
	_list.add_child(HSeparator.new())


## The global class whose script is in the file's header, or "" for none.
func _script_path_of(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var first_line: String = file.get_line()
	var marker := 'script_class="'
	var start: int = first_line.find(marker)
	if start < 0:
		return ""
	start += marker.length()
	var class_id: String = first_line.substr(start, first_line.find('"', start) - start)
	for entry: Dictionary in ProjectSettings.get_global_class_list():
		if entry["class"] == class_id:
			return entry["path"]
	return ""


func _script_has_audio(script_path: String) -> bool:
	if not _class_has_audio.has(script_path):
		var script := load(script_path) as Script
		_class_has_audio[script_path] = script != null and not _audio_properties(script.get_script_property_list()).is_empty()
	return _class_has_audio[script_path]


func _audio_properties(properties: Array[Dictionary]) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for property: Dictionary in properties:
		if not (property.usage & PROPERTY_USAGE_EDITOR):
			continue
		var hint: String = property.hint_string
		var single: bool = property.type == TYPE_OBJECT and hint == "AudioStream"
		var list: bool = property.type == TYPE_ARRAY and hint.ends_with(":AudioStream")
		if single or list:
			found.append(property)
	return found


func _add_array_rows(resource: Resource, property: StringName) -> void:
	var streams: Array = resource.get(property)
	for i: int in streams.size():
		_add_row(resource, property, i)
	_add_row(resource, property, streams.size())


## index -1: a single slot. index == array size: the "drop to add" row of a list.
func _add_row(resource: Resource, property: StringName, index: int) -> void:
	var stream: AudioStream = _stream_at(resource, property, index)
	var row := HBoxContainer.new()
	_list.add_child(row)

	var name_label := Label.new()
	name_label.text = String(property) if index < 0 else "%s[%d]" % [property, index]
	name_label.custom_minimum_size.x = NAME_COLUMN_WIDTH
	name_label.clip_text = true
	name_label.tooltip_text = name_label.text
	name_label.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(name_label)

	var slot := Button.new()
	slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot.clip_text = true
	slot.alignment = HORIZONTAL_ALIGNMENT_LEFT
	if stream != null:
		slot.text = stream.resource_path.get_file()
		slot.tooltip_text = stream.resource_path + "\nClick to show it in the FileSystem dock."
		slot.pressed.connect(func() -> void: EditorInterface.get_file_system_dock().navigate_to_path(stream.resource_path))
	else:
		slot.text = APPEND_SLOT_TEXT if index >= 0 else EMPTY_SLOT_TEXT
		slot.tooltip_text = "Drop audio files here from the FileSystem dock."
	slot.set_drag_forwarding(Callable(), _can_drop, _on_drop.bind(resource, property, index))
	row.add_child(slot)

	if stream == null:
		return
	var play := Button.new()
	play.text = "▶"
	play.tooltip_text = "Preview (press again to stop)"
	play.pressed.connect(_toggle_preview.bind(stream))
	row.add_child(play)
	var clear := Button.new()
	clear.text = "✕"
	clear.tooltip_text = "Clear this slot" if index < 0 else "Remove from the list"
	clear.pressed.connect(_clear.bind(resource, property, index))
	row.add_child(clear)


func _stream_at(resource: Resource, property: StringName, index: int) -> AudioStream:
	if index < 0:
		return resource.get(property) as AudioStream
	var streams: Array = resource.get(property)
	return streams[index] as AudioStream if index < streams.size() else null


func _can_drop(_at: Vector2, data: Variant) -> bool:
	return not _dropped_audio_paths(data).is_empty()


func _on_drop(_at: Vector2, data: Variant, resource: Resource, property: StringName, index: int) -> void:
	var paths: PackedStringArray = _dropped_audio_paths(data)
	if index < 0:
		resource.set(property, load(paths[0]))
	else:
		# Several files dropped on a list slot: the first replaces it, the rest follow it.
		var streams: Array = resource.get(property).duplicate()
		for i: int in paths.size():
			var stream: AudioStream = load(paths[i])
			if index + i < streams.size() and i == 0:
				streams[index] = stream
			else:
				streams.insert(mini(index + i, streams.size()), stream)
		resource.set(property, streams)
	_save(resource)


func _dropped_audio_paths(data: Variant) -> PackedStringArray:
	var paths := PackedStringArray()
	if data is Dictionary and data.get("type") == "files":
		for path: String in data.get("files", []):
			if path.get_extension().to_lower() in AUDIO_EXTENSIONS:
				paths.append(path)
	return paths


func _clear(resource: Resource, property: StringName, index: int) -> void:
	if index < 0:
		resource.set(property, null)
	else:
		var streams: Array = resource.get(property).duplicate()
		streams.remove_at(index)
		resource.set(property, streams)
	_save(resource)


func _save(resource: Resource) -> void:
	var error: Error = ResourceSaver.save(resource)
	if error != OK:
		push_error("Sound Board: could not save %s (error %d)" % [resource.resource_path, error])
	refresh.call_deferred()


func _toggle_preview(stream: AudioStream) -> void:
	var was_this: bool = _preview.playing and _preview_path == stream.resource_path
	_preview.stop()
	_preview_path = ""
	if was_this:
		return
	_preview.stream = stream
	_preview_path = stream.resource_path
	_preview.play()
