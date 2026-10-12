class_name KettleHeat
extends RefCounted

## The burner and the liquid's temperature. The burner follows the heat button with a
## lag, so heat keeps coming a moment after letting go, and the kettle loses heat all
## the time, so holding a temperature means pulsing the button.

const MIN_TEMPERATURE : float = 15.0

var temperature : float = 20.0
var power : float = 0.0
var heating : bool = false
var heat_rate : float = 4.0
var loss_rate : float = 0.3
var lag : float = 0.35


func _init(start : float, rate : float, loss : float, burner_lag : float) -> void:
	temperature = start
	heat_rate = rate
	loss_rate = loss
	lag = burner_lag


func step(delta : float) -> void:
	var target : float = 1.0 if heating else 0.0
	if lag <= 0.0:
		power = target
	else:
		power += (target - power) * minf(1.0, delta / lag)
	temperature = maxf(MIN_TEMPERATURE, temperature + (power * heat_rate - loss_rate) * delta)
