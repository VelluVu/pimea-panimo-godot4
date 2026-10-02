class_name RunEffectsWindow
extends Panel

## The player-facing "why is this run going the way it is" stat sheet —
## opened from a button next to ReceiptLogButton (see
## GUISignals.run_effects_requested). Shows the real numbers behind
## everything RunModifier/RunPerk only describe in flavor text: this run's
## modifier and its stat line, the actual current LVV raid threshold, every
## active perk, and the combined totals those perks add up to (see
## Brewery.get_quality_bonus()/get_reputation_gain_multiplier()/
## get_tip_income_multiplier()) — since perks stack and a single card's own
## number isn't the number that actually matters once two or three are
## active. No timers, nothing here expires; always reflects live state,
## same "reviewable whenever" idea as SaleReceiptLogWindow.

const HEADER_FONT_SIZE : int = 15
const SECTION_SPACING : float = 10.0
const PERMANENT_PERKS_HEADER : String = "Olutopin pysyvät bonukset (%d):"

@onready var title_label : Label = %TitleLabel
@onready var close_button : Button = %CloseButton
@onready var rows_vbox : VBoxContainer = %RowsVBox


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
	GUISignals.window_closed.emit()
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

	rows_vbox.add_child(_make_header(tr(StringContainer.RUN_EFFECTS_MODIFIER_HEADER) % tr(brewery.run_modifier.modifier_name)))

	var stat_summary : String = brewery.run_modifier.get_stat_summary()
	if not stat_summary.is_empty():
		rows_vbox.add_child(_make_label(stat_summary))

	rows_vbox.add_child(_make_label(tr(StringContainer.RUN_EFFECTS_RAID_THRESHOLD_STRING) % brewery.get_effective_raid_threshold()))


func _add_perks_section(brewery : Brewery) -> void:
	# Olutoppi perks come first and apart, so they are not mistaken for this run's picks.
	var permanent_rows : Array[Dictionary] = PerkStack.rows(brewery.active_perks, true)
	if not permanent_rows.is_empty():
		rows_vbox.add_child(_make_header(tr(PERMANENT_PERKS_HEADER) % permanent_rows.size()))
		_add_perk_rows(permanent_rows)
		_add_spacer()

	var run_rows : Array[Dictionary] = PerkStack.rows(brewery.active_perks, false)
	var run_pick_count : int = 0
	for row : Dictionary in run_rows:
		run_pick_count += row[PerkStack.KEY_COUNT]
	rows_vbox.add_child(_make_header(tr(StringContainer.RUN_EFFECTS_PERKS_HEADER) % run_pick_count))
	if run_rows.is_empty():
		rows_vbox.add_child(_make_label(StringContainer.RUN_EFFECTS_NO_PERKS_STRING))
	_add_perk_rows(run_rows)

	if brewery.active_perks.is_empty():
		return
	_add_spacer()
	rows_vbox.add_child(_make_header(StringContainer.RUN_EFFECTS_TOTALS_HEADER))

	var quality_bonus := brewery.stats.total(PerkStats.QUALITY_BONUS)
	if quality_bonus != 0.0:
		rows_vbox.add_child(_make_label(tr(StringContainer.RUN_EFFECTS_TOTALS_QUALITY) % roundi(quality_bonus * 100)))

	var reputation_multiplier := brewery.stats.multiplier(PerkStats.REPUTATION_GAIN)
	if reputation_multiplier != 1.0:
		rows_vbox.add_child(_make_label(tr(StringContainer.RUN_EFFECTS_TOTALS_REPUTATION) % roundi((reputation_multiplier - 1.0) * 100)))

	var tip_multiplier := brewery.stats.multiplier(PerkStats.TIP_INCOME)
	if tip_multiplier != 1.0:
		rows_vbox.add_child(_make_label(tr(StringContainer.RUN_EFFECTS_TOTALS_TIP) % roundi((tip_multiplier - 1.0) * 100)))


func _add_perk_rows(perk_rows : Array[Dictionary]) -> void:
	for row : Dictionary in perk_rows:
		var perk : RunPerk = row[PerkStack.KEY_PERK]
		var count : int = row[PerkStack.KEY_COUNT]
		var count_suffix : String = tr(StringContainer.RUN_EFFECTS_PERK_ROW_COUNT_SUFFIX) % count if count > 1 else ""
		rows_vbox.add_child(_make_label(tr(StringContainer.RUN_EFFECTS_PERK_ROW_FORMAT) % [perk.icon_placeholder, tr(perk.perk_name), count_suffix]))

		var stat_summary : String = perk.get_stat_summary()
		if not stat_summary.is_empty():
			rows_vbox.add_child(_make_label(stat_summary))


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
