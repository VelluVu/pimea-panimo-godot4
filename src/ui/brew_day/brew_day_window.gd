class_name BrewDayWindow
extends Control

## The brew day minigame: mash, then boil, then the earned quality multiplier goes to the
## Brewer. The game pauses meanwhile. Peru (or Esc) asks first and keeps the table;
## Pikakeitto brews at once at a lower quality. On a guided brew day (GuideParts, on for
## the first one) Aatu says what to do next and the pointer marks where.

const MASH_HEADER_TEXT : String = "MÄSKÄYS · %s"
const BOIL_HEADER_TEXT : String = "KEITTO · %s"
## An undiscovered style's name stays hidden until the brew reveals it.
const UNKNOWN_STYLE_TEXT : String = "Tuntematon tyyli"
const HEAT_BUTTON_TEXT : String = "LÄMMITÄ"
const TO_BOIL_BUTTON_TEXT : String = "KEITTOON"
const FINISH_BUTTON_TEXT : String = "VALMIS"
const CANCEL_BUTTON_TEXT : String = "Peru"
const QUICK_BUTTON_TEXT : String = "Pikakeitto"
const QUICK_TOOLTIP_TEXT : String = "Keitä heti ilman keittopäivää. Laatu ×%s."
const RESULT_TEXT : String = "Laatu ×%s"
const MASH_HINT_TEXT : String = "Pidä kattilan lämmitinnappia pohjassa, kunnes vesi on oikeassa lämmössä."
const PADDLE_HINT_TEXT : String = "Vedä melaa paakkujen läpi, niin ne hajoavat."
const BOIL_HINT_TEXT : String = "Pidä kattilan lämmitinnappia pohjassa, kunnes vierre on oikeassa lämmössä."

const BACKDROP_COLOR : Color = Color(0.03, 0.02, 0.04, 0.97)
const KETTLE_POSITION : Vector2 = Vector2(170, 40)
const HEAT_BUTTON_RECT : Rect2 = Rect2(260, 216, 100, 28)
const THERMO_POSITION : Vector2 = Vector2(466, 40)
## The sacks stand in a column right beside the kettle.
const SACK_COLUMN_POSITION : Vector2 = Vector2(KETTLE_POSITION.x - HopSackButton.SIZE.x - 8, 92)
const NEXT_BUTTON_RECT : Rect2 = Rect2(520, 318, 108, 28)
const RESULT_LABEL_Y : float = 96.0
const GLOW_ALPHA : float = 0.7
## The popups start inside the liquid and stay left of the column.
const POPUP_ORIGIN_DROP : float = 34.0
## The old master's speech box, under the kettle and left of the next button.
const GUIDE_RECT : Rect2 = Rect2(8, 290, 504, 62)
## Heating key; the sacks use the number keys.
const HEAT_KEY : Key = KEY_SPACE

enum Stage { MASH, MASH_DONE, BOIL, RESULT }

var _plan : BrewDayPlan
var _mash : MashSession
var _boil : BoilSession
var _stage : Stage = Stage.MASH
var _multiplier : float = BrewDayRules.NORMAL_MULTIPLIER
var _button_heat : bool = false
var _key_heat : bool = false
var _malts_added : bool = false
var _commentary : BrewDayCommentary = BrewDayCommentary.new()
var _brewery : Brewery = null

var _header : Label
var _hint : Label
var _kettle : KettleView
var _thermo : ThermoColumn
var _heat_button : HeatButton
var _malt_sack : MaltSackButton
var _sacks : HopSackColumn
var _next_button : Button
var _cancel_button : Button
var _quick_button : Button
var _result_label : Label
var _popups : BrewDayPopups
var _confirm : BrewDayConfirm
var _guide : BrewDayGuide


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	hide()
	GUISignals.brew_day_requested.connect(open)


## GUI calls this on every new run or loaded save.
func bind_brewery(brewery : Brewery) -> void:
	_brewery = brewery


## Opens the brew day for what is on the brewing table; does nothing when it cannot brew.
func open() -> void:
	var brewery : Brewery = _brewery
	if brewery == null or brewery.brew_preparation.selected_contents.is_empty():
		return
	var contents : Dictionary = brewery.brew_preparation.selected_contents
	var report : BrewResult = brewery.resolver.resolve_brew_style(contents)
	if report == null:
		return
	if brewery.machine_active(CellarMachines.AUTO_KETTLE):
		GUISignals.brew_day_finished.emit(BrewDayRules.AUTO_KETTLE_MULTIPLIER)
		return
	var table : Dictionary = {}
	for id : int in contents:
		table[id] = IngredientDatabase.get_item_by_id(id)
	_plan = BrewDayPlan.create(report.beer_style, contents, table, report.final_ebc)
	if not report.is_matched:
		_plan.style_name = StringContainer.TUNTEMATON
	elif not brewery.is_style_known(report.beer_style.style):
		_plan.style_name = UNKNOWN_STYLE_TEXT
	_guide.begin(GuideParts.is_on(GuideParts.Part.BREW_DAY, brewery))
	_start_mash()
	show()
	move_to_front()
	PauseLock.hold(self)
	GUISignals.brew_day_opened.emit()


func _close() -> void:
	_sacks.release_all()
	_kettle.clear_pours()
	_popups.clear()
	_confirm.hide()
	_guide.end()
	hide()
	PauseLock.release(self)
	GUISignals.brew_day_closed.emit()


func _start_mash() -> void:
	_stage = Stage.MASH
	_mash = _plan.new_mash()
	_boil = null
	_malts_added = false
	_commentary.reset()
	_mash.clump_appeared.connect(func(_clump : MashClump) -> void: _commentary.clump_appeared(_mash))
	_mash.clump_swiped.connect(func(clump : MashClump) -> void:
		_kettle.flash_clump(clump)
		BrewDaySound.play(BrewDaySound.CLUMP_HIT))
	_mash.clump_bounced.connect(func(_clump : MashClump) -> void: BrewDaySound.play(BrewDaySound.CLUMP_BOUNCE))
	_mash.clump_broken.connect(_on_clump_broken)
	_mash.band_left.connect(func(too_hot : bool) -> void: _commentary.band_left(_mash, too_hot))
	_mash.step_completed.connect(func(index : int) -> void:
		BrewDaySound.play(BrewDaySound.STEP_DONE)
		_commentary.step_completed(_mash, index))
	_mash.mash_completed.connect(_on_mash_completed)
	_header.text = tr(MASH_HEADER_TEXT) % tr(_plan.style_name)
	_hint.text = MASH_HINT_TEXT
	_hint.visible = not _guide.is_on()
	_thermo.mash = _mash
	_thermo.boil = null
	_kettle.clumps = _mash.clumps
	_kettle.liquid_color = KettleView.WATER_COLOR
	_kettle.murk = BrewDayLook.WATER_MURK
	_kettle.foam = 0.0
	_kettle.bubbling = false
	_kettle.reset_paddle()
	_malt_sack.reset(_plan.malt_kg)
	_malt_sack.can_lift = true
	_sacks.clear()
	_next_button.hide()
	_result_label.hide()
	_cancel_button.show()
	_quick_button.show()
	_heat_button.disabled = false


func _start_boil() -> void:
	_stage = Stage.BOIL
	_boil = _plan.new_boil()
	_boil.boil_started.connect(_commentary.boil_started)
	_boil.boil_stopped.connect(_commentary.boil_stopped)
	_boil.boiled_over.connect(func() -> void:
		BrewDaySound.play(BrewDaySound.BOIL_OVER)
		_commentary.boiled_over())
	_boil.mark_resolved.connect(_on_mark_resolved)
	_boil.stray_pour.connect(func(_id : int) -> void: _commentary.stray_pour())
	_boil.boil_completed.connect(_show_result)
	_boil.hop_stand_started.connect(func() -> void: _heat_button.disabled = true)
	_header.text = tr(BOIL_HEADER_TEXT) % tr(_plan.style_name)
	_hint.text = BOIL_HINT_TEXT
	_hint.visible = not _guide.is_on()
	_thermo.mash = null
	_thermo.boil = _boil
	_thermo.piece_ids = _plan.piece_ids
	_kettle.clumps = []
	_kettle.liquid_color = BrewDayLook.boil_color(_plan.ebc)
	_kettle.murk = BrewDayLook.BOIL_MURK
	_kettle.reset_paddle()
	_next_button.hide()
	_sacks.start(_plan, _boil)


func _show_result() -> void:
	_stage = Stage.RESULT
	_set_heating_inputs(false, false)
	_multiplier = BrewDayRules.multiplier(BrewDayRules.final_score(_mash.score(), _boil.score()))
	_result_label.text = tr(RESULT_TEXT) % NumberText.decimal(_multiplier, 2)
	_result_label.show()
	_commentary.result(_multiplier)
	var good : bool = _multiplier >= BrewDayRules.NORMAL_MULTIPLIER
	BrewDaySound.play(BrewDaySound.RESULT_GOOD if good else BrewDaySound.RESULT_LOW)
	_sacks.finish()
	_heat_button.disabled = true
	_cancel_button.hide()
	_quick_button.hide()
	_next_button.text = FINISH_BUTTON_TEXT
	_next_button.show()
	# Seen through once; Asetukset can bring the guide back.
	if _guide.is_on():
		GuideParts.finish(GuideParts.Part.BREW_DAY, _brewery)


func _process(delta : float) -> void:
	if not visible:
		return
	if _confirm.visible:
		GUISignals.brew_day_loops.emit(0.0, 0.0, false)
		if _guide.is_on():
			_guide.clear_pointer()
		return
	var heating : bool = _button_heat or _key_heat
	if _stage == Stage.MASH or _stage == Stage.MASH_DONE:
		_mash.set_heating(heating)
		_mash.step(delta)
		_commentary.mash_tick(_mash, delta, heating, _malts_added)
	elif _stage == Stage.BOIL:
		_boil.set_heating(heating)
		_boil.step(delta)
		_commentary.boil_tick(_boil)
	_malt_sack.step(delta, _stage == Stage.MASH and _mash.is_in_band())
	if _boil == null:
		var cloud : float = BrewDayLook.mash_cloud(_malt_sack.poured(), _mash.blend, _malts_added)
		_kettle.liquid_color = BrewDayLook.mash_liquid(_plan.ebc, cloud)
		_kettle.murk = BrewDayLook.mash_murk(cloud)
	else:
		_kettle.foam = _boil.foam
		_kettle.bubbling = _boil.is_boiling()
	_kettle.steam = _steam_level()
	var glow : Color = _thermo.current_needle_color()
	glow.a = GLOW_ALPHA
	_kettle.glow_color = glow if _stage != Stage.RESULT else Color.TRANSPARENT
	_heat_button.heat = _heat().power
	_heat_button.warmth = BrewDayLook.warmth(_heat().temperature, BoilSession.BOIL_MIN if _boil != null else _mash.target())
	_heat_button.held = _key_heat and _stage != Stage.RESULT
	_sacks.refresh()
	if _guide.is_on():
		_guide.show_step(_guide_step())
	_emit_loops()


func _guide_step() -> BrewDayGuideRules.Step:
	match _stage:
		Stage.MASH:
			var too_hot : bool = _mash.heat.temperature > _mash.target() + _mash.band
			return BrewDayGuideRules.mash_step(BrewDayGuideRules.Phase.MASH, _malts_added, _mash.is_in_band(), too_hot, _mash.clumps_left() > 0)
		Stage.MASH_DONE:
			return BrewDayGuideRules.mash_step(BrewDayGuideRules.Phase.MASH_DONE, true, true, false, false)
		Stage.BOIL:
			var foaming : bool = _boil.heat.temperature > BoilSession.FOAM_FROM
			return BrewDayGuideRules.boil_step(_boil.is_boiling(), foaming, _sacks.cued_sack() != null)
		_:
			return BrewDayGuideRules.mash_step(BrewDayGuideRules.Phase.RESULT, true, true, false, false)


## Skipping keeps the brew going without the guide, and ends it for this run.
func _on_guide_skipped() -> void:
	GuideParts.finish(GuideParts.Part.BREW_DAY, _brewery)
	_guide.end()


## The kettle's heat: the mash's until the boil starts.
func _heat() -> KettleHeat:
	return _boil.heat if _boil != null else _mash.heat


func _steam_level() -> float:
	if _boil == null:
		return BrewDayLook.mash_steam(_mash.heat.temperature)
	return BrewDayLook.boil_steam(_boil.heat.temperature, _boil.is_boiling(), _boil.foam)


func _emit_loops() -> void:
	var burner : float = _heat().power if _stage != Stage.RESULT else 0.0
	var boiling : bool = _stage == Stage.BOIL and _boil.is_boiling()
	var boil : float = BrewDayLook.boil_loop(boiling, _boil.foam if boiling else 0.0)
	GUISignals.brew_day_loops.emit(burner, boil, _stage == Stage.BOIL and _sacks.is_pouring())


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
			_sacks.press_key(key.keycode - KEY_1, key.pressed)


func _set_heating_inputs(button : bool, key : bool) -> void:
	if _stage == Stage.RESULT:
		button = false
		key = false
	_button_heat = button
	_key_heat = key
	# The paddle hint stays until a clump breaks.
	if (button or key) and _hint.text != PADDLE_HINT_TEXT:
		_hint.hide()
		_commentary.heating_started(_stage == Stage.MASH and not _malts_added)


func _on_malts_emptied() -> void:
	_malts_added = true
	_mash.add_malts()
	_hint.text = PADDLE_HINT_TEXT
	_hint.visible = not _guide.is_on()
	_commentary.malts_added()


func _on_clump_broken(clump : MashClump) -> void:
	_kettle.burst_clump(clump)
	BrewDaySound.play(BrewDaySound.CLUMP_BREAK)
	if _hint.text == PADDLE_HINT_TEXT:
		_hint.hide()
	_commentary.clump_broken()


func _on_mash_completed() -> void:
	_stage = Stage.MASH_DONE
	_malt_sack.can_lift = false
	_commentary.mash_completed(_mash)
	_next_button.text = TO_BOIL_BUTTON_TEXT
	_next_button.show()


func _on_mark_resolved(mark : BoilMark) -> void:
	_commentary.mark_resolved(mark, _sacks.sack_name(mark.ingredient_id))
	if mark.bittering_only and mark.result != BoilMark.Result.MISS:
		return
	if mark.result == BoilMark.Result.FULL:
		BrewDaySound.play(BrewDaySound.MARK_HIT)
		_kettle.sparkle(BrewDayLook.pellet_color(mark))
	elif mark.result == BoilMark.Result.MISS:
		BrewDaySound.play(BrewDaySound.MARK_MISS)


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
		_sacks.release_all()
		_malt_sack.put_down()


func _build() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = BACKDROP_COLOR
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	_kettle = KettleView.new()
	_kettle.position = KETTLE_POSITION
	add_child(_kettle)
	_kettle.paddle_knocked.connect(func(_speed : float) -> void: BrewDaySound.play(BrewDaySound.PADDLE_KNOCK))
	_kettle.paddle_moved.connect(func(before : PackedVector2Array, after : PackedVector2Array, blade_from : int, delta : float) -> void:
		if _mash != null and _stage != Stage.BOIL:
			_mash.paddle_moved(before, after, blade_from, delta))

	_header = _make_label(6)
	_hint = _make_label(22)
	_hint.modulate = ThermoColumn.DIM_COLOR

	_heat_button = HeatButton.new()
	_heat_button.label = HEAT_BUTTON_TEXT
	_heat_button.position = HEAT_BUTTON_RECT.position
	_heat_button.size = HEAT_BUTTON_RECT.size
	add_child(_heat_button)
	_heat_button.button_down.connect(func() -> void: _set_heating_inputs(true, _key_heat))
	_heat_button.button_up.connect(func() -> void: _set_heating_inputs(false, _key_heat))

	_thermo = ThermoColumn.new()
	_thermo.position = THERMO_POSITION
	add_child(_thermo)

	_malt_sack = MaltSackButton.new()
	_malt_sack.kettle = _kettle
	_malt_sack.position = SACK_COLUMN_POSITION
	_malt_sack.emptied.connect(_on_malts_emptied)
	add_child(_malt_sack)
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
	_quick_button.tooltip_text = tr(QUICK_TOOLTIP_TEXT) % NumberText.decimal(BrewDayRules.SKIP_MULTIPLIER, 2)
	_quick_button.focus_mode = Control.FOCUS_NONE
	_quick_button.pressed.connect(_on_quick_pressed)
	top_row.add_child(_quick_button)

	_sacks = HopSackColumn.new()
	_sacks.kettle = _kettle
	_sacks.position = SACK_COLUMN_POSITION
	add_child(_sacks)

	_result_label = Label.new()
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.add_theme_font_size_override("font_size", 32)
	_result_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_result_label.add_theme_constant_override("outline_size", 6)
	_result_label.position = Vector2(KETTLE_POSITION.x, RESULT_LABEL_Y)
	_result_label.size = Vector2(_kettle.size.x, 40)
	add_child(_result_label)

	_popups = BrewDayPopups.new()
	add_child(_popups)
	_popups.origin = KETTLE_POSITION + Vector2(KettleView.LIQUID_RECT.get_center().x, KettleView.LIQUID_RECT.position.y + POPUP_ORIGIN_DROP)
	_popups.bounds = Rect2(8, 0, THERMO_POSITION.x - 12, 360)
	_commentary.line_said.connect(_popups.show_line)
	_commentary.call_said.connect(_popups.show_call)
	_sacks.mark_opened.connect(_commentary.mark_opened)

	var guide_box := GuideSpeechBox.new()
	guide_box.position = GUIDE_RECT.position
	guide_box.size = GUIDE_RECT.size
	guide_box.skipped.connect(_on_guide_skipped)
	add_child(guide_box)
	guide_box.hide()

	_confirm = BrewDayConfirm.new()
	_confirm.cancel_confirmed.connect(_close)
	_confirm.resume_requested.connect(_toggle_confirm)
	add_child(_confirm)
	# Last, so its frames draw over everything, the confirmation too (hidden meanwhile).
	var pointer := NextStepPointer.new()
	add_child(pointer)
	_guide = BrewDayGuide.new(guide_box, pointer)
	_guide.set_targets(_heat_button, _malt_sack, _kettle, _thermo, _sacks, _next_button)


func _make_label(y : float) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	label.position.y = y
	add_child(label)
	return label


func _make_button(text : String, rect : Rect2) -> Button:
	var button := Button.new()
	button.text = text
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_NONE
	add_child(button)
	return button
