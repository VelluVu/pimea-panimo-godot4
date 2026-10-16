class_name HopSackColumn
extends VBoxContainer

## The boil's hop and spice sacks in a column beside the kettle. A sack lifts with the
## pointer or its number key and pours while carried over the kettle mouth; it cues its
## next mark (wobbling as it comes, blinking while open). The window drives it each frame.

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
var _ids : Array[int] = []
var _buttons : Array[HopSackButton] = []
## Grams (or pieces) each sack starts with.
var _totals : Dictionary = {}
## Spice sacks already tipped in during this carry.
var _spice_tipped : Dictionary = {}


func _ready() -> void:
	add_theme_constant_override("separation", GAP)


## Fills the column with the boil's sacks, keyed 1, 2, ... in the plan's order.
func start(plan : BrewDayPlan, boil : BoilSession) -> void:
	_plan = plan
	_boil = boil
	_active = true
	for button : HopSackButton in _buttons:
		button.queue_free()
	_buttons.clear()
	_ids = plan.sack_ids()
	_totals.clear()
	for mark : BoilMark in plan.marks:
		_totals[mark.ingredient_id] = int(_totals.get(mark.ingredient_id, 0)) + mark.grams
	for i : int in _ids.size():
		var id : int = _ids[i]
		var button := HopSackButton.new()
		button.key_number = i + 1
		button.sack_name = sack_name(id)
		button.pellet_color = pellet_color(id)
		button.button_down.connect(_pick_up.bind(id, true))
		button.button_up.connect(_put_down.bind(id))
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
	for id : int in _ids:
		_put_down(id)


## A number key lifts its sack straight over the mouth; letting go puts it down.
func press_key(index : int, pressed : bool) -> void:
	if not _active or index >= _ids.size():
		return
	if pressed:
		_pick_up(_ids[index], false)
	else:
		_put_down(_ids[index])


func is_pouring() -> bool:
	return _boil != null and _ids.any(func(id : int) -> bool: return _boil.is_pouring(id))


func sack_name(id : int) -> String:
	return BrewDayLook.sack_name(String(_plan.names.get(id, "")))


func pellet_color(id : int) -> Color:
	return BrewDayLook.pellet_color(id, _plan.marks)


## The sacks' fill and text, and the kettle's pours: a sack pours while it is held and
## still has something in it.
func refresh() -> void:
	if _boil == null:
		return
	for i : int in _buttons.size():
		var id : int = _ids[i]
		var left : float = float(_boil.sacks.get(id, 0.0))
		var unit : String = StringContainer.KPL if _plan.piece_ids.has(id) else StringContainer.G
		var button : HopSackButton = _buttons[i]
		button.amount_text = "%d %s" % [roundi(left), tr(unit)]
		button.fill = left / maxf(1.0, float(_totals.get(id, 1)))
		kettle.set_pouring(id, _pour_from_carried(id, left))
		button.lifted = kettle.is_carrying(id)
		_cue(button, id)
		if _active:
			button.disabled = left <= 0.0 and not _boil.is_pouring(id)


## Lifts a sack off its place: with the pointer it follows it, with its key it hangs
## at its own spot over the mouth. It only pours while over the mouth.
func _pick_up(id : int, follow : bool) -> void:
	if _active and float(_boil.sacks.get(id, 0.0)) > 0.0:
		kettle.carry(id, pellet_color(id), follow)


func _put_down(id : int) -> void:
	if _boil != null:
		_boil.stop_pour(id)
	kettle.drop(id)
	_spice_tipped.erase(id)


## A carried sack pours while its mouth is over the kettle mouth: a pour starts as it
## comes over (that is when its timing counts) and ends as it leaves. A spice sack
## tips its handful in once.
func _pour_from_carried(id : int, left : float) -> bool:
	if not kettle.is_carrying(id):
		return false
	kettle.set_carry_target(id, kettle.get_local_mouse_position())
	var over : bool = kettle.is_over_mouth(id) and left > 0.0
	if _plan.piece_ids.has(id):
		if over and not _spice_tipped.has(id):
			_spice_tipped[id] = true
			BrewDaySound.play(BrewDaySound.PLOP)
			kettle.drop_handful(id, SPICE_HANDFUL)
			_boil.start_pour(id)
		return false
	if over and not _boil.is_pouring(id):
		BrewDaySound.play(BrewDaySound.PLOP)
		_boil.start_pour(id)
	elif not over and _boil.is_pouring(id):
		_boil.stop_pour(id)
	return over


## A sack's next open mark: wobbling while it is coming, blinking while it is open,
## and reported the moment it opens.
func _cue(button : HopSackButton, id : int) -> void:
	button.cue = HopSackButton.Cue.NONE
	if not _active:
		return
	for mark : BoilMark in _boil.open_marks():
		if mark.ingredient_id != id:
			continue
		var start : float = BoilSchedule.window_start(mark.kind, _boil.window_widen)
		var open : bool = _boil.is_pouring_time() and BoilSchedule.in_window(mark.kind, _boil.counted, _boil.window_widen)
		# The bittering hops are coming as the wort nears the boil.
		var coming : bool = _boil.counted >= start - CUE_LEAD if _boil.is_pouring_time() \
			else mark.kind == HopAddition.Kind.BITTERING and _boil.heat.temperature >= BoilSession.BOIL_MIN - BITTERING_CUE_DEGREES
		if not open and not coming:
			continue
		button.cue = HopSackButton.Cue.NOW if open else HopSackButton.Cue.SOON
		button.cue_label = ThermoColumn.kind_label(mark.kind)
		if open:
			mark_opened.emit(mark, button.cue_label, sack_name(id))
		return
