class_name RunEffectsWindow
extends Panel

## The player-facing "why is this run going the way it is" stat sheet —
## opened from a button next to ReceiptLogButton (see
## GUISignals.run_effects_requested). Shows the real numbers behind
## everything RunModifier/RunPerk only describe in flavor text: this run's
## modifier and its stat line, the actual current AVI raid threshold, every
## active perk, and the combined totals those perks add up to (see
## Brewery.get_quality_bonus()/get_reputation_gain_multiplier()/
## get_tip_income_multiplier()) — since perks stack and a single card's own
## number isn't the number that actually matters once two or three are
## active. No timers, nothing here expires; always reflects live state,
## same "reviewable whenever" idea as SaleReceiptLogWindow.

const HEADER_FONT_SIZE : int = 15
const SECTION_SPACING : float = 10.0

@onready var title_label : Label = $MarginContainer/MainVBox/HeaderHBox/TitleLabel
@onready var close_button : Button = $MarginContainer/MainVBox/HeaderHBox/CloseButton
@onready var rows_vbox : VBoxContainer = $MarginContainer/MainVBox/ScrollContainer/RowsVBox


func _ready() -> void:
	title_label.text = StringContainer.RUN_EFFECTS_TITLE
	close_button.text = StringContainer.RUN_EFFECTS_CLOSE_TEXT
	close_button.pressed.connect(_on_close_button_pressed)

	GUISignals.run_effects_requested.connect(_on_run_effects_requested)
	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)


func _on_run_effects_requested() -> void:
	_refresh_rows()
	show()


func _on_close_button_pressed() -> void:
	hide()


func _on_brewery_state_changed(_brewery : Brewery) -> void:
	if visible:
		_refresh_rows()


func _refresh_rows() -> void:
	for child in rows_vbox.get_children():
		child.queue_free()

	var brewery := BrewEngine.current_brewery
	if brewery == null:
		return

	_add_modifier_section(brewery)
	_add_spacer()
	_add_perks_section(brewery)


func _add_modifier_section(brewery : Brewery) -> void:
	if brewery.run_modifier == null:
		rows_vbox.add_child(_make_label(StringContainer.RUN_EFFECTS_NO_MODIFIER_STRING))
		return

	rows_vbox.add_child(_make_header(StringContainer.RUN_EFFECTS_MODIFIER_HEADER % brewery.run_modifier.modifier_name))

	var stat_summary : String = brewery.run_modifier.get_stat_summary()
	if not stat_summary.is_empty():
		rows_vbox.add_child(_make_label(stat_summary))

	rows_vbox.add_child(_make_label(StringContainer.RUN_EFFECTS_RAID_THRESHOLD_STRING % brewery.get_effective_raid_threshold()))


func _add_perks_section(brewery : Brewery) -> void:
	rows_vbox.add_child(_make_header(StringContainer.RUN_EFFECTS_PERKS_HEADER % brewery.active_perks.size()))

	if brewery.active_perks.is_empty():
		rows_vbox.add_child(_make_label(StringContainer.RUN_EFFECTS_NO_PERKS_STRING))
		return

	var seen_names : Dictionary = {} # Avain: String (perk_name) -> Arvo: true, säilyttää ensimmäisen esiintymän järjestyksen
	var counts : Dictionary = {} # Avain: String (perk_name) -> Arvo: int
	var representative : Dictionary = {} # Avain: String (perk_name) -> Arvo: RunPerk

	for perk : RunPerk in brewery.active_perks:
		if not seen_names.has(perk.perk_name):
			seen_names[perk.perk_name] = true
			representative[perk.perk_name] = perk
		counts[perk.perk_name] = counts.get(perk.perk_name, 0) + 1

	for perk_name : String in seen_names.keys():
		var perk : RunPerk = representative[perk_name]
		var count : int = counts[perk_name]
		var count_suffix : String = StringContainer.RUN_EFFECTS_PERK_ROW_COUNT_SUFFIX % count if count > 1 else ""
		rows_vbox.add_child(_make_label(StringContainer.RUN_EFFECTS_PERK_ROW_FORMAT % [perk.icon_placeholder, perk_name, count_suffix]))

		var stat_summary : String = perk.get_stat_summary()
		if not stat_summary.is_empty():
			rows_vbox.add_child(_make_label(stat_summary))

	_add_spacer()
	rows_vbox.add_child(_make_header(StringContainer.RUN_EFFECTS_TOTALS_HEADER))

	var quality_bonus := brewery.get_quality_bonus()
	if quality_bonus != 0.0:
		rows_vbox.add_child(_make_label(StringContainer.RUN_EFFECTS_TOTALS_QUALITY % roundi(quality_bonus * 100)))

	var reputation_multiplier := brewery.get_reputation_gain_multiplier()
	if reputation_multiplier != 1.0:
		rows_vbox.add_child(_make_label(StringContainer.RUN_EFFECTS_TOTALS_REPUTATION % roundi((reputation_multiplier - 1.0) * 100)))

	var tip_multiplier := brewery.get_tip_income_multiplier()
	if tip_multiplier != 1.0:
		rows_vbox.add_child(_make_label(StringContainer.RUN_EFFECTS_TOTALS_TIP % roundi((tip_multiplier - 1.0) * 100)))


func _make_header(text : String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", HEADER_FONT_SIZE)
	return label


func _make_label(text : String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _add_spacer() -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, SECTION_SPACING)
	rows_vbox.add_child(spacer)
