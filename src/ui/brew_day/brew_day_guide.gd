class_name BrewDayGuide
extends RefCounted

## Aatu on a guided brew day: says the step (BrewDayGuideRules) and frames the control it
## is about. The window works out the step; this knows what each step points at.

var _box : GuideSpeechBox
var _pointer : NextStepPointer
var _on : bool = false

var _heat_button : Control
var _malt_sack : Control
var _kettle : Control
var _thermo : Control
var _sacks : HopSackColumn
var _next_button : Control


## The box and the pointer are the window's children: the box draws under its confirmation
## and the pointer over everything.
func _init(box : GuideSpeechBox, pointer : NextStepPointer) -> void:
	_box = box
	_pointer = pointer


func set_targets(heat_button : Control, malt_sack : Control, kettle : Control, thermo : Control, sacks : HopSackColumn, next_button : Control) -> void:
	_heat_button = heat_button
	_malt_sack = malt_sack
	_kettle = kettle
	_thermo = thermo
	_sacks = sacks
	_next_button = next_button


func is_on() -> bool:
	return _on


func begin(on : bool) -> void:
	_on = on
	_box.visible = on


func end() -> void:
	_on = false
	_box.hide()
	clear_pointer()


func clear_pointer() -> void:
	_pointer.point_at(null, NextStepPointer.Style.FRAME)


func show_step(step : BrewDayGuideRules.Step) -> void:
	if not _on:
		return
	_box.say(BrewDayGuideText.of(step))
	match step:
		BrewDayGuideRules.Step.HEAT_WATER, BrewDayGuideRules.Step.HEAT_BOIL:
			_pointer.point_at(_heat_button, NextStepPointer.Style.FRAME)
		BrewDayGuideRules.Step.POUR_MALTS:
			_pointer.point_at(_malt_sack, NextStepPointer.Style.FRAME)
		BrewDayGuideRules.Step.BREAK_CLUMPS:
			_pointer.point_at(_kettle, NextStepPointer.Style.FRAME, 0.0, KettleView.LIQUID_RECT)
		BrewDayGuideRules.Step.COOL_WATER, BrewDayGuideRules.Step.HOLD_MASH, BrewDayGuideRules.Step.KEEP_BOILING, BrewDayGuideRules.Step.WATCH_FOAM:
			_pointer.point_at(_thermo, NextStepPointer.Style.FRAME, 0.0, ThermoColumn.BAR_RECT)
		BrewDayGuideRules.Step.ADD_HOPS:
			_pointer.point_at(_sacks.cued_sack(), NextStepPointer.Style.FRAME)
		BrewDayGuideRules.Step.TO_BOIL, BrewDayGuideRules.Step.FINISH:
			_pointer.point_at(_next_button, NextStepPointer.Style.FRAME)
		_:
			clear_pointer()
