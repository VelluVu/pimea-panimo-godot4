class_name MenuBackdrop
extends CanvasLayer

## The main menu's cellar after closing time: dark, only the bar's pendant glowing low, and
## the saved run's taps, kegs and brew waiting. Starting a run switches the lamps on one by
## one (lights_on), so entering the game is a moment and the menu stays calm behind its buttons.

## How much darker than the lit cellar's own tint (season colours included) the night is.
const AFTER_HOURS_DARKEN : float = 0.6
## The pendant's dimmer at night; every other lamp in Lights is off.
const PENDANT_NIGHT_DIMMER : float = 0.7
## Lamps step on like DayLights', never fade, to suit the pixel art.
const ON_GAP_SECONDS : float = 0.14
const STUTTER_SECONDS : float = 0.07
## The lit room shows for a moment before the fade takes it.
const LIT_HOLD_SECONDS : float = 0.35

@onready var tap_tower : TapTower = $WorldYSort/BarTable/BarTable_Sprite2D/TapTower
@onready var keg_row : KegRow = $WorldYSort/KegRow
@onready var fermenting_effect : FermentingTankEffect = $BreweryHoverArea/Sprite2D/FermentingTankEffect
@onready var world_darkness : CanvasModulate = $WorldDarkness
@onready var pendant_light : LightFlicker = $Lights/PendantLamp/Light_BarCone
@onready var lamps_root : Node2D = $Lights

## The cellar's lit tint, as DayLights set it for the season.
var _lit_darkness : Color
## The lamps switched off for the night, in tree order.
var _night_lamps : Array[LightFlicker] = []
var _lit : bool = false


## A 2D light reaches every canvas layer by default, which lit the menu and its windows
## above this one. Children are ready first, so DayLights has already set the season tint.
func _ready() -> void:
	for light : Node in find_children("*", "Light2D", true, false):
		(light as Light2D).range_layer_min = layer
		(light as Light2D).range_layer_max = layer
	_close_for_the_night()


## `brewery` is the saved run (SaveManager.peek()); null leaves the cellar as drawn.
func show_save(brewery : Brewery) -> void:
	if brewery == null:
		return
	BarTaps.show(brewery, tap_tower, keg_row)
	fermenting_effect.set_fermenting(not brewery.inventory.fermenting.is_empty())


## Switches the cellar on lamp by lamp; await it before leaving the menu.
func lights_on() -> void:
	if _lit:
		return
	_lit = true
	var sequence : Tween = create_tween()
	sequence.tween_callback(_set_darkness.bind(_lit_darkness))
	sequence.tween_callback(_set_dimmer.bind(pendant_light, 1.0))
	for i : int in _night_lamps.size():
		var lamp : LightFlicker = _night_lamps[i]
		sequence.tween_interval(ON_GAP_SECONDS)
		if i == 0:
			sequence.tween_callback(_set_dimmer.bind(lamp, 1.0))
			sequence.tween_interval(STUTTER_SECONDS)
			sequence.tween_callback(_set_dimmer.bind(lamp, 0.0))
			sequence.tween_interval(STUTTER_SECONDS)
		sequence.tween_callback(_set_dimmer.bind(lamp, 1.0))
	sequence.tween_interval(LIT_HOLD_SECONDS)
	await sequence.finished


## Season decor (pumpkins, neon) keeps its own glow: it is what makes the dark room seasonal.
func _close_for_the_night() -> void:
	_lit_darkness = world_darkness.color
	world_darkness.color = _lit_darkness.darkened(AFTER_HOURS_DARKEN)
	for node : Node in lamps_root.find_children("*", "PointLight2D", true, false):
		var lamp : LightFlicker = node as LightFlicker
		if lamp == null or lamp == pendant_light:
			continue
		lamp.dimmer = 0.0
		_night_lamps.append(lamp)
	pendant_light.dimmer = PENDANT_NIGHT_DIMMER


func _set_darkness(color : Color) -> void:
	world_darkness.color = color


func _set_dimmer(lamp : LightFlicker, dimmer : float) -> void:
	lamp.dimmer = dimmer
