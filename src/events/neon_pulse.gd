class_name NeonPulse
extends RefCounted

## The Cyber Week lamps: each glows one of the neon colours, slowly brightening and dimming
## and drifting a little towards the next colour. Lamps run out of step, so the cellar
## never pulses as one.

const PULSE_PERIOD_SECONDS : float = 6.0
## The dimmest point of a pulse is this much below full.
const PULSE_DEPTH : float = 0.3
const DRIFT_PERIOD_SECONDS : float = 11.0
## How far a lamp's colour drifts towards the next neon colour at most.
const MAX_DRIFT : float = 0.35
## Each lamp starts this far into the cycle after the previous one.
const PHASE_STEP : float = 0.37


## From 1 - PULSE_DEPTH to 1.
static func brightness(time : float, index : int) -> float:
	var wave : float = 0.5 - 0.5 * cos(TAU * (time / PULSE_PERIOD_SECONDS + index * PHASE_STEP))
	return 1.0 - PULSE_DEPTH * wave


static func color(time : float, index : int, colors : Array[Color]) -> Color:
	var own : Color = colors[index % colors.size()]
	var next : Color = colors[(index + 1) % colors.size()]
	var wave : float = 0.5 + 0.5 * sin(TAU * (time / DRIFT_PERIOD_SECONDS + index * PHASE_STEP))
	return own.lerp(next, wave * MAX_DRIFT)
