class_name TapLayout
extends RefCounted

## Where the tap tower's parts go for a number of taps (TapTower draws them): a
## crossbar that grows by one handle pitch per tap, centred on the tower's origin.
## Pixel sizes are the tap art's, see assets/textures/tap/.

const MAX_TAPS : int = 6
const CAP_WIDTH : int = 5
const HANDLE_WIDTH : int = 5
const HANDLE_PITCH : int = 12
## The drip tray reaches this far past the crossbar on each side.
const TRAY_OVERHANG : int = 2


## Taps drawn for `batches_on_serve`; an empty bar still shows one, unused.
static func tap_count(batches_on_serve : int) -> int:
	return clampi(batches_on_serve, 1, MAX_TAPS)


static func bar_width(taps : int) -> int:
	return 2 * CAP_WIDTH + HANDLE_PITCH * (taps - 1) + HANDLE_WIDTH


static func bar_left(taps : int) -> float:
	return -bar_width(taps) / 2.0


static func handle_left(taps : int, index : int) -> float:
	return bar_left(taps) + CAP_WIDTH + HANDLE_PITCH * index


## The x of a tap's spout centre, where the glass goes under.
static func spout_x(taps : int, index : int) -> float:
	return handle_left(taps, index) + HANDLE_WIDTH / 2.0


static func tray_width(taps : int) -> int:
	return bar_width(taps) + 2 * TRAY_OVERHANG
