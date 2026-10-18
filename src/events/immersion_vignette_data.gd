class_name ImmersionVignetteData
extends Resource

## A decorative scene: actors walking one waypoint path. Every .tres in its folder is
## picked up at startup, so a new vignette is data, not code.

@export var vignette_name : String = ""
## The ImmersionEventSpawner child whose Marker2Ds form the path, in child order.
@export var path_node_name : StringName = &"PathMarkers"
@export var actors : Array[ImmersionActorData] = []
## Relative chance among all vignettes when the spawner picks one.
@export var weight : float = 1.0
## The adopted cellar cat's walk: never in the random pick, played on its own timer
## once Brewery.cellar_cat_adopted (ImmersionEventSpawner).
@export var needs_cellar_cat : bool = false
