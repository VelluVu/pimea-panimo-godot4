class_name BrewDayCommentary
extends RefCounted

## Picks the brew day's popup lines (BrewDayLines) from what the sessions report, and keeps
## one-off lines from repeating.

signal line_said(text : String, color : Color)
## A mark's big opening call, shown larger than a line.
signal call_said(text : String, color : Color)

const FOAM_WARNING_FROM : float = 0.7
## Further than this over the band, a hot mash gets the harsher lines.
const FAR_TOO_HOT : float = 6.0
const IN_BAND_LINE_GAP : float = 5.0
## Chance a second of steady holding gets an in-band line.
const IN_BAND_LINE_RATE : float = 0.25
const MALT_AROMA_AFTER : float = 2.5
## The big call when a mark opens: the mark and the hop, e.g. "AROMI: Citra!".
const CALL_TEXT : String = "%s: %s!"

var _rng : RandomNumberGenerator
var _water_line_said : bool = false
var _malt_aroma_said : bool = false
var _foam_warned : bool = false
var _flameout_said : bool = false
var _in_band_wait : float = 0.0
## Marks whose opening has been called out.
var _called : Dictionary = {}


func _init(rng : RandomNumberGenerator = null) -> void:
	_rng = rng if rng != null else RandomNumberGenerator.new()


func reset() -> void:
	_water_line_said = false
	_malt_aroma_said = false
	_foam_warned = false
	_flameout_said = false
	_in_band_wait = 0.0
	_called.clear()


## The first heating of the day, before the malts, gets a word about the water.
func heating_started(before_malts : bool) -> void:
	if before_malts and not _water_line_said:
		_water_line_said = true
		_say(BrewDayLines.pick(BrewDayLines.WATER_HEATING))


func malts_added() -> void:
	_say(BrewDayLines.MALTS_IN_TEXT)


func mash_tick(mash : MashSession, delta : float, heating : bool, malts_in : bool) -> void:
	_in_band_wait -= delta
	if malts_in and not _malt_aroma_said and mash.counted >= MALT_AROMA_AFTER:
		_malt_aroma_said = true
		_say(BrewDayLines.MALT_AROMA_TEXT)
	elif mash.is_counting() and mash.is_in_band() and not heating and _in_band_wait <= 0.0 \
			and _rng.randf() < delta * IN_BAND_LINE_RATE:
		_in_band_wait = IN_BAND_LINE_GAP
		_say(BrewDayLines.pick(BrewDayLines.IN_BAND), BrewDayPopups.GOOD_COLOR)


## The dough-in's own clumps come with the malts line; only later ones are called out.
func clump_appeared(mash : MashSession) -> void:
	if mash.is_blended():
		_say(BrewDayLines.CLUMP_TEXT, BrewDayPopups.BAD_COLOR)


func clump_broken() -> void:
	_say(BrewDayLines.CLUMP_BROKEN_TEXT, BrewDayPopups.GOOD_COLOR)


func band_left(mash : MashSession, too_hot : bool) -> void:
	if not too_hot:
		_say(BrewDayLines.TOO_COLD_TEXT, BrewDayPopups.BAD_COLOR)
	elif mash.heat.temperature > mash.target() + mash.band + FAR_TOO_HOT:
		_say(BrewDayLines.pick(BrewDayLines.FAR_TOO_HOT), BrewDayPopups.BAD_COLOR)
	else:
		_say(BrewDayLines.TOO_HOT_TEXT, BrewDayPopups.BAD_COLOR)


## The last step needs no line of its own: the mash done line follows it.
func step_completed(mash : MashSession, index : int) -> void:
	if index < mash.steps.size() - 1:
		_say(BrewDayLines.STEP_DONE_TEXT, BrewDayPopups.GOOD_COLOR)


func mash_completed(mash : MashSession) -> void:
	_say(BrewDayLines.MASH_DONE_TEXT, BrewDayPopups.GOOD_COLOR)
	if mash.clumps_left() > 0:
		_say(BrewDayLines.CLUMPS_LEFT_TEXT, BrewDayPopups.BAD_COLOR)


func boil_started() -> void:
	_say(BrewDayLines.BOILING_TEXT, BrewDayPopups.GOOD_COLOR)


func boil_stopped() -> void:
	_say(BrewDayLines.BOIL_STOPPED_TEXT, BrewDayPopups.BAD_COLOR)


func boiled_over() -> void:
	_say(BrewDayLines.pick(BrewDayLines.BOILED_OVER), BrewDayPopups.BAD_COLOR)


func stray_pour() -> void:
	_say(BrewDayLines.STRAY_POUR_TEXT, BrewDayPopups.BAD_COLOR)


## The foam warning rearms once the foam has settled to half its threshold.
func boil_tick(boil : BoilSession) -> void:
	if boil.foam >= FOAM_WARNING_FROM and not _foam_warned:
		_foam_warned = true
		_say(BrewDayLines.FOAM_WARNING_TEXT, BrewDayPopups.BAD_COLOR)
	elif boil.foam < FOAM_WARNING_FROM * 0.5:
		_foam_warned = false
	if not _flameout_said and boil.counted >= BoilSchedule.BOIL_SECONDS:
		_flameout_said = true
		_say(BrewDayLines.FLAMEOUT_TEXT)


## Calls out a mark the moment it opens, once.
func mark_opened(mark : BoilMark, kind_label : String, sack_name : String) -> void:
	if _called.has(mark):
		return
	_called[mark] = true
	call_said.emit(UiText.of(CALL_TEXT) % [kind_label, sack_name], BrewDayPopups.GOOD_COLOR)


func mark_resolved(mark : BoilMark, sack_name : String) -> void:
	if mark.bittering_only and mark.result != BoilMark.Result.MISS:
		_say(UiText.of(BrewDayLines.NOT_AROMA_HOP_TEXT) % sack_name, BrewDayPopups.BAD_COLOR)
		return
	var good : bool = mark.result == BoilMark.Result.FULL
	_say(BrewDayLines.mark_line(mark), BrewDayPopups.GOOD_COLOR if good else BrewDayPopups.BAD_COLOR)


func result(multiplier : float) -> void:
	var good : bool = multiplier >= BrewDayRules.NORMAL_MULTIPLIER
	_say(BrewDayLines.result_line(multiplier), BrewDayPopups.GOOD_COLOR if good else BrewDayPopups.BAD_COLOR)


func _say(text : String, color : Color = BrewDayPopups.PLAIN_COLOR) -> void:
	line_said.emit(text, color)
