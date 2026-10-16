class_name MaltSackButton
extends HopSackButton

## The mash's malt sack: carried and poured into the kettle like a hop sack, under an
## id no ingredient has. It blinks while the water is at the malt marker; the malts
## count as added once it is empty.

signal emptied()

const SACK_ID : int = -1
const NAME_TEXT : String = "Maltaat"
const AMOUNT_FORMAT : String = "%s %s"
## Shown on the sack while the water is at the malt marker.
const CUE_TEXT : String = "NYT"
## Seconds of pouring to empty the sack.
const POUR_SECONDS : float = 2.0

## Set by the window before the first mash.
var kettle : KettleView
## Whether the sack may be lifted now; the window allows it only during the mash.
var can_lift : bool = false

var _malt_kg : float = 0.0
## Share of the sack still to pour, 1..0.
var _left : float = 1.0
var _sound_played : bool = false


func _ready() -> void:
	super()
	key_number = 0
	sack_name = tr(NAME_TEXT)
	pellet_color = KettleView.CLUMP_LIGHT
	button_down.connect(_pick_up)
	button_up.connect(put_down)


func reset(malt_kg : float) -> void:
	_malt_kg = malt_kg
	_left = 1.0
	_sound_played = false
	fill = 1.0
	lifted = false
	_refresh_amount()
	show()


## Share of the sack poured so far, 0..1.
func poured() -> float:
	return 1.0 - _left


## Pours while carried over the mouth, and cues while the water is ready for it.
func step(delta : float, at_marker : bool) -> void:
	if not visible:
		return
	var carried : bool = kettle.is_carrying(SACK_ID)
	cue = Cue.NOW if at_marker and not carried else Cue.NONE
	cue_label = tr(CUE_TEXT) if cue == Cue.NOW else ""
	if carried:
		_pour(delta)


func put_down() -> void:
	kettle.drop(SACK_ID)
	lifted = false


func _pick_up() -> void:
	if can_lift and _left > 0.0:
		kettle.carry(SACK_ID, KettleView.CLUMP_LIGHT, true, false)
		lifted = true


func _pour(delta : float) -> void:
	kettle.set_carry_target(SACK_ID, kettle.get_local_mouse_position())
	var over : bool = kettle.is_over_mouth(SACK_ID)
	kettle.set_pouring(SACK_ID, over)
	if not over:
		return
	if not _sound_played:
		_sound_played = true
		BrewDaySound.play(BrewDaySound.MALTS)
	_left = maxf(0.0, _left - delta / POUR_SECONDS)
	fill = _left
	_refresh_amount()
	if _left <= 0.0:
		put_down()
		hide()
		emptied.emit()


func _refresh_amount() -> void:
	amount_text = AMOUNT_FORMAT % [String.num(_malt_kg * _left, 1), tr(StringContainer.KG)]
