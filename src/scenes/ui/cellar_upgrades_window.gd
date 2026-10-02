class_name CellarUpgradesWindow
extends Panel

## The cellar upgrades, each bought one level at a time with money. Opened from the
## shop (GUISignals.cellar_upgrades_requested); buying goes through
## GUISignals.cellar_upgrade_requested to CellarUpgradeShop.

const TITLE_TEXT : String = "Kellarin parannukset"
const CLOSE_TEXT : String = "Sulje"
const NAME_FONT_SIZE : int = 15
const DETAIL_FONT_SIZE : int = 12
const BUY_BUTTON_WIDTH : float = 78.0
const MUTED_COLOR : Color = Color(0.75, 0.73, 0.67, 1)

@onready var title_label : Label = %TitleLabel
@onready var close_button : Button = %CloseButton
@onready var rows_vbox : VBoxContainer = %RowsVBox


func _ready() -> void:
	title_label.text = TITLE_TEXT
	close_button.text = CLOSE_TEXT
	close_button.pressed.connect(_on_close_button_pressed)
	GUISignals.cellar_upgrades_requested.connect(_on_cellar_upgrades_requested)
	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)


func _on_cellar_upgrades_requested() -> void:
	_refresh_rows()
	show()


func _on_close_button_pressed() -> void:
	GUISignals.window_closed.emit()
	hide()


func _on_brewery_state_changed(_brewery : Brewery) -> void:
	if visible:
		_refresh_rows()


func _refresh_rows() -> void:
	for child : Node in rows_vbox.get_children():
		child.queue_free()
	var brewery : Brewery = BrewEngine.current_brewery
	if brewery == null:
		return
	for upgrade : CellarUpgradeData in CellarUpgrades.all():
		rows_vbox.add_child(_build_row(upgrade, brewery))


func _build_row(upgrade : CellarUpgradeData, brewery : Brewery) -> Control:
	var level : int = brewery.cellar_upgrade_levels.get(upgrade.upgrade_id, 0)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.add_theme_constant_override("separation", 0)
	texts.add_child(_make_label("%s %s" % [upgrade.icon_placeholder, CellarUpgradeText.title_line(upgrade, level)], NAME_FONT_SIZE))
	var description : Label = _make_label(upgrade.description, DETAIL_FONT_SIZE)
	description.add_theme_color_override("font_color", MUTED_COLOR)
	texts.add_child(description)
	texts.add_child(_make_label(CellarUpgradeText.effect_lines(upgrade, level), DETAIL_FONT_SIZE))
	row.add_child(texts)

	var buy_button := Button.new()
	buy_button.custom_minimum_size = Vector2(BUY_BUTTON_WIDTH, 0)
	buy_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	buy_button.text = CellarUpgradeText.button_text(upgrade, level)
	buy_button.disabled = not CellarUpgradeRules.can_buy(level, upgrade.max_level, upgrade.cost_for_next_level(level), brewery.money)
	buy_button.pressed.connect(func() -> void: GUISignals.cellar_upgrade_requested.emit(upgrade.upgrade_id))
	row.add_child(buy_button)
	return row


func _make_label(text : String, font_size : int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	return label
