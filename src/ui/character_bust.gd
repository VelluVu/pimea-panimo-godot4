class_name CharacterBust
extends RefCounted

## Head-and-shoulders crop of a character frame, so a tall sprite reads as an icon.
## dev/tools/icons/make_achievement_icons.py crops the achievement busts the same way.

const DEFAULT_SIZE : int = 20


## A square of `size` from just above the head, centred on the figure. Returns `texture`
## as is when it has no readable pixels.
static func of(texture : Texture2D, size : int = DEFAULT_SIZE) -> Texture2D:
	if texture == null:
		return null
	var image : Image = texture.get_image()
	if image == null:
		return texture
	var region : Rect2i = bust_region(image.get_used_rect(), image.get_size(), size)
	if region.has_area():
		return ImageTexture.create_from_image(image.get_region(region))
	return texture


static func bust_region(used : Rect2i, image_size : Vector2i, size : int) -> Rect2i:
	if not used.has_area():
		return Rect2i()
	var center_x : int = used.position.x + used.size.x / 2
	var region := Rect2i(center_x - size / 2, used.position.y - 1, size, size)
	return region.intersection(Rect2i(Vector2i.ZERO, image_size))
