class_name SpecialEventPacing
extends RefCounted

## How long until the next special event. It can shorten as LVV risk climbs, but
## MAX_RISK_SPEEDUP is 0: with it, risk-lowering events crowded out the rest for good
## players (bot playtests, 2026-10-09). The risk weighting alone favours them now.

const BASE_INTERVAL_SECONDS: float = 300.0
## At the raid threshold the wait is this much shorter.
const MAX_RISK_SPEEDUP: float = 0.0


## `risk_fraction` is risk as a share of the raid threshold, 0 to 1.
static func interval(risk_fraction: float) -> float:
	return BASE_INTERVAL_SECONDS * (1.0 - MAX_RISK_SPEEDUP * clampf(risk_fraction, 0.0, 1.0))
