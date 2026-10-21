class_name ConeDust
extends CPUParticles2D

## Dust specks that start only inside a lamp's light cone (ConeArea), so none float in
## the dark beside it. The cone is measured from the light's texture and scale, around
## this node's x, with a small margin for the specks' drift.

@export var top_y : float = -85.0
@export var bottom_y : float = 70.0
@export var top_half_width : float = 24.0
@export var bottom_half_width : float = 104.0
@export var point_count : int = 160


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	emission_shape = CPUParticles2D.EMISSION_SHAPE_POINTS
	emission_points = ConeArea.random_points(point_count, top_y, bottom_y, top_half_width, bottom_half_width, rng)
