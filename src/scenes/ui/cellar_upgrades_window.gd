class_name CellarUpgradesWindow
extends Panel

## The cellar upgrades, bought one level at a time (CellarUpgradeShop).

const TITLE_TEXT : String = "Kellarin parannukset"
const NAME_FONT_SIZE : int = 16
const DETAIL_FONT_SIZE : int = 16
## Full tap height, like the steppers' buttons.
const BUY_BUTTON_SIZE : Vector2 = Vector2(78, 26)
const MUTED_COLOR : Color = Color(0.75, 0.73, 0.67, 1)
const PIPS_COLOR : Color = Color(0.9490196, 0.7882353, 0.41960785, 1)
const PIPS_GAP : int = 6

@onready var title_label : Label = %TitleLabel
@onready var rows_vbox : VBoxContainer = %RowsVBox
var _brewery : Brewery = null


func _ready() -> void:
	title_label.text = TITLE_TEXT
	WindowCloseButton.attach(self, _on_close_button_pressed)
	GUISignals.cellar_upgrades_requested.connect(_on_cellar_upgrades_requested)
	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)


## GUI calls this on every new run or loaded save.
func bind_brewery(brewery : Brewery) -> void:
	_brewery = brewery


func _on_cellar_upgrades_requested() -> void:
	_refresh_rows()
	show()


func _on_close_button_pressed() -> void:
	GUISignals.window_closed.emit()
	hide()


func _on_brewery_state_changed(_changed : Brewery) -> void:
	if visible:
		_refresh_rows()


func _refresh_rows() -> void:
	# Removed at once, so the old rows do not count when placing the dividers.
	for child : Node in rows_vbox.get_children():
		rows_vbox.remove_child(child)
		child.queue_free()
	var brewery : Brewery = _brewery
	if brewery == null:
		return
	for upgrade : CellarUpgradeData in CellarUpgrades.all():
		if rows_vbox.get_child_count() > 0:
			rows_vbox.add_child(HSeparator.new())
		rows_vbox.add_child(_build_row(upgrade, brewery))


## Two lines: name and level pips, then what the next level changes. The longer
## description is the row's tooltip.
func _build_row(upgrade : CellarUpgradeData, brewery : Brewery) -> Control:
	var level : int = brewery.cellar_upgrade_levels.get(upgrade.upgrade_id, 0)
	var owned_machine : bool = upgrade.is_machine and brewery.owns_machine(upgrade.upgrade_id)
	var description : String = upgrade.get_description()
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.add_theme_constant_override("separation", 0)
	var name_line := HBoxContainer.new()
	name_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_line.add_theme_constant_override("separation", PIPS_GAP)
	var name_label : Label = _make_label("%s %s" % [upgrade.icon_placeholder, tr(upgrade.perk_name)], NAME_FONT_SIZE, description)
	# A wrapping label in an HBox shrinks to nothing; names are short enough for one line.
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_line.add_child(name_label)
	if not upgrade.is_machine:
		var pips : Label = _make_label(CellarUpgradeText.level_pips(level, upgrade.max_level), NAME_FONT_SIZE, description)
		pips.autowrap_mode = TextServer.AUTOWRAP_OFF
		pips.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		pips.add_theme_color_override("font_color", PIPS_COLOR)
		name_line.add_child(pips)
	texts.add_child(name_line)
	var effect_text : String = CellarUpgradeText.machine_lines(upgrade, owned_machine) if upgrade.is_machine else CellarUpgradeText.effect_change(upgrade, level)
	var effect : Label = _make_label(effect_text, DETAIL_FONT_SIZE, description)
	effect.add_theme_color_override("font_color", MUTED_COLOR)
	texts.add_child(effect)
	row.add_child(texts)

	if owned_machine:
		var switch := TooltipButton.new()
		switch.custom_minimum_size = BUY_BUTTON_SIZE
		switch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		switch.toggle_mode = true
		switch.button_pressed = brewery.machine_active(upgrade.upgrade_id)
		switch.text = CellarUpgradeText.machine_button_text(switch.button_pressed)
		switch.tooltip_text = CellarUpgradeText.MACHINE_SWITCH_TOOLTIP
		switch.pressed.connect(func() -> void: GUISignals.machine_switch_requested.emit(upgrade.upgrade_id))
		row.add_child(switch)
		return row

	var buy_button := TooltipButton.new()
	buy_button.custom_minimum_size = BUY_BUTTON_SIZE
	buy_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	buy_button.text = CellarUpgradeText.button_text(upgrade, level)
	buy_button.disabled = not CellarUpgradeRules.can_buy(level, upgrade.max_level, upgrade.cost_for_next_level(level), brewery.money)
	buy_button.tooltip_text = CellarUpgradeText.buy_tooltip(upgrade, level, brewery.money)
	buy_button.pressed.connect(func() -> void: GUISignals.cellar_upgrade_requested.emit(upgrade.upgrade_id))
	row.add_child(buy_button)
	return row


func _make_label(text : String, font_size : int, tooltip : String) -> Label:
	var label := TooltipLabel.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.tooltip_text = tooltip
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	label.add_theme_font_size_override("font_size", font_size)
	return label
