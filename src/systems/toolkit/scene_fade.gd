class_name SceneFade
extends RefCounted

## Fades to black, switches scene, fades back in. The overlay hangs on the window root, so
## it outlives the old scene and hides the new one's first, heaviest frames. The fade steps
## through a few flat shades, to suit pixel art, and swallows clicks while it runs.

const FADE_SECONDS : float = 0.25
const SHADE_STEPS : float = 4.0
## Above every game layer (CanvasLayer allows up to 128).
const LAYER : int = 128
## A frame this quick means the new scene has settled; give up waiting after the max.
const SETTLED_FRAME_SECONDS : float = 0.05
const SETTLE_MAX_FRAMES : int = 15


## Switches `tree` to `path` behind the fade. The scene loads on the main thread while the
## screen is black: a threaded read raced the running scene for shared files, and froze or
## broke the load about once in fifty starts.
## `at_black` runs once the screen is black, just before the switch: unpausing there keeps
## the old scene still while it fades, and a reset there is never seen on the old screen.
static func change_to(tree : SceneTree, path : String, at_black : Callable = Callable()) -> void:
	var layer := CanvasLayer.new()
	layer.layer = LAYER
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var curtain := ColorRect.new()
	curtain.color = Color(0.0, 0.0, 0.0, 0.0)
	curtain.mouse_filter = Control.MOUSE_FILTER_STOP
	curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(curtain)
	tree.root.add_child(layer)

	await _fade(layer, curtain, 0.0, 1.0).finished
	if at_black.is_valid():
		at_black.call()
	tree.change_scene_to_file(path)
	# The new scene's _ready() and first draws are slow; stay black until frames are quick
	# again, or that hitch eats the fade in.
	for frame : int in SETTLE_MAX_FRAMES:
		await tree.process_frame
		if frame > 0 and layer.get_process_delta_time() < SETTLED_FRAME_SECONDS:
			break
	await _fade(layer, curtain, 1.0, 0.0).finished
	layer.queue_free()


static func _fade(layer : CanvasLayer, curtain : ColorRect, from : float, to : float) -> Tween:
	var tween : Tween = layer.create_tween()
	tween.tween_method(func(alpha : float) -> void: curtain.color.a = snappedf(alpha, 1.0 / SHADE_STEPS), from, to, FADE_SECONDS)
	return tween
