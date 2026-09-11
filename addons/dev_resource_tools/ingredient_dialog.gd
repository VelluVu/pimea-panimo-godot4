@tool
extends ConfirmationDialog

## "Luo ainesosa..." dialog: picks Malt/Hop/Yeast, fills in the shared
## IngredientData fields plus whichever stat fields that type needs, and
## saves a real MaltData/HopData/YeastData resource via ResourceSaver —
## guarantees a well-formed .tres (correct script ref, valid uid) the same
## way saving one by hand in the inspector would, instead of hand-writing
## the [gd_resource] text.

const MALT_PATH: String = "res://src/resources/ingredients/malts/"
const HOP_PATH: String = "res://src/resources/ingredients/hops/"
const YEAST_PATH: String = "res://src/resources/ingredients/yeasts/"

const TYPE_MALT: int = 0
const TYPE_HOP: int = 1
const TYPE_YEAST: int = 2

var _type_option: OptionButton
var _name_edit: LineEdit
var _description_edit: LineEdit
var _id_spin: SpinBox
var _price_spin: SpinBox
var _stat_container: VBoxContainer

var _ebc_spin: SpinBox
var _alpha_spin: SpinBox
var _beta_spin: SpinBox
var _flavor_option: OptionButton
var _attenuation_spin: SpinBox


func _ready() -> void:
	title = "Luo uusi ainesosa"
	ok_button_text = "Luo"
	cancel_button_text = "Peruuta"
	_build_ui()
	confirmed.connect(_on_confirmed)
	_type_option.item_selected.connect(_on_type_selected)
	_on_type_selected(TYPE_MALT)


func _build_ui() -> void:
	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(360, 0)
	add_child(vbox)

	_type_option = OptionButton.new()
	_type_option.add_item("Mallas")
	_type_option.add_item("Humala")
	_type_option.add_item("Hiiva")
	vbox.add_child(_row("Tyyppi", _type_option))

	_name_edit = LineEdit.new()
	vbox.add_child(_row("Nimi", _name_edit))

	_description_edit = LineEdit.new()
	vbox.add_child(_row("Kuvaus", _description_edit))

	_id_spin = SpinBox.new()
	_id_spin.min_value = 0
	_id_spin.max_value = 999
	vbox.add_child(_row("ID", _id_spin))

	_price_spin = SpinBox.new()
	_price_spin.min_value = 0
	_price_spin.max_value = 999
	_price_spin.value = 5
	vbox.add_child(_row("Hinta (€)", _price_spin))

	_stat_container = VBoxContainer.new()
	vbox.add_child(_stat_container)

	_ebc_spin = SpinBox.new()
	_ebc_spin.min_value = 0
	_ebc_spin.max_value = 999

	_alpha_spin = SpinBox.new()
	_alpha_spin.min_value = 0
	_alpha_spin.max_value = 100

	_beta_spin = SpinBox.new()
	_beta_spin.min_value = 0
	_beta_spin.max_value = 100

	_flavor_option = OptionButton.new()
	for flavor_name in HopData.FlavorProfile.keys():
		_flavor_option.add_item(flavor_name)

	_attenuation_spin = SpinBox.new()
	_attenuation_spin.min_value = 0
	_attenuation_spin.max_value = 100


func _row(label_text: String, control: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(110, 0)
	row.add_child(label)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)
	return row


func _on_type_selected(index: int) -> void:
	for child in _stat_container.get_children():
		_stat_container.remove_child(child)
		child.queue_free()

	match index:
		TYPE_MALT:
			_stat_container.add_child(_row("EBC", _ebc_spin))
		TYPE_HOP:
			_stat_container.add_child(_row("Alfahapot %", _alpha_spin))
			_stat_container.add_child(_row("Beetahapot %", _beta_spin))
			_stat_container.add_child(_row("Makuprofiili", _flavor_option))
		TYPE_YEAST:
			_stat_container.add_child(_row("Käymisaste %", _attenuation_spin))

	refresh_id_suggestion()


## Public so the plugin can re-suggest a ("next free id in range") on every
## reopen, in case new resources were created since the dialog last opened.
func refresh_id_suggestion() -> void:
	if _type_option == null:
		return

	var start : int = [100, 200, 300][_type_option.selected]
	var folder : String = [MALT_PATH, HOP_PATH, YEAST_PATH][_type_option.selected]
	var highest : int = start - 1

	var dir := DirAccess.open(folder)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var res : Resource = load(folder + file_name)
				if res != null and "id" in res and res.id > highest:
					highest = res.id
			file_name = dir.get_next()
		dir.list_dir_end()

	_id_spin.value = maxi(highest + 1, start)


func _on_confirmed() -> void:
	var display_name := _name_edit.text.strip_edges()
	if display_name.is_empty():
		push_warning("Dev Resource Tools: ainesosan nimi puuttuu, ei luotu.")
		return

	var resource : IngredientData
	var folder : String

	match _type_option.selected:
		TYPE_MALT:
			var malt := MaltData.new()
			malt.ebc = int(_ebc_spin.value)
			resource = malt
			folder = MALT_PATH
		TYPE_HOP:
			var hop := HopData.new()
			hop.alpha_acids = int(_alpha_spin.value)
			hop.beta_acids = int(_beta_spin.value)
			hop.flavor_profile = _flavor_option.selected
			resource = hop
			folder = HOP_PATH
		TYPE_YEAST:
			var yeast := YeastData.new()
			yeast.attentuation_percent = int(_attenuation_spin.value)
			resource = yeast
			folder = YEAST_PATH
		_:
			return

	resource.id = int(_id_spin.value)
	resource.name = display_name
	resource.description = _description_edit.text.strip_edges()
	resource.base_price = int(_price_spin.value)
	resource.type = [IngredientData.IngredientType.MALT, IngredientData.IngredientType.HOP, IngredientData.IngredientType.YEAST][_type_option.selected]

	var path := folder + display_name.to_snake_case() + ".tres"
	var err := ResourceSaver.save(resource, path)
	if err != OK:
		push_error("Dev Resource Tools: tallennus epäonnistui (%s): %s" % [path, error_string(err)])
		return

	EditorInterface.get_resource_filesystem().scan()
	print("Dev Resource Tools: ainesosa luotu -> ", path)

	_name_edit.text = ""
	_description_edit.text = ""
