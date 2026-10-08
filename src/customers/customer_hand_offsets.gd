class_name CustomerHandOffsets
extends RefCounted

## Per-frame hand position for the held beer glass during ANIM_WALK_TOWARDS
## (Customer-local space, matching AnimatedSprite2D's centered=false/
## offset=(-16,-32)/scale=4 transform). That animation is always played with
## flip_h=true, so the customer's own RIGHT hand, which stays steady at hip
## height across the 4 frames of a plain walk cycle, ends up screen-left. The
## default x values are that steady hand's texture position run through the
## same mirror flip_h applies (screen_x = 64 - 4*tx), plus a +9 nudge toward
## center so the glass doesn't float off the body. Archetypes whose walk pose
## doesn't fit the "one steady hand" assumption get a dedicated table below.

const DEFAULT_OFFSETS : Array[Vector2] = [
	Vector2(-23, -46),
	Vector2(-7, -46),
	Vector2(-23, -46),
	Vector2(-25, -50),
]

## Zgen keeps both arms crossed at the chest the whole cycle (no swinging hand
## to track), so this is a small hand-authored sway around chest height.
const ZGEN_TITLE : String = "Gen Z"
const ZGEN_OFFSETS : Array[Vector2] = [
	Vector2(-4, -68),
	Vector2(0, -66),
	Vector2(4, -68),
	Vector2(0, -66),
]

## Raksamies (and raksamies_naaras, same title) swing BOTH arms. Tracked from
## the customer's own left hand: hip height on frames 0/2, tucked near the
## belt on frame 1 while the other arm swings out, swinging out on frame 3.
const RAKSAMIES_TITLE : String = "Raksamies"
const RAKSAMIES_OFFSETS : Array[Vector2] = [
	Vector2(-30, -46),
	Vector2(-4, -51),
	Vector2(-30, -44),
	Vector2(-28, -58),
]

## Leijonafani (and leijonafani_naaras, same title) throws one arm into a
## raised fist-pump: hip height on frames 0/2, all the way up on frame 1,
## partway back down on frame 3, so the held glass punches the air with him.
const LEIJONAFANI_TITLE : String = "Leijonafani"
const LEIJONAFANI_OFFSETS : Array[Vector2] = [
	Vector2(-30, -50),
	Vector2(-46, -66),
	Vector2(-30, -50),
	Vector2(-22, -58),
]

## Kriitikko carries his notebook in the hand the default table tracks, so the glass
## goes in the other one, steady at the hip (one pixel higher on frames 1 and 3).
const KRIITIKKO_TITLE : String = "Kriitikko"
const KRIITIKKO_OFFSETS : Array[Vector2] = [
	Vector2(35, -44),
	Vector2(35, -48),
	Vector2(35, -44),
	Vector2(35, -48),
]


## Tarkastusdrooni flies off with the glass hanging just under its belly. The
## body bobs a pixel per frame (bottom rows 17, 16, 18), and the glass follows.
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
