class_name LvvRaidSnapshot
extends Resource

## A raid squad under way, frozen for the save. The fine and seizure are already in the
## saved run; this keeps the squad's walk and the recap it ends in.

@export var confiscated_bottles : int = 0
@export var fine_amount : float = 0.0
@export var reputation_lost : int = 0
@export var agent_count : int = 0
## Seconds each agent sent in has walked of its route; negative for one already gone.
@export var agent_elapsed : Array[float] = []
## Seconds before the next agent comes down the stairs.
@export var next_agent_in : float = 0.0
