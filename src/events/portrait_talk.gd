class_name PortraitTalk
extends RefCounted

## A caller's words typed out with the mouth moving. A portrait sheet is two 48 px frames
## side by side: shut, then open.

const FRAME_SIZE : float = 48.0
## The same pace as Pate's speech box.
const CHARACTERS_PER_SECOND : float = 45.0
const CHARACTERS_PER_MOUTH_MOVE : int = 4
const BABBLE_SECONDS : float = 0.8


static func characters_shown(seconds : float, total : int) -> int:
	return mini(int(seconds * CHARACTERS_PER_SECOND), total)


## The mouth flaps while there is text to come and rests shut once it is all out.
static func is_mouth_open(shown : int, total : int) -> bool:
	return shown < total and (shown / CHARACTERS_PER_MOUTH_MOVE) % 2 == 1


static func frame_region(mouth_open : bool) -> Rect2:
	return Rect2(FRAME_SIZE if mouth_open else 0.0, 0.0, FRAME_SIZE, FRAME_SIZE)
