class_name BrewDayArt
extends Resource

## The brew day's sprites, so swapping one means editing its PNG in
## assets/textures/brew_day/. Kettle shown 4x, props 2x; the moving, colour-changing
## parts stay drawn in code. Keep each sprite's size, or the parts placed on it shift.

const KETTLE_SCALE : int = 4
const PROP_SCALE : int = 2

## 70 x 71. The oval mouth must stay a transparent hole at (6, 11), 58 x 26: the
## liquid is drawn under it and shows through, its edge hidden under the rim.
@export var kettle : Texture2D
## 13 x 5: the blade along +x, its tip at the right end; drawn turned with the stick.
@export var paddle_blade : Texture2D
## 4 x 4: the knob at the handle end, centred on the stick's end.
@export var paddle_grip : Texture2D
## Three frames side by side, 19 x 20 each: full, half and almost empty. The code
## paints the pellets' colour into the neck (HopSackButton.NECK_TOPS).
@export var sack : Texture2D
## 20 x 20, already tilted over the kettle; pellets fall from its mouth at (13, 16).
@export var sack_lifted : Texture2D
## Two square frames side by side, 13 x 13 each: a whole clump and one that has been hit.
@export var clump : Texture2D
## The steam over the mouth, pixel-strict (assets/shaders/brew_steam.gdshader).
@export var steam_shader : Shader
