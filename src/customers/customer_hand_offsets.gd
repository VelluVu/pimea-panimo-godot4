class_name CustomerHandOffsets
extends RefCounted

## Per-frame hand position for the held glass on ANIM_WALK_TOWARDS, Customer-local. The walk
## plays flipped, so the defaults mirror the steady right hand (screen_x = 64 - 4*tx) nudged
## 9 px in. Archetypes without a steady hand get their own table.

const DEFAULT_OFFSETS : Array[Vector2] = [
	Vector2(-23, -46),
	Vector2(-7, -46),
	Vector2(-23, -46),
	Vector2(-25, -50),
]

## Zgen's arms stay crossed, so a small hand-authored sway at chest height.
const ZGEN_TITLE : String = "Gen Z"
const ZGEN_OFFSETS : Array[Vector2] = [
	Vector2(-4, -68),
	Vector2(0, -66),
	Vector2(4, -68),
	Vector2(0, -66),
]

## Raksamies swings both arms: tracked from their left hand, hip height on frames 0/2, by
## the belt on 1, swinging out on 3.
const RAKSAMIES_TITLE : String = "Raksamies"
const RAKSAMIES_OFFSETS : Array[Vector2] = [
	Vector2(-30, -46),
	Vector2(-4, -51),
	Vector2(-30, -44),
	Vector2(-28, -58),
]

## Leijonafani fist-pumps: hip height on frames 0/2, up on 1, partway down on 3, so the
## glass punches the air.
const LEIJONAFANI_TITLE : String = "Leijonafani"
const LEIJONAFANI_OFFSETS : Array[Vector2] = [
	Vector2(-30, -50),
	Vector2(-46, -66),
	Vector2(-30, -50),
	Vector2(-22, -58),
]

## Kriitikko's notebook is in the tracked hand, so the glass rides steady at the other hip
## (a pixel higher on frames 1 and 3).
const KRIITIKKO_TITLE : String = "Kriitikko"
const KRIITIKKO_OFFSETS : Array[Vector2] = [
	Vector2(35, -44),
	Vector2(35, -48),
	Vector2(35, -44),
	Vector2(35, -48),
]


## Munkki walks with hands pressed together in prayer, so the glass sits between them,
## a texel higher on the frames where the hands rise.
const MUNKKI_TITLE : String = "Munkki"
const MUNKKI_OFFSETS : Array[Vector2] = [
	Vector2(0, -66),
	Vector2(0, -70),
	Vector2(0, -66),
	Vector2(0, -70),
]

## Kurpitsapää's praying hands stay put while the pumpkin bobs.
const KURPITSAPAA_TITLE : String = "Kurpitsapää"
const KURPITSAPAA_OFFSETS : Array[Vector2] = [
	Vector2(0, -66),
]


## The drone flies off with the glass under its belly, bobbing a pixel per frame.
const DRONE_TITLE : String = "Tarkastusdrooni"
const DRONE_OFFSETS : Array[Vector2] = [
	Vector2(3, -45),
	Vector2(3, -49),
	Vector2(3, -41),
]


## Tarjoushaukka stuffs the glass into a shopping bag with the rest of the loot: only its
## top rows show, the cut edge in the bag's opening (one texel higher on frame 3, where
## the bag rises with the step).
const TARJOUSHAUKKA_TITLE : String = "Tarjoushaukka"
const TARJOUSHAUKKA_OFFSETS : Array[Vector2] = [
	Vector2(-28, -46),
	Vector2(-28, -46),
	Vector2(-28, -46),
	Vector2(-28, -50),
]
const BAGGED_GLASS_REGION : Rect2 = Rect2(0, 0, 8, 5)

## Kyborgi's hand rises with its hum on frame 1, and swings out and up on frame 3.
const KYBORGI_TITLE : String = "Kyborgi"
const KYBORGI_OFFSETS : Array[Vector2] = [
	Vector2(-28, -46),
	Vector2(-28, -50),
	Vector2(-28, -46),
	Vector2(-32, -54),
]


## Hand position for one walk_towards frame of the archetype with this title.
static func position_for(title: String, frame: int) -> Vector2:
	var offsets : Array[Vector2] = DEFAULT_OFFSETS
	match title:
		ZGEN_TITLE:
			offsets = ZGEN_OFFSETS
		RAKSAMIES_TITLE:
			offsets = RAKSAMIES_OFFSETS
		LEIJONAFANI_TITLE:
			offsets = LEIJONAFANI_OFFSETS
		DRONE_TITLE:
			offsets = DRONE_OFFSETS
		KRIITIKKO_TITLE:
			offsets = KRIITIKKO_OFFSETS
		MUNKKI_TITLE:
			offsets = MUNKKI_OFFSETS
		KURPITSAPAA_TITLE:
			offsets = KURPITSAPAA_OFFSETS
		TARJOUSHAUKKA_TITLE:
			offsets = TARJOUSHAUKKA_OFFSETS
		KYBORGI_TITLE:
			offsets = KYBORGI_OFFSETS
	return offsets[frame % offsets.size()]


## The part of the held glass that shows, in glass texels; an empty Rect2 shows all of it.
static func glass_region_for(title: String) -> Rect2:
	return BAGGED_GLASS_REGION if title == TARJOUSHAUKKA_TITLE else Rect2()
