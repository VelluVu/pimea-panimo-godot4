class_name HopSackColumn
extends VBoxContainer

## The boil's sacks in a column, one per mark. A sack lifts with the pointer or its number
## key and pours while over the kettle mouth. The window drives it each frame.

## A mark opened: its kind ("AROMI") and the sack's name, for the window's big call.
signal mark_opened(mark : BoilMark, kind_label : String, sack_name : String)

const GAP : int = 6
## Pellets in a tapped-in handful of spice.
const SPICE_HANDFUL : int = 12
## A sack starts wobbling this long before its mark opens.
const CUE_LEAD : float = 1.5
## The bittering sacks start wobbling this close to the boil.
const BITTERING_CUE_DEGREES : float = 3.0

## Set by the window before the first boil.
var kettle : KettleView

var _plan : BrewDayPlan
var _boil : BoilSession
var _active : bool = false
var _buttons : Array[HopSackButton] = []
## Spice sacks already tipped in during this carry.
var _spice_tipped : Dictionary = {}


func _ready() -> void:
	add_theme_constant_override("separation", GAP)


## Fills the column with the boil's sacks, keyed 1, 2, ... in the order of their marks.
func start(plan : BrewDayPlan, boil : BoilSession) -> void:
	_plan = plan
	_boil = boil
	_active = true
	for button : HopSackButton in _buttons:
		button.queue_free()
	_buttons.clear()
	for sack : int in boil.marks.size():
		var mark : BoilMark = boil.marks[sack]
		var button := HopSackButton.new()
		button.key_number = sack + 1
		button.sack_name = sack_name(mark.ingredient_id)
		button.pellet_color = BrewDayLook.pellet_color(mark)
		button.cue_label = ThermoColumn.kind_label(mark.kind)
		button.button_down.connect(_pick_up.bind(sack, true))
		button.button_up.connect(_put_down.bind(sack))
		add_child(button)
		_buttons.append(button)
	show()
	refresh()


## Back to the mash: no boil, no sacks.
func clear() -> void:
	release_all()
	_boil = null
	_active = false
	hide()


## The boil is over: the sacks stay as they are but can no longer be picked up.
func finish() -> void:
	_active = false
	for button : HopSackButton in _buttons:
		button.disabled = true


func release_all() -> void:
	for sack : int in _buttons.size():
		_put_down(sack)


## A number key lifts its sack straight over the mouth; letting go puts it down.
func press_key(index : int, pressed : bool) -> void:
	if not _active or index >= _buttons.size():
		return
	if pressed:
		_pick_up(index, false)
	else:
		_put_down(index)


func is_pouring() -> bool:
	return _boil != null and _boil.sacks.keys().any(func(sack : int) -> bool: return _boil.is_pouring(sack))


## The ingredient's name as its sacks show it.
func sack_name(ingredient_id : int) -> String:
	return BrewDayLook.sack_name(String(_plan.names.get(ingredient_id, "")))


## The sacks' fill and text, and the kettle's pours: a sack pours while it is held and
## still has something in it.
func refresh() -> void:
	if _boil == null:
		return
	for sack : int in _buttons.size():
		var mark : BoilMark = _boil.marks[sack]
		var left : float = float(_boil.sacks.get(sack, 0.0))
		var unit : String = StringContainer.KPL if _is_pieces(sack) else StringContainer.G
		var button : HopSackButton = _buttons[sack]
		button.amount_text = "%d %s" % [roundi(left), tr(unit)]
		button.fill = left / maxf(1.0, float(mark.grams))
		kettle.set_pouring(sack, _pour_from_carried(sack, left))
		button.lifted = kettle.is_carrying(sack)
		_cue(button, mark)
		if _active:
			button.disabled = left <= 0.0 and not _boil.is_pouring(sack)


## With the pointer the sack follows it; with its key it hangs at its own spot over the
## mouth. It pours only while over the mouth.
func _pick_up(sack : int, follow : bool) -> void:
	if _active and float(_boil.sacks.get(sack, 0.0)) > 0.0:
		kettle.carry(sack, BrewDayLook.pellet_color(_boil.marks[sack]), follow)


func _put_down(sack : int) -> void:
	if _boil != null:
		_boil.stop_pour(sack)
	kettle.drop(sack)
	_spice_tipped.erase(sack)


func _is_pieces(sack : int) -> bool:
	return _plan.piece_ids.has(_boil.marks[sack].ingredient_id)


## A carried sack pours while over the mouth: the pour starts as it comes over (timing
## counts then) and ends as it leaves. A spice sack tips its handful once.
func _pour_from_carried(sack : int, left : float) -> bool:
	if not kettle.is_carrying(sack):
		return false
	kettle.set_carry_target(sack, kettle.get_local_mouse_position())
	var over : bool = kettle.is_over_mouth(sack) and left > 0.0
	if _is_pieces(sack):
		if over and not _spice_tipped.has(sack):
			_spice_tipped[sack] = true
			BrewDaySound.play(BrewDaySound.PLOP)
			kettle.drop_handful(sack, SPICE_HANDFUL)
			_boil.start_pour(sack)
		return false
	if over and not _boil.is_pouring(sack):
		BrewDaySound.play(BrewDaySound.PLOP)
		_boil.start_pour(sack)
	elif not over and _boil.is_pouring(sack):
		_boil.stop_pour(sack)
	return over


## A sack's mark: wobbling while it is coming, blinking while it is open, and reported
## the moment it opens.
func _cue(button : HopSackButton, mark : BoilMark) -> void:
	button.cue = HopSackButton.Cue.NONE
	if not _active or not mark.is_open():
		return
	var start : float = BoilSchedule.window_start(mark.kind, _boil.window_widen)
	var open : bool = _boil.is_pouring_time() and BoilSchedule.in_window(mark.kind, _boil.counted, _boil.window_widen)
	# The bittering hops are coming as the wort nears the boil.
	var coming : bool = _boil.counted >= start - CUE_LEAD if _boil.is_pouring_time() \
		else mark.kind == HopAddition.Kind.BITTERING and _boil.heat.temperature >= BoilSession.BOIL_MIN - BITTERING_CUE_DEGREES
	if not open and not coming:
		return
	button.cue = HopSackButton.Cue.NOW if open else HopSackButton.Cue.SOON
	if open:
		mark_opened.emit(mark, button.cue_label, sack_name(mark.ingredient_id))
