class_name CustomerSway
extends RefCounted

## A strong or big round sways a customer on the way out, see TipsyRules. The offset moves a
## whole art pixel at a time, so body and hand step sideways together.

## How far the sway reaches, in art pixels; 0 walks straight.
var steps : int = 0
## The current sideways offset in screen pixels.
var x : float = 0.0

var _seconds : float = 0.0


## Advances the sway; true when `x` moved, so the sprite and hand need placing.
func tick(delta : float, art_pixel : float) -> bool:
	if steps <= 0:
		return false
	_seconds += delta
	var new_x : float = TipsyRules.sway_offset(_seconds, steps) * art_pixel
	if is_equal_approx(new_x, x):
		return false
	x = new_x
	return true
