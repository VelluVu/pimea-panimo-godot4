class_name SpecialEventPacing
extends RefCounted

## How long until the next special event. MAX_RISK_SPEEDUP is 0: with it, risk-lowering
## events crowded out the rest (bot playtests, 2026-10-09); the risk weighting is enough.

const BASE_INTERVAL_SECONDS: float = 300.0 * DayPace.SCALE
## At the raid threshold the wait is this much shorter.
const MAX_RISK_SPEEDUP: float = 0.0


## `risk_fraction` is risk as a share of the raid threshold, 0 to 1.
static func interval(risk_fraction: float) -> float:
	return BASE_INTERVAL_SECONDS * (1.0 - MAX_RISK_SPEEDUP * clampf(risk_fraction, 0.0, 1.0))
