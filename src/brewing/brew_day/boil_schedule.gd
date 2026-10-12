class_name BoilSchedule
extends RefCounted

## The boil's timeline in counted seconds; the clock stops whenever the boil does.
## After BOIL_SECONDS the flame goes out and a hop stand follows, as in a real brewery:
## the aroma hops go in then, with time to aim, and the clock no longer waits.

const BOIL_SECONDS : float = 15.0
const HOP_STAND_SECONDS : float = 3.0
## The flavour and spice marks as shares of the boil, so its length is one number.
const FLAVOR_AT : float = 0.5
const SPICE_AT : float = 0.85
const WINDOW_HALF : float = 0.75
## The bittering hops go in as the boil starts, with a longer window to react in.
const BITTERING_WINDOW : float = 1.5
## A pour this far outside its window still counts as a late or early try at it.
const NEAR_MISS : float = 1.5


static func time_for(kind : HopAddition.Kind) -> float:
	match kind:
		HopAddition.Kind.BITTERING: return 0.0
		HopAddition.Kind.FLAVOR: return BOIL_SECONDS * FLAVOR_AT
		HopAddition.Kind.SPICE: return BOIL_SECONDS * SPICE_AT
		HopAddition.Kind.AROMA: return BOIL_SECONDS
		_: return -1.0


static func is_in_boil(kind : HopAddition.Kind) -> bool:
	return kind != HopAddition.Kind.DRY_HOP


static func window_start(kind : HopAddition.Kind, widen : float = 0.0) -> float:
	if kind == HopAddition.Kind.BITTERING:
		return 0.0
	return time_for(kind) - WINDOW_HALF - widen


## The aroma window lasts the whole hop stand.
static func window_end(kind : HopAddition.Kind, widen : float = 0.0) -> float:
	if kind == HopAddition.Kind.BITTERING:
		return BITTERING_WINDOW + widen
	if kind == HopAddition.Kind.AROMA:
		return end_time()
	return time_for(kind) + WINDOW_HALF + widen


static func in_window(kind : HopAddition.Kind, at : float, widen : float = 0.0) -> bool:
	return at >= window_start(kind, widen) and at <= window_end(kind, widen)


## The brew day ends when the hop stand does.
static func end_time() -> float:
	return BOIL_SECONDS + HOP_STAND_SECONDS
