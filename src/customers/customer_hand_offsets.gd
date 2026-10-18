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


## The drone flies off with the glass under its belly, bobbing a pixel per frame.
const DRONE_TITLE : String = "Tarkastusdrooni"
const DRONE_OFFSETS : Array[Vector2] = [
	Vector2(3, -45),
	Vector2(3, -49),
	Vector2(3, -41),
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
	return offsets[frame % offsets.size()]
