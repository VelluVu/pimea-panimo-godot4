class_name ImmersionActorData
extends Resource

## One critter/person in an ImmersionVignetteData: what it looks like and how
## it walks the vignette's path. Purely presentational, no gameplay stats.

@export var sprite_frames : SpriteFrames
## Animation played for the whole crossing. The art is drawn facing left, so
## ImmersionEventSpawner mirrors the sprite on legs that head right.
@export var animation : StringName = &"walk_left"
## Scale at the depth-reference line (see ImmersionEventSpawner's DEPTH_*
## constants); the spawner shrinks/grows it from here by screen y.
@export var base_scale : Vector2 = Vector2(4, 4)
## Seconds after the vignette starts before this actor appears. Two actors
## with the same crossing time keep this as a constant gap the whole way
## across (a steady chase rather than one catching up).
@export var start_delay_seconds : float = 0.0
## Time to walk the whole path, start to end.
@export var crossing_seconds : float = 6.0
