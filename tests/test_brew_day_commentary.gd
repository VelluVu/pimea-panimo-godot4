@tool
extends McpTestSuite

## Unit tests for BrewDayCommentary: which brew day lines are said, and only once.

const CommentaryScript := preload("res://src/ui/brew_day/brew_day_commentary.gd")
const MashSessionScript := preload("res://src/brewing/brew_day/mash_session.gd")
const BoilSessionScript := preload("res://src/brewing/brew_day/boil_session.gd")
const BoilMarkScript := preload("res://src/brewing/brew_day/boil_mark.gd")

var _lines : Array[String] = []
var _calls : Array[String] = []


func suite_name() -> String:
	return "brew_day_commentary"


func _commentary() -> BrewDayCommentary:
	_lines.clear()
	_calls.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var commentary : BrewDayCommentary = CommentaryScript.new(rng)
	commentary.line_said.connect(func(text : String, _color : Color) -> void: _lines.append(text))
	commentary.call_said.connect(func(text : String, _color : Color) -> void: _calls.append(text))
	return commentary


func _mash() -> MashSession:
	var temperatures : Array[float] = [64.0, 72.0]
	return MashSessionScript.new(temperatures, 2.0, 0.35, 0)


func _boil() -> BoilSession:
	var marks : Array[BoilMark] = []
	return BoilSessionScript.new(marks)


func test_the_water_line_comes_once_and_only_before_the_malts() -> void:
	var commentary := _commentary()
	commentary.heating_started(false)
	assert_eq(_lines.size(), 0)
	commentary.heating_started(true)
	commentary.heating_started(true)
	assert_eq(_lines.size(), 1)
	commentary.reset()
	commentary.heating_started(true)
	assert_eq(_lines.size(), 2, "a new brew day says it again")


func test_the_foam_warning_rearms_once_the_foam_settles() -> void:
	var commentary := _commentary()
	var boil := _boil()
	boil.foam = BrewDayCommentary.FOAM_WARNING_FROM
	commentary.boil_tick(boil)
	commentary.boil_tick(boil)
	assert_eq(_lines.count(BrewDayLines.FOAM_WARNING_TEXT), 1)
	boil.foam = BrewDayCommentary.FOAM_WARNING_FROM * 0.6
	commentary.boil_tick(boil)
	boil.foam = BrewDayCommentary.FOAM_WARNING_FROM
	commentary.boil_tick(boil)
	assert_eq(_lines.count(BrewDayLines.FOAM_WARNING_TEXT), 1, "not settled enough to rearm")
	boil.foam = 0.0
	commentary.boil_tick(boil)
	boil.foam = BrewDayCommentary.FOAM_WARNING_FROM
	commentary.boil_tick(boil)
	assert_eq(_lines.count(BrewDayLines.FOAM_WARNING_TEXT), 2)


func test_flameout_is_said_once_when_the_boil_time_is_up() -> void:
	var commentary := _commentary()
	var boil := _boil()
	commentary.boil_tick(boil)
	assert_false(_lines.has(BrewDayLines.FLAMEOUT_TEXT))
	boil.counted = BoilSchedule.BOIL_SECONDS
	commentary.boil_tick(boil)
	commentary.boil_tick(boil)
	assert_eq(_lines.count(BrewDayLines.FLAMEOUT_TEXT), 1)


func test_the_last_mash_step_leaves_its_line_to_the_mash_done_line() -> void:
	var commentary := _commentary()
	var mash := _mash()
	commentary.step_completed(mash, 0)
	commentary.step_completed(mash, 1)
	assert_eq(_lines, [BrewDayLines.STEP_DONE_TEXT] as Array[String])


func test_leaving_the_band_hot_or_far_too_hot_or_cold() -> void:
	var commentary := _commentary()
	var mash := _mash()
	commentary.band_left(mash, false)
	assert_eq(_lines[-1], BrewDayLines.TOO_COLD_TEXT)
	mash.heat.temperature = mash.target() + mash.band + 1.0
	commentary.band_left(mash, true)
	assert_eq(_lines[-1], BrewDayLines.TOO_HOT_TEXT)
	mash.heat.temperature = mash.target() + mash.band + BrewDayCommentary.FAR_TOO_HOT + 1.0
	commentary.band_left(mash, true)
	assert_true(BrewDayLines.FAR_TOO_HOT.has(_lines[-1]))


func test_a_mark_is_called_out_once() -> void:
	var commentary := _commentary()
	var mark : BoilMark = BoilMarkScript.new()
	commentary.mark_opened(mark, "AROMI", "Citra")
	commentary.mark_opened(mark, "AROMI", "Citra")
	assert_eq(_calls, ["AROMI: Citra!"] as Array[String])


func test_an_aroma_hop_on_a_bittering_only_mark_is_named() -> void:
	var commentary := _commentary()
	var mark : BoilMark = BoilMarkScript.new()
	mark.bittering_only = true
	mark.result = BoilMark.Result.FULL
	commentary.mark_resolved(mark, "Magnum")
	assert_eq(_lines, [BrewDayLines.NOT_AROMA_HOP_TEXT % "Magnum"] as Array[String])
