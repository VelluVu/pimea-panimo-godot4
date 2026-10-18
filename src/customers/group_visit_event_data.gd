class_name GroupVisitEventData
extends Resource

## A crowd walk-in: a banner, then a burst of customers at one counter spot acting as one:
## a shared bubble and one order scaled by group size.


@export_multiline var banner_text: String = ""
## Variants of one archetype (male and female), picked per member so the crowd looks mixed.
## The order copies a random one, so variants share title and stats.
@export var customer_data_options: Array[CustomerData] = []

@export_group("Ryhmän koko")
@export var min_group_size: int = 3
@export var max_group_size: int = 10

@export_group("Ajoitus")
@export var walk_in_stagger_seconds: float = 0.4
@export var formation_spacing_px: float = 11.0

## SEQUENCE cycles chant_texts in order (call and response); RANDOM picks a fresh line each
## time.
enum ChantMode { SEQUENCE, RANDOM }

@export_group("Kuorohuuto")
## Lines cycled in the shared bubble while the group walks in; empty = no chant.
@export var chant_texts: Array[String] = []
@export var chant_mode: ChantMode = ChantMode.SEQUENCE
@export var chant_interval_seconds: float = 2.5


## `sequence_index` is the caller's ever-growing counter; SEQUENCE wraps it, RANDOM ignores it.
func get_chant_text(sequence_index: int) -> String:
	if chant_texts.is_empty():
		return ""
	if chant_mode == ChantMode.RANDOM:
		return chant_texts[randi() % chant_texts.size()]
	return chant_texts[sequence_index % chant_texts.size()]
