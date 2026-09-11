@tool
extends ConfirmationDialog

## "Luo asiakas..." dialog: picks a sprite sheet (the same 128x128, 4-row
## idle/idle_up/walk_towards/walk_right layout every customer in this
## project uses), builds its SpriteFrames programmatically instead of
## hand-writing the AtlasTexture regions, then fills in a CustomerData and
## saves both via ResourceSaver — the same guaranteed-well-formed-.tres
## approach as ingredient_dialog.gd.

const SPRITE_FRAMES_PATH: String = "res://src/resources/sprite_frames/"
const CUSTOMER_PATH: String = "res://src/resources/customers/"
const TEXTURES_PATH: String = "res://assets/textures/"

const FRAME_SIZE: int = 32

var _title_edit: LineEdit
var _customer_name_edit: LineEdit
var _first_names_edit: LineEdit
var _texture_path_edit: LineEdit
var _sprite_file_dialog: EditorFileDialog

var _primary_style_option: OptionButton
var _secondary_style_option: OptionButton
var _min_quality_spin: SpinBox
var _budget_multiplier_spin: SpinBox
var _min_reputation_spin: SpinBox

var _dialogue_intro_edit: LineEdit
var _dialogue_success_edit: LineEdit
var _dialogue_fallback_edit: LineEdit
var _dialogue_wrong_style_edit: LineEdit
var _dialogue_reject_edit: LineEdit


func _ready() -> void:
	title = "Luo uusi asiakas"
	ok_button_text = "Luo"
	cancel_button_text = "Peruuta"
	_build_ui()
	confirmed.connect(_on_confirmed)


func _build_ui() -> void:
	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(420, 0)
	add_child(vbox)

	_title_edit = LineEdit.new()
	vbox.add_child(_row("Titteli", _title_edit))

	_customer_name_edit = LineEdit.new()
	vbox.add_child(_row("Oletusnimi", _customer_name_edit))

	_first_names_edit = LineEdit.new()
	_first_names_edit.placeholder_text = "Pilkulla eroteltuna, esim. Jorma, Reijo, Pertti"
	vbox.add_child(_row("Etunimet", _first_names_edit))

	var texture_row := HBoxContainer.new()
	_texture_path_edit = LineEdit.new()
	_texture_path_edit.placeholder_text = "res://assets/textures/..."
	_texture_path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texture_row.add_child(_texture_path_edit)
	var browse_button := Button.new()
	browse_button.text = "Selaa..."
	browse_button.pressed.connect(_on_browse_pressed)
	texture_row.add_child(browse_button)
	vbox.add_child(_labeled("Spritesheet (128x128, 4 riviä)", texture_row))

	_primary_style_option = OptionButton.new()
	_secondary_style_option = OptionButton.new()
	for style_name in BeerStyle.Style.keys():
		_primary_style_option.add_item(style_name)
		_secondary_style_option.add_item(style_name)
	vbox.add_child(_row("Ensisijainen tyyli", _primary_style_option))
	vbox.add_child(_row("Toissijainen tyyli", _secondary_style_option))

	_min_quality_spin = SpinBox.new()
	_min_quality_spin.min_value = 0.0
	_min_quality_spin.max_value = 2.0
	_min_quality_spin.step = 0.05
	_min_quality_spin.value = 0.5
	vbox.add_child(_row("Min. laatu", _min_quality_spin))

	_budget_multiplier_spin = SpinBox.new()
	_budget_multiplier_spin.min_value = 0.0
	_budget_multiplier_spin.max_value = 5.0
	_budget_multiplier_spin.step = 0.1
	_budget_multiplier_spin.value = 1.0
	vbox.add_child(_row("Budjettikerroin", _budget_multiplier_spin))

	_min_reputation_spin = SpinBox.new()
	_min_reputation_spin.min_value = 0
	_min_reputation_spin.max_value = 999
	vbox.add_child(_row("Min. maine näkyäkseen", _min_reputation_spin))

	_dialogue_intro_edit = _dialogue_field(vbox, "Tervehdys", "Moro. Oisko jotain juotavaa?")
	_dialogue_success_edit = _dialogue_field(vbox, "Onnistunut myynti", "Kylläpä uppoo! Tässä rahat.")
	_dialogue_fallback_edit = _dialogue_field(vbox, "Toissijainen tyyli", "No, tämäkin käy paremman puutteessa.")
	_dialogue_wrong_style_edit = _dialogue_field(vbox, "Väärä tyyli", "Ei tää sitäkään ollu, mut menköön...")
	_dialogue_reject_edit = _dialogue_field(vbox, "Hylkäys", "Mitä helvettiä sä mulle myyt? Pitää tunkkis.")

	_sprite_file_dialog = EditorFileDialog.new()
	_sprite_file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	_sprite_file_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_sprite_file_dialog.add_filter("*.png", "PNG-kuvat")
	_sprite_file_dialog.current_dir = TEXTURES_PATH
	_sprite_file_dialog.file_selected.connect(_on_texture_selected)
	add_child(_sprite_file_dialog)


func _dialogue_field(parent: VBoxContainer, label_text: String, default_text: String) -> LineEdit:
	var edit := LineEdit.new()
	edit.text = default_text
	parent.add_child(_row(label_text, edit))
	return edit


func _row(label_text: String, control: Control) -> HBoxContainer:
	return _labeled(label_text, control)


func _labeled(label_text: String, control: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(150, 0)
	row.add_child(label)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)
	return row


func _on_browse_pressed() -> void:
	_sprite_file_dialog.popup_centered_ratio(0.7)


func _on_texture_selected(path: String) -> void:
	_texture_path_edit.text = path


## Builds the SpriteFrames every customer in this project shares: a 128x128
## sheet cut into four 32px rows — idle (3 frames), idle_up (3 frames),
## walk_towards (4 frames), walk_right (4 frames) — matching customer.gd's
## ANIM_* constants exactly.
static func _build_sprite_frames(texture: Texture2D) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")

	_add_row_animation(frames, texture, "idle", 0, 3, 4.0)
	_add_row_animation(frames, texture, "idle_up", 32, 3, 4.0)
	_add_row_animation(frames, texture, "walk_towards", 64, 4, 6.0)
	_add_row_animation(frames, texture, "walk_right", 96, 4, 6.0)

	return frames


static func _add_row_animation(frames: SpriteFrames, texture: Texture2D, anim_name: String, row_y: int, frame_count: int, speed: float) -> void:
	frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, speed)
	for i in range(frame_count):
		var region := AtlasTexture.new()
		region.atlas = texture
		region.region = Rect2(i * FRAME_SIZE, row_y, FRAME_SIZE, FRAME_SIZE)
		frames.add_frame(anim_name, region)


func _on_confirmed() -> void:
	var title_text := _title_edit.text.strip_edges()
	var texture_path := _texture_path_edit.text.strip_edges()

	if title_text.is_empty():
		push_warning("Dev Resource Tools: asiakkaan titteli puuttuu, ei luotu.")
		return
	if texture_path.is_empty():
		push_warning("Dev Resource Tools: spritesheetiä ei valittu, ei luotu.")
		return

	EditorInterface.get_resource_filesystem().scan()
	var texture : Texture2D = load(texture_path)
	if texture == null:
		push_error("Dev Resource Tools: spritesheetin lataus epäonnistui: " + texture_path)
		return

	var snake_name := title_text.to_snake_case()

	var sprite_frames := _build_sprite_frames(texture)
	var sprite_frames_path := SPRITE_FRAMES_PATH + snake_name + "_anim.tres"
	var sf_err := ResourceSaver.save(sprite_frames, sprite_frames_path)
	if sf_err != OK:
		push_error("Dev Resource Tools: SpriteFrames-tallennus epäonnistui (%s): %s" % [sprite_frames_path, error_string(sf_err)])
		return

	var customer := CustomerData.new()
	customer.title = title_text
	customer.customer_name = _customer_name_edit.text.strip_edges() if not _customer_name_edit.text.strip_edges().is_empty() else title_text

	var first_names : Array[String] = []
	for raw_name in _first_names_edit.text.split(","):
		var trimmed := raw_name.strip_edges()
		if not trimmed.is_empty():
			first_names.append(trimmed)
	customer.first_names = first_names

	customer.sprite_frames = sprite_frames
	customer.primary_style = _primary_style_option.selected
	customer.secondary_style = _secondary_style_option.selected
	customer.min_quality = _min_quality_spin.value
	customer.budget_multiplier = _budget_multiplier_spin.value
	customer.min_reputation_to_appear = int(_min_reputation_spin.value)

	customer.dialogue_intro = _dialogue_intro_edit.text
	customer.dialogue_success = _dialogue_success_edit.text
	customer.dialogue_fallback = _dialogue_fallback_edit.text
	customer.dialogue_wrong_style = _dialogue_wrong_style_edit.text
	customer.dialogue_reject = _dialogue_reject_edit.text

	var customer_path := CUSTOMER_PATH + snake_name + ".tres"
	var err := ResourceSaver.save(customer, customer_path)
	if err != OK:
		push_error("Dev Resource Tools: asiakkaan tallennus epäonnistui (%s): %s" % [customer_path, error_string(err)])
		return

	EditorInterface.get_resource_filesystem().scan()
	print("Dev Resource Tools: asiakas luotu -> ", customer_path, " (", sprite_frames_path, ")")
