class_name GroupVisitEventData
extends Resource

## A crowd walk-in: one banner, then a burst of customers clustered at one counter spot.
## The crowd acts as one: a shared speech bubble for chant, intro and result, and one
## order (the archetype's range scaled by group size) instead of a sale per member.


@export_multiline var banner_text: String = ""
## Variants of one archetype (say its male and female CustomerData), picked at random per
## member so the crowd looks mixed. The shared order copies a random one too, so variants
## must share title and stats and differ only in sprite, name and lines.
@export var customer_data_options: Array[CustomerData] = []

@export_group("Ryhmän koko")
@export var min_group_size: int = 3
@export var max_group_size: int = 10

@export_group("Ajoitus")
@export var walk_in_stagger_seconds: float = 0.4
@export var formation_spacing_px: float = 11.0

## SEQUENCE cycles chant_texts in the order they're listed (a call-and-
## response crowd, or a line that's meant to build on the last one);
## RANDOM picks a fresh line each interval (a chaotic/no-particular-order
## crowd) — see get_chant_text().
enum ChantMode { SEQUENCE, RANDOM }

@export_group("Kuorohuuto")
## Optional line(s) shown (and cycled) in the shared bubble while the group
## is still walking in. Left empty, no chant plays. A single entry repeats
## every interval exactly like the old chant_text did.
@export var chant_texts: Array[String] = []
@export var chant_mode: ChantMode = ChantMode.SEQUENCE
@export var chant_interval_seconds: float = 2.5


## sequence_index is an ever-increasing counter the caller owns (see
## GroupVisitDirector._wait_for_group_arrival) — SEQUENCE wraps it via modulo
## instead of the caller needing to know chant_texts.size() itself; RANDOM
## ignores it entirely.
func get_chant_text(sequence_index: int) -> String:
	if chant_texts.is_empty():
		return ""
	if chant_mode == ChantMode.RANDOM:
		return chant_texts[randi() % chant_texts.size()]
	return chant_texts[sequence_index % chant_texts.size()]
