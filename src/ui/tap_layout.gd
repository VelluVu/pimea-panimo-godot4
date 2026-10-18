class_name TapLayout
extends RefCounted

## Where the tap tower's parts go: a crossbar growing a handle pitch per tap, centred. Past
## the counter's room the pitch tightens, so twelve taps fit.

## One tap per keg the brewery owns but the spares, see KegRules.tap_count().
const MAX_TAPS : int = 12
const CAP_WIDTH : int = 5
const HANDLE_WIDTH : int = 5
const HANDLE_PITCH : int = 12
## The widest crossbar before the PC: six taps at full pitch, twelve 8 px apart.
const MAX_BAR_WIDTH : int = 103
## The drip tray reaches at least this far past the crossbar on each side.
const TRAY_OVERHANG : int = 2
## The tray's pattern repeats every 3 px. A width one past a multiple of it ends on the
## same stud column it starts with, so both ends look alike.
const TRAY_PATTERN : int = 3


## Taps drawn for `kegs` owned; never fewer than one.
static func tap_count(kegs : int) -> int:
	return clampi(kegs, 1, MAX_TAPS)


## Handle spacing for `taps`: the full pitch while it fits, tighter after.
static func pitch(taps : int) -> int:
	if taps <= 1:
		return HANDLE_PITCH
	@warning_ignore("integer_division")
	var fitting : int = (MAX_BAR_WIDTH - 2 * CAP_WIDTH - HANDLE_WIDTH) / (taps - 1)
	return mini(HANDLE_PITCH, fitting)


static func bar_width(taps : int) -> int:
	return 2 * CAP_WIDTH + pitch(taps) * (taps - 1) + HANDLE_WIDTH


## Whole pixels, so the pieces never round apart into a seam.
static func bar_left(taps : int) -> float:
	@warning_ignore("integer_division")
	return float(-(bar_width(taps) / 2))


static func handle_left(taps : int, index : int) -> float:
	return bar_left(taps) + CAP_WIDTH + pitch(taps) * index


static func tray_width(taps : int) -> int:
	var width : int = bar_width(taps) + 2 * TRAY_OVERHANG
	return width + posmod(1 - width, TRAY_PATTERN)


## The x of a tap's spout centre, where the glass goes under.
static func spout_x(taps : int, index : int) -> float:
	return handle_left(taps, index) + HANDLE_WIDTH / 2.0
