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

## The raid under way, or null. Also guards against a second raid firing (extremely
## unlikely given Brewery.risk is reset to 0 on trigger, but risk-reset happens
## synchronously while this coroutine is still mid-flight): if it somehow does, skip the
## visual and hand the recap straight through rather than running two squads on top of
## each other or dropping the recap entirely.
var _raid : LvvRaidSnapshot
var _agents : Array[LvvAgent] = []
var _stagger_timer : SceneTreeTimer


func _ready() -> void:
	BrewerySignals.lvv_raid_triggered.connect(_on_lvv_raid_triggered)
	BrewEngine.brewery_about_to_save.connect(_record_raid)
	_resume_raid.call_deferred()


func _on_lvv_raid_triggered(confiscated_bottles : int, fine_amount : float, reputation_lost : int) -> void:
	if _raid != null:
		BrewerySignals.lvv_raid_recap_ready.emit(confiscated_bottles, fine_amount, reputation_lost)
		return
	var raid := LvvRaidSnapshot.new()
	raid.confiscated_bottles = confiscated_bottles
	raid.fine_amount = fine_amount
	raid.reputation_lost = reputation_lost
	raid.agent_count = randi_range(MIN_AGENTS, MAX_AGENTS)
	_run_raid(raid)


## A fresh raid starts with no agents in; a loaded one puts its agents back where they
## were on their route and sends the rest in on the stagger they had left.
func _run_raid(raid : LvvRaidSnapshot) -> void:
	_raid = raid
	_agents.clear()
	CustomerManager.pause_spawning()

	for elapsed : float in raid.agent_elapsed:
		if elapsed < 0.0:
			_agents.append(null)
		else:
			_send_agent(elapsed)
	var wait : float = raid.next_agent_in
	while _agents.size() < raid.agent_count:
		if wait > 0.0:
			_stagger_timer = get_tree().create_timer(wait)
			await _stagger_timer.timeout
		_send_agent(0.0)
		wait = AGENT_SPAWN_STAGGER_SECONDS
	_stagger_timer = null

	for agent : LvvAgent in _agents.duplicate():
		if is_instance_valid(agent):
			await agent.raid_sequence_finished

	CustomerManager.resume_spawning()
	_raid = null
	BrewerySignals.lvv_raid_recap_ready.emit(raid.confiscated_bottles, raid.fine_amount, raid.reputation_lost)


func _send_agent(elapsed_seconds : float) -> void:
	var waypoints : Array[Vector2] = [
		stairs_marker.global_position,
		warehouse_align_marker.global_position,
		warehouse_doorway_marker.global_position,
		pickup_marker.global_position,
	]
	var agent : LvvAgent = LVV_AGENT_SCENE.instantiate()
	add_child(agent)
	agent.global_position = entry_marker.global_position
	_agents.append(agent)
	agent.walk_in_and_seize(waypoints, elapsed_seconds)


func _record_raid(brewery : Brewery) -> void:
	brewery.lvv_raid = null
	if _raid == null:
		return
	var snap := LvvRaidSnapshot.new()
	snap.confiscated_bottles = _raid.confiscated_bottles
	snap.fine_amount = _raid.fine_amount
	snap.reputation_lost = _raid.reputation_lost
	snap.agent_count = _raid.agent_count
	for agent : LvvAgent in _agents:
		# An agent already gone still counts, or the resumed raid would send it again.
		snap.agent_elapsed.append(agent.elapsed_seconds() if is_instance_valid(agent) and not agent.is_queued_for_deletion() else -1.0)
	snap.next_agent_in = _stagger_timer.time_left if _stagger_timer != null else 0.0
	brewery.lvv_raid = snap


func _resume_raid() -> void:
	var brewery : Brewery = BrewEngine.current_brewery
	if brewery == null or brewery.lvv_raid == null:
		return
	var raid : LvvRaidSnapshot = brewery.lvv_raid
	brewery.lvv_raid = null
	_run_raid(raid)
