@tool
extends ConfirmationDialog

## "Luo perkki..." dialog: name, description, icon, tier and one number field
## per perk stat, saved as a RunPerk .tres in the perks folder that PerkRegistry
## loads. The stat fields come from PerkStats.definitions(), so a new stat
## shows up here without editing this file.

const PERK_FOLDER_PATH: String = "res://src/resources/perks/"
const DEFAULT_ICON: String = "⭐"

const MULTIPLIER_MIN: float = 0.0
const MULTIPLIER_MAX: float = 5.0
const FRACTION_MAX: float = 1.0
const COUNT_MAX: float = 20.0

var _name_edit: LineEdit
var _description_edit: LineEdit
var _icon_edit: LineEdit
var _tier_option: OptionButton
var _additive_check: CheckBox
## PerkStats stat name -> the SpinBox holding its value.
var _stat_spins: Dictionary = {}


func _ready() -> void:
	title = "Luo uusi perkki"
	ok_button_text = "Luo"
	cancel_button_text = "Peruuta"
	_build_ui()
	confirmed.connect(_on_confirmed)


func _build_ui() -> void:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(420, 420)
	add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	_name_edit = LineEdit.new()
	vbox.add_child(_row("Nimi", _name_edit))

	_description_edit = LineEdit.new()
	vbox.add_child(_row("Kuvaus", _description_edit))

	_icon_edit = LineEdit.new()
	_icon_edit.text = DEFAULT_ICON
	vbox.add_child(_row("Kuvake", _icon_edit))

	_tier_option = OptionButton.new()
	for tier_name: String in RunPerk.Tier.keys():
		_tier_option.add_item(tier_name.capitalize())
	vbox.add_child(_row("Harvinaisuus", _tier_option))

	_additive_check = CheckBox.new()
	_additive_check.text = "Kasvaa tasaisesti (ei kerry)"
	vbox.add_child(_additive_check)

	vbox.add_child(HSeparator.new())

	for entry: Dictionary in PerkStats.definitions():
		var spin := _make_stat_spin(entry.kind)
		_stat_spins[entry.stat] = spin
		vbox.add_child(_row(_stat_label(entry.text), spin))


## The label is the start of the stat's own display line, e.g.
## "Laatu: +%d %%" becomes "Laatu".
func _stat_label(display_text: String) -> String:
	return display_text.get_slice(":", 0)


func _make_stat_spin(kind: PerkStats.Kind) -> SpinBox:
	var spin := SpinBox.new()
	spin.value = PerkStats.neutral_value(kind)
	match kind:
		PerkStats.Kind.MULTIPLIER:
			spin.min_value = MULTIPLIER_MIN
			spin.max_value = MULTIPLIER_MAX
			spin.step = 0.01
		PerkStats.Kind.PERCENT_ADD:
			spin.min_value = 0.0
			spin.max_value = FRACTION_MAX
			spin.step = 0.01
		_:
			spin.min_value = 0
			spin.max_value = COUNT_MAX
			spin.step = 1
	return spin


func _row(label_text: String, control: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(170, 0)
	row.add_child(label)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)
	return row


## The RunPerk described by the current form values.
func build_perk() -> RunPerk:
	var perk := RunPerk.new()
	perk.perk_name = _name_edit.text.strip_edges()
	perk.description = _description_edit.text.strip_edges()
	perk.icon_placeholder = _icon_edit.text.strip_edges()
	perk.tier = _tier_option.selected as RunPerk.Tier
	perk.stacks_additively = _additive_check.button_pressed
	for entry: Dictionary in PerkStats.definitions():
		var spin: SpinBox = _stat_spins[entry.stat]
		if entry.kind == PerkStats.Kind.COUNT:
			perk.set(entry.stat, int(spin.value))
		else:
			perk.set(entry.stat, spin.value)
	return perk


func _on_confirmed() -> void:
	var perk := build_perk()
	if perk.perk_name.is_empty():
		push_warning("Dev Resource Tools: perkin nimi puuttuu, ei luotu.")
		return

	var path := PERK_FOLDER_PATH + perk.perk_name.to_snake_case() + ".tres"
	if FileAccess.file_exists(path):
		push_warning("Dev Resource Tools: %s on jo olemassa, ei ylikirjoitettu." % path)
		return

	var err := ResourceSaver.save(perk, path)
	if err != OK:
		push_error("Dev Resource Tools: tallennus epäonnistui (%s): %s" % [path, error_string(err)])
		return

	EditorInterface.get_resource_filesystem().scan()
	print("Dev Resource Tools: perkki luotu -> ", path)

	_name_edit.text = ""
	_description_edit.text = ""
