class_name BoilSchedule
extends RefCounted

## The boil's timeline in counted seconds; the clock stops whenever the boil does.

const BOIL_SECONDS : float = 10.0
const WINDOW_HALF : float = 0.75
## The bittering hops go in as the boil starts, with a longer window to react in.
const BITTERING_WINDOW : float = 1.5
## A pour this far outside its window still counts as a late or early try at it.
const NEAR_MISS : float = 1.5


static func time_for(kind : HopAddition.Kind) -> float:
	match kind:
		HopAddition.Kind.BITTERING: return 0.0
		HopAddition.Kind.FLAVOR: return 5.0
		HopAddition.Kind.SPICE: return 8.5
		HopAddition.Kind.AROMA: return BOIL_SECONDS
		_: return -1.0


static func is_in_boil(kind : HopAddition.Kind) -> bool:
	return kind != HopAddition.Kind.DRY_HOP


static func window_start(kind : HopAddition.Kind, widen : float = 0.0) -> float:
	if kind == HopAddition.Kind.BITTERING:
		return 0.0
	return time_for(kind) - WINDOW_HALF - widen


static func window_end(kind : HopAddition.Kind, widen : float = 0.0) -> float:
	if kind == HopAddition.Kind.BITTERING:
		return BITTERING_WINDOW + widen
	return time_for(kind) + WINDOW_HALF + widen


static func in_window(kind : HopAddition.Kind, at : float, widen : float = 0.0) -> bool:
	return at >= window_start(kind, widen) and at <= window_end(kind, widen)


## Pours are still taken until the flameout window closes.
static func end_time() -> float:
	return BOIL_SECONDS + WINDOW_HALF
