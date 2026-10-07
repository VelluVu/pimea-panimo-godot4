class_name SpecialEventSnapshot
extends Resource

## A special event window open when the run was saved (Brewery.open_special_events), so a
## loaded run shows it again with the time it had left. SpecialEventWindow fills it.

@export var event_data : SpecialEventData
## Seconds left to answer; unused once answered.
@export var time_left : float = 0.0
## The caller's reply once answered (the event is already settled), with its seconds left.
@export var answer_text : String = ""
@export var fade_left : float = 0.0
