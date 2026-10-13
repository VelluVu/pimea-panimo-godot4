class_name KegTunnel
extends RefCounted

## The opened keg as the wash window shows it: tilted toward the player, so its opening
## is a wide ellipse and the far bottom a small one inside it. In window pixels, matching
## keg_tunnel.png drawn at KegWashArt.TUNNEL_SCALE.

const OPENING_CENTER : Vector2 = Vector2(320, 202)
const OPENING_RADII : Vector2 = Vector2(164, 104)
const BOTTOM_CENTER : Vector2 = Vector2(320, 174)
const BOTTOM_RADII : Vector2 = Vector2(68, 44)
## Dirt keeps this far inside the opening, clear of the rim.
const SPOT_REACH : float = 0.8


## 0 at the opening's centre, 1 on its edge, more outside it.
static func reach(point : Vector2) -> float:
	return ((point - OPENING_CENTER) / OPENING_RADII).length()


static func is_inside(point : Vector2) -> bool:
	return reach(point) <= 1.0


## How deep in the keg a point is: 1 on the far bottom, 0 at the rim.
static func depth(point : Vector2) -> float:
	var on_bottom : float = ((point - BOTTOM_CENTER) / BOTTOM_RADII).length()
	return clampf(1.0 - (on_bottom - 1.0) / 1.4, 0.0, 1.0)


## A point inside the opening, `share` (0 to 1) of the way from the centre to the edge
## in the direction `angle`.
static func point_at(angle : float, share : float) -> Vector2:
	return OPENING_CENTER + Vector2(cos(angle), sin(angle)) * OPENING_RADII * share
