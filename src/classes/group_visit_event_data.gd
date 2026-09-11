class_name GroupVisitEventData
extends Resource

## A crowd walk-in: one big announcement banner, then a burst of customers
## (all sharing a single CustomerData archetype) who all cluster at one
## shared counter position instead of spreading across the usual slots.
## The crowd acts as a single unit rather than N independent customers: one
## shared speech bubble carries the optional walking chant, the intro, and
## the sale result, and one shared order (customer_data's own bottle range
## scaled by group size) is placed against the shared inventory — not N
## separate per-member sales.


@export_multiline var banner_text: String = ""
@export var customer_data: CustomerData = null

@export_group("Ryhmän koko")
@export var min_group_size: int = 6
@export var max_group_size: int = 10

@export_group("Ajoitus")
@export var walk_in_stagger_seconds: float = 0.4
@export var formation_spacing_px: float = 11.0

@export_group("Kuorohuuto")
## Optional chant shown (and repeated) in the shared bubble while the group
## is still walking in. Left empty, no chant plays.
@export_multiline var chant_text: String = ""
@export var chant_interval_seconds: float = 2.5
