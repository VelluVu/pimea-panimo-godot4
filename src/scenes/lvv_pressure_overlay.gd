class_name LvvPressureOverlay
extends ColorRect

## Feeds lvv_pressure.gdshader: RiskPressure eased in over a moment, and the siren while
## a raid squad is in the cellar. Hidden when both are off, so a calm cellar costs nothing.

const PRESSURE_TWEEN_SECONDS : float = 1.5
const SIREN_FADE_SECONDS : float = 0.6
const VISIBLE_EPSILON : float = 0.001

var _pressure : float = 0.0
var _siren : float = 0.0
var _pressure_tween : Tween
var _siren_tween : Tween


func _ready() -> void:
	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)
	BrewerySignals.lvv_raid_triggered.connect(_fade_siren.bind(1.0).unbind(3))
	BrewerySignals.lvv_raid_recap_ready.connect(_fade_siren.bind(0.0).unbind(3))
	if BrewEngine.current_brewery != null:
		_set_pressure(RiskPressure.of(BrewEngine.current_brewery.risk, BrewEngine.current_brewery.get_effective_raid_threshold()))
	_refresh()


func _on_brewery_state_changed(brewery : Brewery) -> void:
	var target : float = RiskPressure.of(brewery.risk, brewery.get_effective_raid_threshold())
	if is_equal_approx(target, _pressure):
		return
	if _pressure_tween != null:
		_pressure_tween.kill()
	_pressure_tween = create_tween()
	_pressure_tween.tween_method(_set_pressure, _pressure, target, PRESSURE_TWEEN_SECONDS)


func _fade_siren(target : float) -> void:
	if _siren_tween != null:
		_siren_tween.kill()
	_siren_tween = create_tween()
	_siren_tween.tween_method(_set_siren, _siren, target, SIREN_FADE_SECONDS)


func _set_pressure(value : float) -> void:
	_pressure = value
	_refresh()


func _set_siren(value : float) -> void:
	_siren = value
	_refresh()


func _refresh() -> void:
	var shader_material : ShaderMaterial = material as ShaderMaterial
	shader_material.set_shader_parameter("pressure", _pressure)
	shader_material.set_shader_parameter("siren", _siren)
	visible = _pressure > VISIBLE_EPSILON or _siren > VISIBLE_EPSILON
