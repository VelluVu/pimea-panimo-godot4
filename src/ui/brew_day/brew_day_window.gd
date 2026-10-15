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
const MALT_SACK_TEXT : String = "Maltaat"
const MALT_AMOUNT_FORMAT : String = "%s %s"
## Shown on the malt sack while the water is at the malt marker.
const MALT_CUE_TEXT : String = "NYT"
## The malt sack is carried and poured like a hop sack, under an id no ingredient has.
const MALT_SACK_ID : int = -1
## Seconds of pouring to empty the malt sack; the malts count as added when it is empty.
const MALT_POUR_SECONDS : float = 2.0
## How far the pour alone takes the water toward the mash colour; blending does the rest.
const POUR_CLOUD : float = 0.3
## The heater button is cold this many degrees under the target and fully warm at it.
const WARM_SPAN : float = 15.0
const TO_BOIL_BUTTON_TEXT : String = "KEITTOON"
const FINISH_BUTTON_TEXT : String = "VALMIS"
const CANCEL_BUTTON_TEXT : String = "Peru"
const QUICK_BUTTON_TEXT : String = "Pikakeitto"
const QUICK_TOOLTIP_TEXT : String = "Keitä heti ilman keittopäivää. Laatu ×%.2f."
const CONFIRM_CANCEL_TEXT : String = "Perutaanko keittopäivä? Raaka-aineet jäävät pöydälle."
const CONFIRM_YES_TEXT : String = "Peru keitto"
const CONFIRM_NO_TEXT : String = "Jatka"
const RESULT_TEXT : String = "Laatu ×%.2f"
const MASH_HINT_TEXT : String = "Pidä kattilan lämmitinnappia pohjassa, kunnes vesi on oikeassa lämmössä."
const PADDLE_HINT_TEXT : String = "Vedä melaa paakkujen läpi, niin ne hajoavat."
const BOIL_HINT_TEXT : String = "Pidä kattilan lämmitinnappia pohjassa, kunnes vierre on oikeassa lämmössä."

const BACKDROP_COLOR : Color = Color(0.03, 0.02, 0.04, 0.97)
const KETTLE_POSITION : Vector2 = Vector2(170, 40)
const HEAT_BUTTON_RECT : Rect2 = Rect2(260, 216, 100, 28)
const THERMO_POSITION : Vector2 = Vector2(466, 40)
## The sacks stand in a column right beside the kettle.
const SACK_COLUMN_POSITION : Vector2 = Vector2(KETTLE_POSITION.x - HopSackButton.SIZE.x - 8, 92)
const SACK_GAP : int = 6
## Pellet colours: the bittering hops darkest, the aroma hops brightest, like potions.
const PELLET_COLORS : Dictionary = {
	HopAddition.Kind.BITTERING: Color(0.2, 0.45, 0.16),
	HopAddition.Kind.FLAVOR: Color(0.38, 0.7, 0.22),
	HopAddition.Kind.AROMA: Color(0.62, 0.95, 0.32),
	HopAddition.Kind.SPICE: Color(0.95, 0.56, 0.24),
}
const JUNIPER_COLOR : Color = Color(0.4, 0.42, 0.8)
## Pellets in a tapped-in handful of spice.
const SPICE_HANDFUL : int = 12
## A sack starts wobbling this long before its mark opens.
const CUE_LEAD : float = 1.5
## The big call when a mark opens: the mark and the hop, e.g. "AROMI: Citra!".
const CALL_TEXT : String = "%s: %s!"
const NEXT_BUTTON_RECT : Rect2 = Rect2(520, 318, 108, 28)
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
## How much each liquid hides the paddle's blade (KettleView.murk): clear water, the
## blended mash, the boiling wort.
const WATER_MURK : float = 0.3
const MASH_MURK : float = 0.85
const BOIL_MURK : float = 0.6
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
## Steam: a faint haze over a hot mash, wisps as the wort nears the boil, thick
## steam at a rolling boil and thicker as the foam rises.
const MASH_STEAM : float = 0.12
const NEAR_BOIL_STEAM : float = 0.3
const BOIL_STEAM : float = 0.35
const FOAM_STEAM : float = 0.3

enum Stage { MASH, MASH_DONE, BOIL, RESULT }

var _plan : BrewDayPlan
var _mash : MashSession
var _boil : BoilSession
var _stage : Stage = Stage.MASH
var _multiplier : float = BrewDayRules.NORMAL_MULTIPLIER
var _button_heat : bool = false
var _key_heat : bool = false
var _sack_ids : Array[int] = []
var _sack_buttons : Array[HopSackButton] = []
## Spice sacks already tipped in during this carry.
var _spice_tipped : Dictionary = {}
## Marks whose opening has been called out.
var _called : Dictionary = {}
var _malts_added : bool = false
## Share of the malt sack still to pour, 1..0.
var _malt_left : float = 1.0
var _malt_sound_played : bool = false
var _foam_warned : bool = false
var _flameout_shown : bool = false
var _malt_aroma_shown : bool = false
var _water_line_shown : bool = false
var _in_band_line_wait : float = 0.0

var _header : Label
var _hint : Label
var _kettle : KettleView
var _thermo : ThermoColumn
var _heat_button : HeatButton
var _malts_button : HopSackButton
var _next_button : Button
var _cancel_button : Button
var _quick_button : Button
var _sack_column : VBoxContainer
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
	if brewery.machine_active(CellarMachines.AUTO_KETTLE):
		GUISignals.brew_day_finished.emit(BrewDayRules.AUTO_KETTLE_MULTIPLIER)
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
	_kettle.clear_pours()
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
	_malt_left = 1.0
	_malt_sound_played = false
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
	_kettle.murk = WATER_MURK
	_kettle.foam = 0.0
	_kettle.bubbling = false
	_kettle.reset_paddle()
	_malts_button.fill = 1.0
	_malts_button.lifted = false
	_refresh_malt_amount()
	_malts_button.show()
	_next_button.hide()
	_sack_column.hide()
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
	_called.clear()
	_boil.hop_stand_started.connect(func() -> void: _heat_button.disabled = true)
	_header.text = tr(BOIL_HEADER_TEXT) % tr(_plan.style_name)
	_hint.text = BOIL_HINT_TEXT
	_hint.show()
	_thermo.mash = null
	_thermo.boil = _boil
	_thermo.piece_ids = _plan.piece_ids
	_kettle.clumps = []
	_kettle.liquid_color = BeerColor.from_ebc(_plan.ebc).lerp(GRAIN_COLOR, BOIL_CLOUD)
	_kettle.murk = BOIL_MURK
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
		if _malts_added:
			_kettle.liquid_color = KettleView.WATER_COLOR.lerp(_mash_color(), lerpf(POUR_CLOUD, 1.0, _mash.blend))
			_kettle.murk = lerpf(WATER_MURK, MASH_MURK, lerpf(POUR_CLOUD, 1.0, _mash.blend))
	elif _stage == Stage.BOIL:
		_boil.set_heating(heating)
		_boil.step(delta)
		_boil_lines()
	if _boil != null:
		_kettle.foam = _boil.foam
		_kettle.bubbling = _boil.is_boiling()
	_kettle.steam = _steam_level()
	var glow : Color = _thermo.current_needle_color()
	glow.a = GLOW_ALPHA
	_kettle.glow_color = glow if _stage != Stage.RESULT else Color.TRANSPARENT
	_heat_button.heat = _boil.heat.power if _boil != null else _mash.heat.power
	_heat_button.warmth = _kettle_warmth()
	_heat_button.held = _key_heat and _stage != Stage.RESULT
	_pour_malts(delta)
	_cue_malts()
	_refresh_sacks()
	_emit_loops()


func _kettle_warmth() -> float:
	var temperature : float = _boil.heat.temperature if _boil != null else _mash.heat.temperature
	var target : float = BoilSession.BOIL_MIN if _boil != null else _mash.target()
	return clampf((temperature - (target - WARM_SPAN)) / WARM_SPAN, 0.0, 1.0)


func _steam_level() -> float:
	if _boil == null:
		return MASH_STEAM * clampf((_mash.heat.temperature - 50.0) / 20.0, 0.0, 1.0)
	if _boil.is_boiling():
		return BOIL_STEAM + FOAM_STEAM * clampf(_boil.foam, 0.0, 1.0)
	var near : float = clampf((_boil.heat.temperature - (BoilSession.BOIL_MIN - 8.0)) / 8.0, 0.0, 1.0)
	return NEAR_BOIL_STEAM * near


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


## The malt sack blinks while the water is at the malt marker, like a hop sack at its mark.
func _cue_malts() -> void:
	if not _malts_button.visible:
		return
	var at_marker : bool = _stage == Stage.MASH and _mash.is_in_band() and not _kettle.is_carrying(MALT_SACK_ID)
	_malts_button.cue = HopSackButton.Cue.NOW if at_marker else HopSackButton.Cue.NONE
	_malts_button.cue_label = tr(MALT_CUE_TEXT)


## The carried malt sack pours while over the mouth, clouding the water a little as it
## goes; the malts go in when it is empty and then blend in (MashSession.blend).
func _pour_malts(delta : float) -> void:
	if not _kettle.is_carrying(MALT_SACK_ID):
		return
	_kettle.set_carry_target(MALT_SACK_ID, _kettle.get_local_mouse_position())
	var over : bool = _kettle.is_over_mouth(MALT_SACK_ID)
	_kettle.set_pouring(MALT_SACK_ID, over)
	if not over:
		return
	if not _malt_sound_played:
		_malt_sound_played = true
		GUISignals.brew_day_sound.emit(SOUND_MALTS)
	_malt_left = maxf(0.0, _malt_left - delta / MALT_POUR_SECONDS)
	_malts_button.fill = _malt_left
	_refresh_malt_amount()
	_kettle.liquid_color = KettleView.WATER_COLOR.lerp(_mash_color(), POUR_CLOUD * (1.0 - _malt_left))
	_kettle.murk = lerpf(WATER_MURK, MASH_MURK, POUR_CLOUD * (1.0 - _malt_left))
	if _malt_left <= 0.0:
		_add_malts()


func _pick_up_malts() -> void:
	if _stage == Stage.MASH and not _malts_added:
		_kettle.carry(MALT_SACK_ID, KettleView.CLUMP_LIGHT, true, false)
		_malts_button.lifted = true


func _put_down_malts() -> void:
	_kettle.drop(MALT_SACK_ID)
	_malts_button.lifted = false


func _refresh_malt_amount() -> void:
	_malts_button.amount_text = MALT_AMOUNT_FORMAT % [String.num(_plan.malt_kg * _malt_left, 1), tr(StringContainer.KG)]


func _mash_color() -> Color:
	return BeerColor.from_ebc(_plan.ebc).lerp(GRAIN_COLOR, MASH_CLOUD)


func _add_malts() -> void:
	_put_down_malts()
	_malts_added = true
	_mash.add_malts()
	_malts_button.hide()
	_hint.text = PADDLE_HINT_TEXT
	_hint.show()
	_popups.show_line(BrewDayLines.MALTS_IN_TEXT)


func _on_clump_appeared(_clump : MashClump) -> void:
	# The clumps of the dough-in itself come with the malts line.
	if _mash.is_blended():
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
	if mark.bittering_only and mark.result != BoilMark.Result.MISS:
		_popups.show_line(tr(BrewDayLines.NOT_AROMA_HOP_TEXT) % _sack_name(mark.ingredient_id), BrewDayPopups.BAD_COLOR)
		return
	var good : bool = mark.result == BoilMark.Result.FULL
	if good:
		GUISignals.brew_day_sound.emit(SOUND_MARK_HIT)
		_kettle.sparkle(_pellet_color(mark.ingredient_id))
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
		_put_down_malts()


func _on_sack_key(index : int, pressed : bool) -> void:
	if _boil == null or _stage != Stage.BOIL or index >= _sack_ids.size():
		return
	if pressed:
		_pick_up(_sack_ids[index], false)
	else:
		_put_down(_sack_ids[index])


## Lifts a sack off its place: with the pointer it follows it, with its key it hangs
## at its own spot over the mouth. It only pours while over the mouth.
func _pick_up(id : int, follow : bool) -> void:
	if _stage == Stage.BOIL and float(_boil.sacks.get(id, 0.0)) > 0.0:
		_kettle.carry(id, _pellet_color(id), follow)


func _put_down(id : int) -> void:
	if _boil != null:
		_boil.stop_pour(id)
	_kettle.drop(id)
	_spice_tipped.erase(id)


## A carried sack pours while its mouth is over the kettle mouth: a pour starts as it
## comes over (that is when its timing counts) and ends as it leaves. A spice sack
## tips its handful in once.
func _pour_from_carried(id : int, left : float) -> bool:
	if not _kettle.is_carrying(id):
		return false
	_kettle.set_carry_target(id, _kettle.get_local_mouse_position())
	var over : bool = _kettle.is_over_mouth(id) and left > 0.0
	if _plan.piece_ids.has(id):
		if over and not _spice_tipped.has(id):
			_spice_tipped[id] = true
			GUISignals.brew_day_sound.emit(SOUND_PLOP)
			_kettle.drop_handful(id, SPICE_HANDFUL)
			_boil.start_pour(id)
		return false
	if over and not _boil.is_pouring(id):
		GUISignals.brew_day_sound.emit(SOUND_PLOP)
		_boil.start_pour(id)
	elif not over and _boil.is_pouring(id):
		_boil.stop_pour(id)
	return over


## A sack's next open mark: wobbling while it is coming, blinking while it is open,
## and called out from the kettle the moment it opens.
func _cue_sack(button : HopSackButton, id : int) -> void:
	button.cue = HopSackButton.Cue.NONE
	if _stage != Stage.BOIL:
		return
	for mark : BoilMark in _boil.open_marks():
		if mark.ingredient_id != id:
			continue
		var start : float = BoilSchedule.window_start(mark.kind, _boil.window_widen)
		var open : bool = _boil.is_pouring_time() and BoilSchedule.in_window(mark.kind, _boil.counted, _boil.window_widen)
		# The bittering hops are coming as the wort nears the boil.
		var coming : bool = _boil.counted >= start - CUE_LEAD if _boil.is_pouring_time() \
			else mark.kind == HopAddition.Kind.BITTERING and _boil.heat.temperature >= BoilSession.BOIL_MIN - 3.0
		if not open and not coming:
			continue
		button.cue = HopSackButton.Cue.NOW if open else HopSackButton.Cue.SOON
		button.cue_label = ThermoColumn.kind_label(mark.kind)
		if open and not _called.has(mark):
			_called[mark] = true
			_popups.show_call(tr(CALL_TEXT) % [button.cue_label, _sack_name(id)], BrewDayPopups.GOOD_COLOR)
		return


## The ingredient's name without the "-humala" ending, as the sacks show it.
func _sack_name(id : int) -> String:
	return tr(String(_plan.names.get(id, ""))).get_slice("-", 0)


## A sack's pellets take the colour of its first mark; juniper is its own blue.
func _pellet_color(id : int) -> Color:
	if id == BrewDayLines.JUNIPER_ID:
		return JUNIPER_COLOR
	for mark : BoilMark in _plan.marks:
		if mark.ingredient_id == id:
			return PELLET_COLORS.get(mark.kind, PELLET_COLORS[HopAddition.Kind.FLAVOR])
	return PELLET_COLORS[HopAddition.Kind.FLAVOR]


func _set_sacks_released() -> void:
	for id : int in _sack_ids:
		_put_down(id)


func _build_sacks() -> void:
	for button : HopSackButton in _sack_buttons:
		button.queue_free()
	_sack_buttons.clear()
	_sack_ids = _plan.sack_ids()
	for i : int in _sack_ids.size():
		var id : int = _sack_ids[i]
		var button := HopSackButton.new()
		button.key_number = i + 1
		button.sack_name = _sack_name(id)
		button.pellet_color = _pellet_color(id)
		button.button_down.connect(_pick_up.bind(id, true))
		button.button_up.connect(_put_down.bind(id))
		_sack_column.add_child(button)
		_sack_buttons.append(button)
	_sack_column.show()
	_refresh_sacks()


## The sacks' fill and text, and the kettle's pours: a sack pours while it is held and
## still has something in it.
func _refresh_sacks() -> void:
	if _boil == null:
		return
	var totals : Dictionary = {}
	for mark : BoilMark in _plan.marks:
		totals[mark.ingredient_id] = int(totals.get(mark.ingredient_id, 0)) + mark.grams
	for i : int in _sack_buttons.size():
		var id : int = _sack_ids[i]
		var left : float = float(_boil.sacks.get(id, 0.0))
		var unit : String = StringContainer.KPL if _plan.piece_ids.has(id) else StringContainer.G
		var button : HopSackButton = _sack_buttons[i]
		button.amount_text = "%d %s" % [roundi(left), tr(unit)]
		button.fill = left / maxf(1.0, float(totals.get(id, 1)))
		_kettle.set_pouring(id, _pour_from_carried(id, left))
		button.lifted = _kettle.is_carrying(id)
		_cue_sack(button, id)
		if _stage == Stage.BOIL:
			button.disabled = left <= 0.0 and not _boil.is_pouring(id)


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

	_malts_button = HopSackButton.new()
	_malts_button.key_number = 0
	_malts_button.sack_name = tr(MALT_SACK_TEXT)
	_malts_button.pellet_color = KettleView.CLUMP_LIGHT
	_malts_button.position = SACK_COLUMN_POSITION
	_malts_button.button_down.connect(_pick_up_malts)
	_malts_button.button_up.connect(_put_down_malts)
	add_child(_malts_button)
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

	_sack_column = VBoxContainer.new()
	_sack_column.position = SACK_COLUMN_POSITION
	_sack_column.add_theme_constant_override("separation", SACK_GAP)
	add_child(_sack_column)

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
