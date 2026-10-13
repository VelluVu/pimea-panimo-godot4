class_name KegWashRules
extends RefCounted

## The keg wash's numbers: what each kind of dirt takes, how a wash is scored and what a
## dirty keg holds. Dirt is scrubbed loose with the brush, then rinsed away with the hose;
## the hat and the coconut come out whole, and flies and bees flee from the brush.

## Brush stroke (pixels) that scrubs each kind loose; the hat pops out at once.
const WORK : Dictionary = {
	KegWashSpot.Kind.YEAST: 90.0,
	KegWashSpot.Kind.GUM: 240.0,
	KegWashSpot.Kind.SALMIAKKI: 70.0,
	KegWashSpot.Kind.HAT: 1.0,
	KegWashSpot.Kind.COCONUT: 160.0,
}
## Salmiakki only gives way to a fast stroke, pixels a second.
const SALMIAKKI_MIN_SPEED : float = 260.0
## The hat needs a touch that moves at all.
const MIN_SCRUB_SPEED : float = 40.0
## These come out whole, with nothing left to rinse.
const POPS_OUT : Array[KegWashSpot.Kind] = [KegWashSpot.Kind.HAT, KegWashSpot.Kind.COCONUT]
const CRITTERS : Array[KegWashSpot.Kind] = [KegWashSpot.Kind.FLIES, KegWashSpot.Kind.BEES]
## Bees buzz around a while before they leave.
const FLEE_SECONDS : Dictionary = {KegWashSpot.Kind.FLIES: 0.3, KegWashSpot.Kind.BEES: 1.2}

const BRUSH_RADIUS : float = 20.0
const SPOT_RADIUS : float = 12.0
## Critters flee when the scrubbing brush comes this close.
const FLEE_RADIUS : float = 48.0
const HOSE_RADIUS : float = 26.0
const RINSE_SECONDS : float = 0.3
## A tool works whenever it is over the keg, so a wrong move only counts once it lingers.
const MISTAKE_DWELL : float = 0.5
const SPRAY_RADIUS : float = 40.0
## Coverage a sprayed cell gains a second.
const SPRAY_RATE : float = 5.0
const COVERAGE_CELL : float = 16.0
## Coverage that counts as the whole keg.
const FULL_COVERAGE : float = 0.97

## Grime: a film over the whole inside, with thicker coloured stains on it, that only
## the hose takes off, so the hose has to go all over the keg. Kept in cells this size.
const STAIN_CELL : float = 8.0
const FILM_AMOUNT : float = 0.5
const FILM_COLOR : Color = Color(0.36, 0.31, 0.24)
## Grime a hosed cell loses a second, and the hose's reach on it.
const STAIN_RINSE_RATE : float = 5.0
const STAIN_HOSE_RADIUS : float = 34.0
## A cell this faint counts as clean.
const STAIN_CLEAN_BELOW : float = 0.05
## Grime left at or under this share counts as rinsed: the last specks by the rim wash off
## with it, so nobody has to hunt for them.
const GRIME_DONE_SHARE : float = 0.03
const MIN_STAINS : int = 2
const MAX_STAINS : int = 4
## Stain sizes across, in pixels; the tilted keg squashes them to the opening's shape.
const STAIN_SIZE_MIN : float = 30.0
const STAIN_SIZE_MAX : float = 70.0
## Old beer, hop slime, yeast.
const STAIN_COLORS : Array[Color] = [Color(0.47, 0.31, 0.12), Color(0.35, 0.47, 0.16), Color(0.75, 0.66, 0.31)]

## Shares of the cleanliness: dirt scrubbed loose, dirt and stains rinsed away, inside
## sanitized.
const SCRUB_SHARE : float = 0.6
const RINSE_SHARE : float = 0.2
const SPRAY_SHARE : float = 0.2

const MIN_SPOTS : int = 3
const MAX_SPOTS : int = 5
## How often each kind turns up; the hat and the coconut at most once a keg.
const WEIGHTS : Dictionary = {
	KegWashSpot.Kind.YEAST: 5.0,
	KegWashSpot.Kind.GUM: 2.0,
	KegWashSpot.Kind.SALMIAKKI: 2.0,
	KegWashSpot.Kind.FLIES: 2.0,
	KegWashSpot.Kind.BEES: 1.0,
	KegWashSpot.Kind.HAT: 0.5,
	KegWashSpot.Kind.COCONUT: 0.5,
}
const ONCE_PER_KEG : Array[KegWashSpot.Kind] = [KegWashSpot.Kind.HAT, KegWashSpot.Kind.COCONUT]
## Spots keep at least this far apart.
const MIN_SPOT_GAP : float = 40.0
const PLACEMENT_TRIES : int = 30


static func is_critter(kind : KegWashSpot.Kind) -> bool:
	return CRITTERS.has(kind)


static func pops_out(kind : KegWashSpot.Kind) -> bool:
	return POPS_OUT.has(kind)


## Stroke that counts toward scrubbing `kind` loose, from a stroke of `length` pixels
## at `speed` pixels a second.
static func scrub_work(kind : KegWashSpot.Kind, length : float, speed : float) -> float:
	if speed < MIN_SCRUB_SPEED:
		return 0.0
	if kind == KegWashSpot.Kind.SALMIAKKI and speed < SALMIAKKI_MIN_SPEED:
		return 0.0
	return length


static func cleanliness(scrubbed : float, gone : float, coverage : float) -> float:
	return clampf(SCRUB_SHARE * scrubbed + RINSE_SHARE * gone + SPRAY_SHARE * coverage, 0.0, 1.0)


## The stains in one dirty keg, anywhere inside the opening.
static func roll_stains(rng : RandomNumberGenerator) -> Array[KegWashStain]:
	var stains : Array[KegWashStain] = []
	var squash : float = KegTunnel.OPENING_RADII.y / KegTunnel.OPENING_RADII.x
	for i : int in rng.randi_range(MIN_STAINS, MAX_STAINS):
		var at : Vector2 = KegTunnel.point_at(rng.randf() * TAU, sqrt(rng.randf()) * KegTunnel.SPOT_REACH)
		var size : float = rng.randf_range(STAIN_SIZE_MIN, STAIN_SIZE_MAX)
		stains.append(KegWashStain.new(at, Vector2(size, size * squash), STAIN_COLORS[rng.randi() % STAIN_COLORS.size()]))
	return stains


## The things in one dirty keg, placed apart inside the opening.
static func roll_spots(rng : RandomNumberGenerator) -> Array[KegWashSpot]:
	var spots : Array[KegWashSpot] = []
	var used : Array[KegWashSpot.Kind] = []
	for i : int in rng.randi_range(MIN_SPOTS, MAX_SPOTS):
		var kind : KegWashSpot.Kind = _roll_kind(rng, used)
		used.append(kind)
		spots.append(KegWashSpot.new(kind, _free_point(rng, spots)))
	return spots


static func _roll_kind(rng : RandomNumberGenerator, used : Array[KegWashSpot.Kind]) -> KegWashSpot.Kind:
	var total : float = 0.0
	for kind : KegWashSpot.Kind in WEIGHTS:
		if not (ONCE_PER_KEG.has(kind) and used.has(kind)):
			total += WEIGHTS[kind]
	var roll : float = rng.randf() * total
	for kind : KegWashSpot.Kind in WEIGHTS:
		if ONCE_PER_KEG.has(kind) and used.has(kind):
			continue
		roll -= WEIGHTS[kind]
		if roll <= 0.0:
			return kind
	return KegWashSpot.Kind.YEAST


static func _free_point(rng : RandomNumberGenerator, placed : Array[KegWashSpot]) -> Vector2:
	var point : Vector2 = KegTunnel.OPENING_CENTER
	for attempt : int in PLACEMENT_TRIES:
		point = KegTunnel.point_at(rng.randf() * TAU, sqrt(rng.randf()) * KegTunnel.SPOT_REACH)
		var clear : bool = true
		for spot : KegWashSpot in placed:
			if spot.position.distance_to(point) < MIN_SPOT_GAP:
				clear = false
				break
		if clear:
			break
	return point
