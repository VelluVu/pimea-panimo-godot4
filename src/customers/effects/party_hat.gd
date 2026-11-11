class_name PartyHat
extends RefCounted

## Seats a New Year's Eve party hat (party_hats.png, make_party_hats.py) on any customer's
## head without a table per sheet: it finds the head's top in the frame's own pixels, so
## it follows the walk's bob, a mirrored walk and every sheet size.

const SHEET : Texture2D = preload("res://assets/textures/new_year/party_hats.png")
const HAT_SIZE : Vector2i = Vector2i(6, 8)
const COLOURS : int = 4
## The hat's brim sinks this many rows into the hair, so it sits on the head.
const SINK_ROWS : int = 1
## Rows under the top whose opaque span sets the head's middle, so one tuft or an antenna
## does not pull the hat aside.
const HEAD_ROWS : int = 3

## Frame texture -> its head top (x middle, top row), worked out once per texture.
static var _tops : Dictionary[Texture2D, Vector2i] = {}


## A Sprite2D for a random colour, to add under the customer's AnimatedSprite2D.
static func make_sprite() -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = SHEET
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.region_enabled = true
	sprite.region_rect = Rect2(0, randi_range(0, COLOURS - 1) * HAT_SIZE.y, HAT_SIZE.x, HAT_SIZE.y)
	return sprite


## Where the hat goes in the customer sprite's own art pixels for `frame` (its texture
## drawn at `offset`). Mirrored, the head's middle flips with the frame.
static func position_for(frame : Texture2D, offset : Vector2, mirrored : bool) -> Vector2:
	if not _tops.has(frame):
		_tops[frame] = head_top(frame.get_image())
	var top : Vector2i = _tops[frame]
	var middle : int = top.x
	if mirrored:
		middle = frame.get_width() - middle
	@warning_ignore("integer_division")
	return offset + Vector2(middle - HAT_SIZE.x / 2, top.y - HAT_SIZE.y + SINK_ROWS)


## The head's top in `image`: x is the middle of the opaque span over the top HEAD_ROWS
## rows (measured between pixels, so a mirrored frame is width - x), y the first opaque row.
static func head_top(image : Image) -> Vector2i:
	var used : Rect2i = image.get_used_rect()
	if not used.has_area():
		@warning_ignore("integer_division")
		return Vector2i(image.get_width() / 2, 0)
	var left : int = used.end.x
	var right : int = used.position.x
	for y : int in range(used.position.y, mini(used.position.y + HEAD_ROWS, used.end.y)):
		for x : int in range(used.position.x, used.end.x):
			if image.get_pixel(x, y).a > 0.0:
				left = mini(left, x)
				right = maxi(right, x + 1)
	@warning_ignore("integer_division")
	return Vector2i((left + right) / 2, used.position.y)
