class_name CustomerPortrait
extends RefCounted

## A customer's still for the customer book and unlock cards, recoloured on the CPU with
## the seeded palette. The toast cards only take a texture, so the shader can't do this.


## The first frame of `animation`, or null when the customer has none.
static func of(data: CustomerData, animation: StringName) -> Texture2D:
	if data.sprite_frames == null or not data.sprite_frames.has_animation(animation):
		return null
	var image : Image = data.sprite_frames.get_frame_texture(animation, 0).get_image()
	if image == null:
		return null
	recolor_image(image, CustomerPalette.seeded(data))
	return ImageTexture.create_from_image(image)


## What the shader's fragment() does, on an image whose frames are FRAME_HEIGHT tall.
static func recolor_image(image: Image, palette: Dictionary) -> void:
	if image.is_compressed():
		image.decompress()
	for y : int in image.get_height():
		var in_feet : bool = CustomerPalette.is_feet_row(y)
		for x : int in image.get_width():
			var pixel : Color = image.get_pixel(x, y)
			if pixel.a == 0.0:
				continue
			var region : String = CustomerPalette.claiming_region(pixel, palette, in_feet)
			if region != "" and palette[region]["recolor"]:
				var target : Color = palette[region]["target"]
				image.set_pixel(x, y, Color.from_hsv(target.h, target.s, pixel.v, pixel.a))
