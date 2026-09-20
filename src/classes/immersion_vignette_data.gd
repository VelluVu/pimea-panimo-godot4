class_name ImmersionVignetteData
extends Resource

## A purely decorative background scene: some actors walking one waypoint
## path across the floor. Every .tres in res://src/resources/immersion_vignettes/
## is picked up by ImmersionEventSpawner at startup, so a new vignette is a
## data file, not code.

@export var vignette_name : String = ""
## Name of the Node2D child of ImmersionEventSpawner whose Marker2D children
## form the path (walked in child order, first = spawn, last = despawn).
## Lets different vignettes use different routes.
@export var path_node_name : StringName = &"PathMarkers"
@export var actors : Array[ImmersionActorData] = []
## Relative chance among all vignettes when the spawner picks one.
@export var weight : float = 1.0
