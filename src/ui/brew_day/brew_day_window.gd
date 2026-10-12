class_name BrewDayWindow
extends Control

## The brew day minigame. The Brew button opens it for the table's brew: mash, then
## boil, then the quality multiplier it earned goes to the Brewer, which brews the table.
## The game is paused meanwhile. Peru (or Esc) asks first and leaves the table as it
## was; Pikakeitto brews at once for a fixed, lower quality. Placeholder shapes until
## the real sprites exist.

const MASH_HEADER_TEXT : String = "MÄSKÄYS · %s"
const BOIL_HEADER_TEXT : String = "KEITTO · %s"
const HEAT_BUTTON_TEXT : String = "LÄMMITÄ"
const ADD_MALTS_BUTTON_TEXT : String = "LISÄÄ MALTAAT"
const TO_BOIL_BUTTON_TEXT : String = "KEITTOON"
const FINISH_BUTTON_TEXT : String = "VALMIS"
const CANCEL_BUTTON_TEXT : String = "Peru"
const QUICK_BUTTON_TEXT : String = "Pikakeitto"
const QUICK_TOOLTIP_TEXT : String = "Keitä heti ilman keittopäivää. Laatu ×%.2f."
const CONFIRM_CANCEL_TEXT : String = "Perutaanko keittopäivä? Raaka-aineet jäävät pöydälle."
const CONFIRM_YES_TEXT : String = "Peru keitto"
const CONFIRM_NO_TEXT : String = "Jatka"
const RESULT_TEXT : String = "Laatu ×%.2f"
const SACK_TEXT : String = "%d %s\n%d %s"
const MASH_HINT_TEXT : String = "Pidä kattilan lämmitinnappia pohjassa, kunnes vesi on oikeassa lämmössä."
const PADDLE_HINT_TEXT : String = "Vedä melaa paakkujen läpi, niin ne hajoavat."
const BOIL_HINT_TEXT : String = "Pidä kattilan lämmitinnappia pohjassa, kunnes vierre on oikeassa lämmössä."

const BACKDROP_COLOR : Color = Color(0.03, 0.02, 0.04, 0.97)
const KETTLE_POSITION : Vector2 = Vector2(170, 40)
const HEAT_BUTTON_RECT : Rect2 = Rect2(260, 216, 100, 28)
const THERMO_POSITION : Vector2 = Vector2(466, 40)
const SACK_ROW_POSITION : Vector2 = Vector2(12, 306)
const SACK_SIZE : Vector2 = Vector2(112, 40)
const SACK_ROW_WIDTH : float = 500.0
const NEXT_BUTTON_RECT : Rect2 = Rect2(520, 318, 108, 28)
const MALTS_BUTTON_RECT : Rect2 = Rect2(12, 318, 140, 28)
const RESULT_LABEL_Y : float = 96.0
const FOAM_WARNING_FROM : float = 0.7
## Further than this over the band, a hot mash gets the harsher lines.
const FAR_TOO_HOT : float = 6.0
const IN_BAND_LINE_GAP : float = 5.0
const MALT_AROMA_AFTER : float = 2.5
const GLOW_ALPHA : float = 0.7
## Wort is cloudier than the finished beer; the mash more than the boil.
const GRAIN_COLOR : Color = Color(0.45, 0.36, 0.24)
const MASH_CLOUD : float = 0.45
const BOIL_CLOUD : float = 0.25
## The popups start inside the liquid and stay left of the column.
const POPUP_ORIGIN_DROP : float = 34.0
## Heating key; the sacks use the number keys.
const HEAT_KEY : Key = KEY_SPACE

## The one-shot sounds, played by the audio wiring through GUISignals.brew_day_sound.
const SOUND_MALTS : StringName = &"malts"
const SOUND_PLOP : StringName = &"plop"
const SOUND_CLUMP_HIT : StringName = &"clump_hit"
const SOUND_CLUMP_BOUNCE : StringName = &"clump_bounce"
const SOUND_CLUMP_BREAK : StringName = &"clump_break"
const SOUND_PADDLE_KNOCK : StringName = &"paddle_knock"
const SOUND_STEP_DONE : StringName = &"step_done"
const SOUND_BOIL_OVER : StringName = &"boil_over"
const SOUND_MARK_HIT : StringName = &"mark_hit"
const SOUND_MARK_MISS : StringName = &"mark_miss"
const SOUND_RESULT_GOOD : StringName = &"result_good"
const SOUND_RESULT_LOW : StringName = &"result_low"
## The boil loop starts at this level and grows with the foam.
const BOIL_SOUND_BASE : float = 0.55

enum Stage { MASH, MASH_DONE, BOIL, RESULT }

var _plan : BrewDayPlan
var _mash : MashSession
var _boil : BoilSession
var _stage : Stage = Stage.MASH
var _multiplier : float = BrewDayRules.NORMAL_MULTIPLIER
var _button_heat : bool = false
var _key_heat : bool = false
var _sack_ids : Array[int] = []
var _sack_buttons : Array[Button] = []
var _malts_added : bool = false
var _foam_warned : bool = false
var _flameout_shown : bool = false
var _malt_aroma_shown : bool = false
var _water_line_shown : bool = false
var _in_band_line_wait : float = 0.0

var _header : Label
var _hint : Label
var _kettle : KettleView
var _thermo : ThermoColumn
var _heat_button : Button
var _malts_button : Button
var _next_button : Button
var _cancel_button : Button
var _quick_button : Button
var _sack_row : HBoxContainer
var _result_label : Label
var _popups : BrewDayPopups
var _confirm : Panel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	hide()
	GUISignals.brew_day_requested.connect(open)


## Opens the brew day for what is on the brewing table; does nothing when it cannot brew.
func open() -> void:
	var brewery : Brewery = BrewEngine.current_brewery
	if brewery == null or brewery.brew_preparation.selected_contents.is_empty():
		return
	var contents : Dictionary = brewery.brew_preparation.selected_contents
	var report : BrewResult = brewery.resolver.resolve_brew_style(contents)
	if report == null:
		return
	var table : Dictionary = {}
	for id : int in contents:
		table[id] = IngredientDatabase.get_item_by_id(id)
	_plan = BrewDayPlan.create(report.beer_style, contents, table, report.final_ebc)
	if not report.is_matched:
		_plan.style_name = StringContainer.TUNTEMATON
	_start_mash()
	show()
	move_to_front()
	PauseLock.hold(self)
	GUISignals.brew_day_opened.emit()


func _close() -> void:
	_set_sacks_released()
	_popups.clear()
	_confirm.hide()
	hide()
	PauseLock.release(self)
	GUISignals.brew_day_closed.emit()


func _start_mash() -> void:
	_stage = Stage.MASH
	_mash = _plan.new_mash()
	_boil = null
	_malts_added = false
	_foam_warned = false
	_flameout_shown = false
	_malt_aroma_shown = false
	_water_line_shown = false
	_mash.clump_appeared.connect(_on_clump_appeared)
	_mash.clump_swiped.connect(func(clump : MashClump) -> void:
		_kettle.flash_clump(clump)
		GUISignals.brew_day_sound.emit(SOUND_CLUMP_HIT))
	_mash.clump_bounced.connect(func(_clump : MashClump) -> void: GUISignals.brew_day_sound.emit(SOUND_CLUMP_BOUNCE))
	_mash.clump_broken.connect(func(clump : MashClump) -> void:
		_kettle.burst_clump(clump)
		GUISignals.brew_day_sound.emit(SOUND_CLUMP_BREAK)
		if _hint.text == PADDLE_HINT_TEXT:
			_hint.hide()
		_popups.show_line(BrewDayLines.CLUMP_BROKEN_TEXT, BrewDayPopups.GOOD_COLOR))
	_mash.band_left.connect(_on_mash_band_left)
	_mash.step_completed.connect(_on_step_completed)
	_mash.mash_completed.connect(_on_mash_completed)
	_header.text = tr(MASH_HEADER_TEXT) % tr(_plan.style_name)
	_hint.text = MASH_HINT_TEXT
	_hint.show()
	_thermo.mash = _mash
	_thermo.boil = null
	_kettle.clumps = _mash.clumps
	_kettle.liquid_color = KettleView.WATER_COLOR
	_kettle.foam = 0.0
	_kettle.bubbling = false
	_kettle.reset_paddle()
	_malts_button.show()
	_next_button.hide()
	_sack_row.hide()
	_result_label.hide()
	_cancel_button.show()
	_quick_button.show()
	_heat_button.disabled = false


func _start_boil() -> void:
	_stage = Stage.BOIL
	_boil = _plan.new_boil()
	_boil.boil_started.connect(func() -> void: _popups.show_line(BrewDayLines.BOILING_TEXT, BrewDayPopups.GOOD_COLOR))
	_boil.boil_stopped.connect(func() -> void: _popups.show_line(BrewDayLines.BOIL_STOPPED_TEXT, BrewDayPopups.BAD_COLOR))
	_boil.boiled_over.connect(func() -> void:
		GUISignals.brew_day_sound.emit(SOUND_BOIL_OVER)
		_popups.show_line(BrewDayLines.pick(BrewDayLines.BOILED_OVER), BrewDayPopups.BAD_COLOR))
	_boil.mark_resolved.connect(_on_mark_resolved)
	_boil.stray_pour.connect(func(_id : int) -> void: _popups.show_line(BrewDayLines.STRAY_POUR_TEXT, BrewDayPopups.BAD_COLOR))
	_boil.boil_completed.connect(_on_boil_completed)
	_header.text = tr(BOIL_HEADER_TEXT) % tr(_plan.style_name)
	_hint.text = BOIL_HINT_TEXT
	_hint.show()
	_thermo.mash = null
	_thermo.boil = _boil
	_thermo.piece_ids = _plan.piece_ids
	_kettle.clumps = []
	_kettle.liquid_color = BeerColor.from_ebc(_plan.ebc).lerp(GRAIN_COLOR, BOIL_CLOUD)
	_kettle.reset_paddle()
	_next_button.hide()
	_build_sacks()


func _show_result() -> void:
	_stage = Stage.RESULT
	_set_heating_inputs(false, false)
	_multiplier = BrewDayRules.multiplier(BrewDayRules.final_score(_mash.score(), _boil.score()))
	_result_label.text = tr(RESULT_TEXT) % _multiplier
	_result_label.show()
	var good : bool = _multiplier >= BrewDayRules.NORMAL_MULTIPLIER
	_popups.show_line(BrewDayLines.result_line(_multiplier), BrewDayPopups.GOOD_COLOR if good else BrewDayPopups.BAD_COLOR)
	GUISignals.brew_day_sound.emit(SOUND_RESULT_GOOD if good else SOUND_RESULT_LOW)
	for button : Button in _sack_buttons:
		button.disabled = true
	_heat_button.disabled = true
	_cancel_button.hide()
	_quick_button.hide()
	_next_button.text = FINISH_BUTTON_TEXT
	_next_button.show()


func _process(delta : float) -> void:
	if not visible:
		return
	if _confirm.visible:
		GUISignals.brew_day_loops.emit(0.0, 0.0, false)
		return
	var heating : bool = _button_heat or _key_heat
	if _stage == Stage.MASH or _stage == Stage.MASH_DONE:
		_mash.set_heating(heating)
		_mash.step(delta)
		_mash_lines(delta, heating)
	elif _stage == Stage.BOIL:
		_boil.set_heating(heating)
		_boil.step(delta)
		_boil_lines()
	if _boil != null:
		_kettle.foam = _boil.foam
		_kettle.bubbling = _boil.is_boiling()
	var glow : Color = _thermo.current_needle_color()
	glow.a = GLOW_ALPHA
	_kettle.glow_color = glow if _stage != Stage.RESULT else Color.TRANSPARENT
	_heat_button.modulate = Color.WHITE.lerp(ThermoColumn.FLAME_COLOR, (_boil.heat.power if _boil != null else _mash.heat.power) * 0.6)
	_refresh_sacks()
	_emit_loops()


func _emit_loops() -> void:
	var burner : float = 0.0
	var boil : float = 0.0
	var pouring : bool = false
	if _stage != Stage.RESULT:
		burner = _boil.heat.power if _boil != null else _mash.heat.power
	if _boil != null and _stage == Stage.BOIL:
		if _boil.is_boiling():
			boil = BOIL_SOUND_BASE + (1.0 - BOIL_SOUND_BASE) * clampf(_boil.foam, 0.0, 1.0)
		pouring = _sack_ids.any(func(id : int) -> bool: return _boil.is_pouring(id))
	GUISignals.brew_day_loops.emit(burner, boil, pouring)


func _input(event : InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey:
		var key := event as InputEventKey
		get_viewport().set_input_as_handled()
		if key.echo:
			return
		if key.pressed and event.is_action(InputManager.ACTION_CANCEL):
			_toggle_confirm()
		elif key.keycode == HEAT_KEY:
			_set_heating_inputs(_button_heat, key.pressed)
		elif key.keycode >= KEY_1 and key.keycode <= KEY_9:
			_on_sack_key(key.keycode - KEY_1, key.pressed)


func _set_heating_inputs(button : bool, key : bool) -> void:
	if _stage == Stage.RESULT:
		button = false
		key = false
	_button_heat = button
	_key_heat = key
	# The paddle hint stays until a clump breaks.
	if (button or key) and _hint.text != PADDLE_HINT_TEXT:
		_hint.hide()
		if _stage == Stage.MASH and not _malts_added and not _water_line_shown:
			_water_line_shown = true
			_popups.show_line(BrewDayLines.pick(BrewDayLines.WATER_HEATING))


func _mash_lines(delta : float, heating : bool) -> void:
	_in_band_line_wait -= delta
	if _malts_added and not _malt_aroma_shown and _mash.counted >= MALT_AROMA_AFTER:
		_malt_aroma_shown = true
		_popups.show_line(BrewDayLines.MALT_AROMA_TEXT)
	elif _mash.is_counting() and _mash.is_in_band() and not heating and _in_band_line_wait <= 0.0 and randf() < delta * 0.25:
		_in_band_line_wait = IN_BAND_LINE_GAP
		_popups.show_line(BrewDayLines.pick(BrewDayLines.IN_BAND), BrewDayPopups.GOOD_COLOR)


func _boil_lines() -> void:
	if _boil.foam >= FOAM_WARNING_FROM and not _foam_warned:
		_foam_warned = true
		_popups.show_line(BrewDayLines.FOAM_WARNING_TEXT, BrewDayPopups.BAD_COLOR)
	elif _boil.foam < FOAM_WARNING_FROM * 0.5:
		_foam_warned = false
	if not _flameout_shown and _boil.counted >= BoilSchedule.BOIL_SECONDS:
		_flameout_shown = true
		_popups.show_line(BrewDayLines.FLAMEOUT_TEXT)


func _on_malts_pressed() -> void:
	_malts_added = true
	_mash.add_malts()
	GUISignals.brew_day_sound.emit(SOUND_MALTS)
	_malts_button.hide()
	_hint.text = PADDLE_HINT_TEXT
	_hint.show()
	_kettle.liquid_color = BeerColor.from_ebc(_plan.ebc).lerp(GRAIN_COLOR, MASH_CLOUD)
	_popups.show_line(BrewDayLines.MALTS_IN_TEXT)


func _on_clump_appeared(_clump : MashClump) -> void:
	# The clumps of the dough-in itself come with the malts line.
	if _malts_added and _mash.counted > 0.0:
		_popups.show_line(BrewDayLines.CLUMP_TEXT, BrewDayPopups.BAD_COLOR)


func _on_mash_band_left(too_hot : bool) -> void:
	if not too_hot:
		_popups.show_line(BrewDayLines.TOO_COLD_TEXT, BrewDayPopups.BAD_COLOR)
	elif _mash.heat.temperature > _mash.target() + _mash.band + FAR_TOO_HOT:
		_popups.show_line(BrewDayLines.pick(BrewDayLines.FAR_TOO_HOT), BrewDayPopups.BAD_COLOR)
	else:
		_popups.show_line(BrewDayLines.TOO_HOT_TEXT, BrewDayPopups.BAD_COLOR)


func _on_step_completed(index : int) -> void:
	GUISignals.brew_day_sound.emit(SOUND_STEP_DONE)
	if index < _mash.steps.size() - 1:
		_popups.show_line(BrewDayLines.STEP_DONE_TEXT, BrewDayPopups.GOOD_COLOR)


func _on_mash_completed() -> void:
	_stage = Stage.MASH_DONE
	_popups.show_line(BrewDayLines.MASH_DONE_TEXT, BrewDayPopups.GOOD_COLOR)
	if _mash.clumps_left() > 0:
		_popups.show_line(BrewDayLines.CLUMPS_LEFT_TEXT, BrewDayPopups.BAD_COLOR)
	_next_button.text = TO_BOIL_BUTTON_TEXT
	_next_button.show()


func _on_mark_resolved(mark : BoilMark) -> void:
	var good : bool = mark.result == BoilMark.Result.FULL
	if good:
		GUISignals.brew_day_sound.emit(SOUND_MARK_HIT)
	elif mark.result == BoilMark.Result.MISS:
		GUISignals.brew_day_sound.emit(SOUND_MARK_MISS)
	_popups.show_line(BrewDayLines.mark_line(mark), BrewDayPopups.GOOD_COLOR if good else BrewDayPopups.BAD_COLOR)


func _on_boil_completed() -> void:
	_show_result()


func _on_next_pressed() -> void:
	GUISignals.menu_button_pressed.emit()
	if _stage == Stage.MASH_DONE:
		_start_boil()
	elif _stage == Stage.RESULT:
		_finish(_multiplier)


func _on_quick_pressed() -> void:
	GUISignals.menu_button_pressed.emit()
	_finish(BrewDayRules.SKIP_MULTIPLIER)


## The brew comes first, so a level-up from its XP queues until the window has closed.
func _finish(multiplier : float) -> void:
	GUISignals.brew_day_finished.emit(multiplier)
	_close()


func _toggle_confirm() -> void:
	if _stage == Stage.RESULT:
		return
	_confirm.visible = not _confirm.visible
	if _confirm.visible:
		_set_heating_inputs(false, false)
		_set_sacks_released()


func _on_sack_key(index : int, pressed : bool) -> void:
	if _boil == null or _stage != Stage.BOIL or index >= _sack_ids.size():
		return
	if pressed:
		_start_pour(_sack_ids[index])
	else:
		_boil.stop_pour(_sack_ids[index])


func _start_pour(id : int) -> void:
	if float(_boil.sacks.get(id, 0.0)) > 0.0 and not _boil.is_pouring(id):
		GUISignals.brew_day_sound.emit(SOUND_PLOP)
	_boil.start_pour(id)


func _set_sacks_released() -> void:
	if _boil == null:
		return
	for id : int in _sack_ids:
		_boil.stop_pour(id)


func _build_sacks() -> void:
	for button : Button in _sack_buttons:
		button.queue_free()
	_sack_buttons.clear()
	_sack_ids = _plan.sack_ids()
	var width : float = minf(SACK_SIZE.x, SACK_ROW_WIDTH / maxi(_sack_ids.size(), 1) - 4.0)
	for i : int in _sack_ids.size():
		var id : int = _sack_ids[i]
		var button := Button.new()
		button.custom_minimum_size = Vector2(width, SACK_SIZE.y)
		button.clip_text = true
		button.focus_mode = Control.FOCUS_NONE
		button.button_down.connect(func() -> void:
			if _stage == Stage.BOIL:
				_start_pour(id))
		button.button_up.connect(func() -> void:
			if _boil != null:
				_boil.stop_pour(id))
		_sack_row.add_child(button)
		_sack_buttons.append(button)
	_sack_row.show()
	_refresh_sacks()


func _refresh_sacks() -> void:
	if _boil == null:
		return
	for i : int in _sack_buttons.size():
		var id : int = _sack_ids[i]
		var unit : String = StringContainer.KPL if _plan.piece_ids.has(id) else StringContainer.G
		var name_text : String = tr(String(_plan.names.get(id, ""))).get_slice("-", 0)
		_sack_buttons[i].text = tr(SACK_TEXT) % [i + 1, name_text, roundi(_boil.sacks.get(id, 0.0)), tr(unit)]
		if _stage == Stage.BOIL:
			_sack_buttons[i].disabled = float(_boil.sacks.get(id, 0.0)) <= 0.0 and not _boil.is_pouring(id)


func _build() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = BACKDROP_COLOR
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	_kettle = KettleView.new()
	_kettle.position = KETTLE_POSITION
	add_child(_kettle)
	_kettle.paddle_knocked.connect(func(_speed : float) -> void: GUISignals.brew_day_sound.emit(SOUND_PADDLE_KNOCK))
	_kettle.paddle_moved.connect(func(before : PackedVector2Array, after : PackedVector2Array, blade_from : int, delta : float) -> void:
		if _mash != null and _stage != Stage.BOIL:
			_mash.paddle_moved(before, after, blade_from, delta))

	_header = Label.new()
	_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_header.position.y = 6
	add_child(_header)

	_hint = Label.new()
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_hint.position.y = 22
	_hint.modulate = ThermoColumn.DIM_COLOR
	add_child(_hint)

	_heat_button = _make_button(HEAT_BUTTON_TEXT, HEAT_BUTTON_RECT)
	_heat_button.button_down.connect(func() -> void: _set_heating_inputs(true, _key_heat))
	_heat_button.button_up.connect(func() -> void: _set_heating_inputs(false, _key_heat))

	_thermo = ThermoColumn.new()
	_thermo.position = THERMO_POSITION
	add_child(_thermo)

	_malts_button = _make_button(ADD_MALTS_BUTTON_TEXT, MALTS_BUTTON_RECT)
	_malts_button.pressed.connect(_on_malts_pressed)
	_next_button = _make_button(TO_BOIL_BUTTON_TEXT, NEXT_BUTTON_RECT)
	_next_button.pressed.connect(_on_next_pressed)

	var top_row := HBoxContainer.new()
	top_row.position = Vector2(8, 6)
	add_child(top_row)
	_cancel_button = Button.new()
	_cancel_button.text = CANCEL_BUTTON_TEXT
	_cancel_button.focus_mode = Control.FOCUS_NONE
	_cancel_button.pressed.connect(_toggle_confirm)
	top_row.add_child(_cancel_button)
	_quick_button = Button.new()
	_quick_button.text = QUICK_BUTTON_TEXT
	_quick_button.tooltip_text = tr(QUICK_TOOLTIP_TEXT) % BrewDayRules.SKIP_MULTIPLIER
	_quick_button.focus_mode = Control.FOCUS_NONE
	_quick_button.pressed.connect(_on_quick_pressed)
	top_row.add_child(_quick_button)

	_sack_row = HBoxContainer.new()
	_sack_row.position = SACK_ROW_POSITION
	add_child(_sack_row)

	_result_label = Label.new()
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.add_theme_font_size_override("font_size", 32)
	_result_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_result_label.add_theme_constant_override("outline_size", 6)
	_result_label.position = Vector2(KETTLE_POSITION.x, RESULT_LABEL_Y)
	_result_label.size = Vector2(KettleView.BODY_RECT.end.x, 40)
	add_child(_result_label)

	_popups = BrewDayPopups.new()
	add_child(_popups)
	_popups.origin = KETTLE_POSITION + Vector2(KettleView.LIQUID_RECT.get_center().x, KettleView.LIQUID_RECT.position.y + POPUP_ORIGIN_DROP)
	_popups.bounds = Rect2(8, 0, THERMO_POSITION.x - 12, 360)

	_build_confirm()


func _build_confirm() -> void:
	_confirm = Panel.new()
	_confirm.size = Vector2(320, 88)
	_confirm.position = ((Vector2(640, 360) - _confirm.size) / 2.0).round()
	add_child(_confirm)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
	_confirm.add_child(box)
	var label := Label.new()
	label.text = CONFIRM_CANCEL_TEXT
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(label)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(row)
	var yes := Button.new()
	yes.text = CONFIRM_YES_TEXT
	yes.pressed.connect(func() -> void:
		GUISignals.menu_button_pressed.emit()
		_close())
	row.add_child(yes)
	var no := Button.new()
	no.text = CONFIRM_NO_TEXT
	no.pressed.connect(_toggle_confirm)
	row.add_child(no)
	_confirm.hide()


func _make_button(text : String, rect : Rect2) -> Button:
	var button := Button.new()
	button.text = text
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_NONE
	add_child(button)
	return button
