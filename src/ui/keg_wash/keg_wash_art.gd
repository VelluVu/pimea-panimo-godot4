class_name KegWashArt
extends Resource

## The keg wash's sprites, so swapping one is a matter of editing its PNG in
## assets/textures/keg_wash/. Drawn small and shown scaled up like the game's other
## sprites: the keg 4x, everything else 2x. The water, mist, sparkles and the hose itself
## stay drawn in code. Keep each sprite's size, or the parts the code places on it shift.

const TUNNEL_SCALE : int = 4
const PROP_SCALE : int = 2

## 92 x 62, the opened keg seen from the front, tilted toward the player. Its opening and
## far bottom must stay where KegTunnel expects them (drawn at TUNNEL_SCALE from
## KegWashView.TUNNEL_POSITION).
@export var tunnel : Texture2D
## Eight 14 x 14 frames side by side, in KegWashSpot.Kind order (yeast, gum, salmiakki,
## hat, coconut, flies, bees), then a loose clump of scrubbed dirt.
@export var spots : Texture2D
## 12 x 34: hangs from the hook by the hole at its top, held by the shaft at BRUSH_GRIP_Y;
## the bristles at the bottom do the scrubbing around BRUSH_HEAD_Y (KegWashView).
@export var brush : Texture2D
## 8 x 16, the spraying tip at the top centre; the hose joins the bottom (NOZZLE_GRIP).
@export var nozzle : Texture2D
## 14 x 20, the mist leaves from the nozzle at (1, 4) (SPRAY_NOZZLE).
@export var spray : Texture2D
## 14 x 12, the hose leaves from the spout at (7, 11) (TAP_SPOUT).
@export var tap : Texture2D
## 8 x 8, the brush hangs from it.
@export var hook : Texture2D
## 52 x 10, the spray bottle stands on it.
@export var bench : Texture2D
