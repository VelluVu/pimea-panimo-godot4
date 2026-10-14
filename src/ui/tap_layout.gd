class_name TapLayout
extends RefCounted

## Where the tap tower's parts go for a number of taps (TapTower draws them): a
## crossbar that grows by one handle pitch per tap, centred on the tower's origin. Past
## the counter's room the pitch tightens instead, so twelve taps still fit. Pixel sizes
## are the tap art's, see assets/textures/tap/.

## One tap per keg the brewery owns: KegRules.START_KEGS plus the keg upgrade's levels.
const MAX_TAPS : int = 12
const CAP_WIDTH : int = 5
const HANDLE_WIDTH : int = 5
const HANDLE_PITCH : int = 12
## The widest crossbar the counter has room for before the PC beside it: six taps at
## the full pitch, twelve 8 px apart.
const MAX_BAR_WIDTH : int = 103
## The drip tray reaches at least this far past the crossbar on each side.
const TRAY_OVERHANG : int = 2
## The tray's studs repeat every 3 px. A width one past a multiple of it puts the last
## stud where the mirrored left end has its own, so both ends match.
const TRAY_STUD_PITCH : int = 3


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


static func bar_left(taps : int) -> float:
	return -bar_width(taps) / 2.0


static func handle_left(taps : int, index : int) -> float:
	return bar_left(taps) + CAP_WIDTH + pitch(taps) * index


## The x of a tap's spout centre, where the glass goes under.
static func spout_x(taps : int, index : int) -> float:
	return handle_left(taps, index) + HANDLE_WIDTH / 2.0


static func tray_width(taps : int) -> int:
	var width : int = bar_width(taps) + 2 * TRAY_OVERHANG
	return width + posmod(1 - width, TRAY_STUD_PITCH)
