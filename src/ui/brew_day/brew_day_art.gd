class_name BrewDayArt
extends Resource

## The brew day's sprites, so swapping one is a matter of editing its PNG in
## assets/textures/brew_day/ (or reassigning it here). The liquid, foam, bubbles, hop
## blooms, stripes, pellets and the bent shaft stay drawn in code, since they move and
## change colour. Keep each sprite's size, or the parts the code places on it shift.

## 280 x 284. The oval mouth must stay a transparent hole at (24, 44), 232 x 104
## (KettleView.LIQUID_RECT): the code fills it with the liquid.
@export var kettle : Texture2D
## The blade along +x, its tip at the right end; drawn turned with the stick.
@export var paddle_blade : Texture2D
## The knob at the handle end, centred on the stick's end.
@export var paddle_grip : Texture2D
## Three frames side by side, 38 x 40 each: full, half and almost empty. The code
## paints the pellets' colour into the neck (HopSackButton.NECK_TOPS).
@export var sack : Texture2D
## 40 x 40, already tilted over the kettle; pellets fall from KettleView.LIFTED_SACK_MOUTH.
@export var sack_lifted : Texture2D
## Two square frames side by side: a whole clump and one that has been hit.
@export var clump : Texture2D
## The steam over the mouth, pixel-strict (assets/shaders/brew_steam.gdshader).
@export var steam_shader : Shader
