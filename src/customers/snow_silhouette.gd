class_name SnowSilhouette
extends RefCounted

## Where snow settles on a sprite frame: the top opaque pixel of each column, which is a
## head, a hat or the shoulders. A column whose top is far below the highest one (a hand held
## out, a stepping foot) holds none. -1 marks a column without snow.

const ALPHA_THRESHOLD : float = 0.5
## From the head's top down to the shoulders, in art pixels, with room for a tall hat.
const MAX_DROP_ROWS : int = 14

## Frame textures already read, by instance id: reading a texture's image is slow.
static var _cache : Dictionary[int, PackedInt32Array] = {}


static func top_edge_of(texture : Texture2D) -> PackedInt32Array:
	var id : int = texture.get_instance_id()
	if not _cache.has(id):
		var image : Image = texture.get_image()
		_cache[id] = top_edge(image) if image != null else PackedInt32Array()
	return _cache[id]


static func top_edge(image : Image) -> PackedInt32Array:
	var tops := PackedInt32Array()
	tops.resize(image.get_width())
	var highest : int = image.get_height()
	for x in image.get_width():
		tops[x] = -1
		for y in image.get_height():
			if image.get_pixel(x, y).a >= ALPHA_THRESHOLD:
				tops[x] = y
				highest = mini(highest, y)
				break
	for x in tops.size():
		if tops[x] > highest + MAX_DROP_ROWS:
			tops[x] = -1
	return tops
