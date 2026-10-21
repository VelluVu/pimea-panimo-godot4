class_name RiskPressure
extends RefCounted

## How hard the LVV risk presses on the screen, 0 to 1: nothing until the risk reaches
## START_SHARE of the raid threshold, full at the threshold. Eased, so it creeps in.

const START_SHARE : float = 0.45


static func of(risk : int, threshold : int) -> float:
	if threshold <= 0:
		return 0.0
	return smoothstep(START_SHARE, 1.0, float(risk) / float(threshold))
