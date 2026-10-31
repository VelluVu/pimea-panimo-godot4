class_name DayLights
extends Node

## The night between days: when the day changes the lamps click off one by one and the
## cellar stays dark while the day recap is open; closing it lights them again in reverse,
## the last one off coming back first with a stutter. Lamps step, never fade, like the art.

const OFF_GAP_SECONDS : float = 0.22
const ON_GAP_SECONDS : float = 0.18
const STUTTER_SECONDS : float = 0.07
## The lamps come back by themselves if no window closes, so the cellar never stays dark.
const MAX_NIGHT_SECONDS : float = 10.0
const NIGHT_DARKNESS : Color = Color(0.16, 0.15, 0.2)
## The day's darkness in the Halloween season: a touch more purple, so the pumpkins glow.
const HALLOWEEN_DARKNESS : Color = Color(0.4, 0.33, 0.5)
## In Black Month: colder and a little darker, so the neon sale signs stand out.
const BLACK_MONTH_DARKNESS : Color = Color(0.33, 0.35, 0.48)
## In Cyber Week: a cyan screen glow on top of Black Month's cold.
const CYBER_WEEK_DARKNESS : Color = Color(0.3, 0.4, 0.5)
## In Cyber Week the lamps glow neon, cyan and magenta in turn, a little soft so the faces
## under them stay readable; NeonPulse makes them pulse and drift slowly.
const CYBER_LAMP_COLORS : Array[Color] = [Color(0.45, 0.95, 1.0), Color(1.0, 0.45, 0.9)]

@export_node_path("CanvasModulate") var darkness_path : NodePath

## The LightFlicker lamps beside this node, switched off in tree order.
var lamps : Array[LightFlicker] = []
var darkness : CanvasModulate
var _day_darkness : Color
## The scene's own darkness, for days outside every season.
var _plain_darkness : Color
## Each lamp's own colour, given back when Cyber Week ends.
var _lamp_colors : Dictionary[LightFlicker, Color] = {}
var _neon : bool = false
var _neon_time : float = 0.0
var _night : bool = false
var _sequence : Tween


func _ready() -> void:
	# The recap may pause the tree; the lamps must still switch.
	process_mode = Node.PROCESS_MODE_ALWAYS
	darkness = get_node(darkness_path) as CanvasModulate
	_plain_darkness = darkness.color
	for node : Node in get_parent().find_children("*", "PointLight2D"):
		var lamp : LightFlicker = node as LightFlicker
		if lamp != null:
			lamps.append(lamp)
			_lamp_colors[lamp] = lamp.color
	_set_season(SeasonRules.now())
	TimeManager.day_changed.connect(_on_day_changed.unbind(1))
	GUISignals.window_closed.connect(_light_up)
	BrewerySignals.season_forced.connect(_set_season)


## Keeps the night dark when the season changes mid-night; the lamps bring the new day tint.
func _set_season(season : SeasonRules.Season) -> void:
	match season:
		SeasonRules.Season.HALLOWEEN:
			_day_darkness = HALLOWEEN_DARKNESS
		SeasonRules.Season.BLACK_MONTH:
			_day_darkness = BLACK_MONTH_DARKNESS
		SeasonRules.Season.CYBER_WEEK:
			_day_darkness = CYBER_WEEK_DARKNESS
		_:
			_day_darkness = _plain_darkness
	if not _night:
		darkness.color = _day_darkness
	_neon = season == SeasonRules.Season.CYBER_WEEK
	if not _neon:
		for lamp : LightFlicker in lamps:
			lamp.color = _lamp_colors[lamp]
			lamp.pulse = 1.0


func _process(delta : float) -> void:
	if not _neon:
		return
	_neon_time += delta
	for index : int in lamps.size():
		lamps[index].color = NeonPulse.color(_neon_time, index, CYBER_LAMP_COLORS)
		lamps[index].pulse = NeonPulse.brightness(_neon_time, index)


func _on_day_changed() -> void:
	_night = true
	_restart_sequence()
	for lamp : LightFlicker in lamps:
		_sequence.tween_callback(_switch.bind(lamp, 0.0))
		_sequence.tween_interval(OFF_GAP_SECONDS)
	_sequence.tween_callback(_set_darkness.bind(NIGHT_DARKNESS))
	get_tree().create_timer(MAX_NIGHT_SECONDS, true).timeout.connect(_light_up)


func _light_up() -> void:
	if not _night:
		return
	_night = false
	_restart_sequence()
	_sequence.tween_callback(_set_darkness.bind(_day_darkness))
	for i : int in range(lamps.size() - 1, -1, -1):
		var lamp : LightFlicker = lamps[i]
		if i == lamps.size() - 1:
			_sequence.tween_callback(_switch.bind(lamp, 1.0))
			_sequence.tween_interval(STUTTER_SECONDS)
			_sequence.tween_callback(_switch.bind(lamp, 0.0))
			_sequence.tween_interval(STUTTER_SECONDS)
		_sequence.tween_callback(_switch.bind(lamp, 1.0))
		_sequence.tween_interval(ON_GAP_SECONDS)


func _restart_sequence() -> void:
	if _sequence != null:
		_sequence.kill()
	_sequence = create_tween()


func _switch(lamp : LightFlicker, dimmer : float) -> void:
	lamp.dimmer = dimmer


func _set_darkness(color : Color) -> void:
	darkness.color = color
