class_name LvvRaidSpawner
extends Node2D

## Reacts to Brewery's own raid trigger (BrewerySignals.lvv_raid_triggered)
## with a visual squad of LvvAgents: walk in down the stairs, then through
## route_waypoints (see below) to line up with and walk into the warehouse
## doorway, each seize a keg, then walk back out. Uses its own
## EntryMarker/StairsMarker/route markers/PickupMarker (siblings of this
## node in main.tscn) instead of reusing CustomerSpawner's — fully
## independent and freely draggable in the editor without touching the
## customer walk-in path. The actual confiscation/fine/reputation math
## already happened synchronously in Brewery — this is purely the
## dramatization, ending in lvv_raid_recap_ready once the squad has fully
## left, which is what LvvRaidWindow actually shows the recap on.

const LVV_AGENT_SCENE : PackedScene = preload("res://src/scenes/lvv_agent.tscn")

const MIN_AGENTS : int = 2
const MAX_AGENTS : int = 3
## Staggered spawn, same idea as CustomerSpawner's group walk-in stagger —
## a squad flooding in all on the same frame reads as a glitch, not a raid.
const AGENT_SPAWN_STAGGER_SECONDS : float = 0.5

## Off-screen-ish spot each agent first appears at before descending
## EntryMarker/StairsMarker's stairs leg — same idea as CustomerSpawner's
## own root position doubling as its customers' spawn point.
@onready var entry_marker : Marker2D = $EntryMarker
@onready var stairs_marker : Marker2D = $StairsMarker

## Route from the stairs bottom into the warehouse, walked in this exact
## order (then reversed for the way out) — see LvvAgent.walk_in_and_seize()/
## _tween_leg(), which derives each leg's animation (walk_right vs
## walk_towards/walk_away) purely from the direction between consecutive
## points. WarehouseAlignMarker lines the squad up on the same floor-level X
## as the doorway; WarehouseDoorwayMarker is the doorway threshold itself
## (walked to with walk_away, appearing to head into the room, and where
## WarehouseWallOverlay's polygon — see main.tscn — visually occludes them
## like StairsWallOverlay does for the stairs). Add, remove, or drag any of
## these three (or PickupMarker) in the editor; nothing here needs to change.
@onready var warehouse_align_marker : Marker2D = $WarehouseAlignMarker
@onready var warehouse_doorway_marker : Marker2D = $WarehouseDoorwayMarker
@onready var pickup_marker : Marker2D = $PickupMarker

## Guards against a second raid firing (extremely unlikely given
## Brewery.risk is reset to 0 on trigger, but risk-reset happens
## synchronously while this coroutine is still mid-flight) — if it somehow
## does, skip the visual and hand the recap straight through rather than
## running two squads on top of each other or dropping the recap entirely.
var _raid_in_progress : bool = false


func _ready() -> void:
	BrewerySignals.lvv_raid_triggered.connect(_on_lvv_raid_triggered)


func _on_lvv_raid_triggered(confiscated_bottles : int, fine_amount : float, reputation_lost : int) -> void:
	if _raid_in_progress:
		BrewerySignals.lvv_raid_recap_ready.emit(confiscated_bottles, fine_amount, reputation_lost)
		return
	_run_raid(confiscated_bottles, fine_amount, reputation_lost)


func _run_raid(confiscated_bottles : int, fine_amount : float, reputation_lost : int) -> void:
	_raid_in_progress = true
	CustomerManager.pause_spawning()

	var waypoints : Array[Vector2] = [
		stairs_marker.global_position,
		warehouse_align_marker.global_position,
		warehouse_doorway_marker.global_position,
		pickup_marker.global_position,
	]

	var agent_count := randi_range(MIN_AGENTS, MAX_AGENTS)
	var agents : Array[LvvAgent] = []

	for i in range(agent_count):
		var agent : LvvAgent = LVV_AGENT_SCENE.instantiate()
		add_child(agent)
		agent.global_position = entry_marker.global_position
		agents.append(agent)
		agent.walk_in_and_seize(waypoints)

		if i < agent_count - 1:
			await get_tree().create_timer(AGENT_SPAWN_STAGGER_SECONDS).timeout

	for agent in agents:
		if is_instance_valid(agent):
			await agent.raid_sequence_finished

	CustomerManager.resume_spawning()
	_raid_in_progress = false
	BrewerySignals.lvv_raid_recap_ready.emit(confiscated_bottles, fine_amount, reputation_lost)
