class_name MirroredAnimation
extends RefCounted

## Plays a sprite animation facing either way. Flipping the sprite writes any lettering
## backwards (Kriitikko's K), so a sheet can carry hand-fixed "<name>_mirrored" frames
## that are played instead; every other sheet is just flipped.

const SUFFIX : String = "_mirrored"


static func play(sprite : AnimatedSprite2D, anim_name : StringName, mirrored : bool) -> void:
	var frames : SpriteFrames = sprite.sprite_frames
	if frames == null:
		return
	var mirrored_name := StringName(String(anim_name) + SUFFIX)
	if mirrored and frames.has_animation(mirrored_name):
		sprite.flip_h = false
		sprite.play(mirrored_name)
	elif frames.has_animation(anim_name):
		sprite.flip_h = mirrored
		sprite.play(anim_name)


## The animation without the mirrored suffix, for checks like "is it walking".
static func base_name(anim_name : StringName) -> StringName:
	var text : String = String(anim_name)
	return StringName(text.trim_suffix(SUFFIX))
