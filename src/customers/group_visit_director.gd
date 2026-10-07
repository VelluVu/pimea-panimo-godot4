class_name GroupVisitDirector
extends RefCounted

## Runs crowd visits for CustomerSpawner: members walk in and chant, place one shared
## order, get served and leave together. The stages (GroupVisit.Stage) run in sequence:
## two pushes to one dialogue slot would race each other's hide timers. A saved visit
## resumes at its stage, see resume().

const CUSTOMER_SCENE : PackedScene = preload("res://src/scenes/customer.tscn")

const GROUP_LABEL_FORMAT : String = "%s-lauma (%d hlöä)"
const SPEECH_FORMAT : String = "%s: %s"

const DIALOGUE_SLOT_BASE : int = 10
const DIALOGUE_SLOT_RANGE : int = 90

const CHANT_BUBBLE_EXTRA_SECONDS : float = 0.3
const CHANT_BUBBLE_FADE_SECONDS : float = 0.3

const SERVE_INTERVAL_SECONDS : float = 0.3
const SERVE_ANIMATION_SPEED_SCALE : float = 3.0
const SERVE_GLASS_SLIDE_SECONDS : float = 0.25

## Everyone but the representative stands this far back, so the crowd hides no pouring.
const STANDBY_Y_OFFSET_PX : float = 56.0

var _host : Node2D
var _stairs_marker : Marker2D
var _room_center_marker : Marker2D
## Returns the run's beer styles, for members that roll a random preference.
var _active_styles : Callable
var _dialogue_slot_counter : int = 0
var _visits : Array[GroupVisit] = []


func _init(host : Node2D, stairs_marker : Marker2D, room_center_marker : Marker2D, active_styles : Callable) -> void:
	_host = host
	_stairs_marker = stairs_marker
	_room_center_marker = room_center_marker
	_active_styles = active_styles


## The lower of two rolls, so big crowds stay rare.
static func roll_group_size(min_size : int, max_size : int) -> int:
	return mini(randi_range(min_size, max_size), randi_range(min_size, max_size))


## A compact two-row huddle: counter markers are only ~43px apart.
static func formation_offset(index : int, group_size : int, spacing : float) -> Vector2:
	var centered_index : float = float(index) - (float(group_size - 1) / 2.0)
	var row : int = index % 2
	return Vector2(centered_index * spacing, row * spacing * 0.7)


## The crowd's order: a copy (the shared resource stays untouched) scaled by crowd size.
static func build_order_data(options : Array[CustomerData], member_count : int, styles : Array[BeerStyle]) -> CustomerData:
	var order_data : CustomerData = options.pick_random().duplicate()
	if order_data.randomizes_preference:
		order_data.reroll_preference(styles)
	order_data.min_bottles_per_visit *= member_count
	order_data.max_bottles_per_visit *= member_count
	order_data.bar_fight_min_bottles_bought *= member_count
	return order_data


func run(event_data : GroupVisitEventData, slot : int, counter_position : Vector2) -> void:
	var visit := GroupVisit.new(event_data, slot, _next_dialogue_slot(), counter_position)
	visit.group_size = roll_group_size(event_data.min_group_size, event_data.max_group_size)
	await _play(visit, -1.0)


## Carries on a saved visit at `slot`: members walk or stand where they were and the
## stage picks up with the wait it had left. The sale is never made twice.
func resume(snap : GroupVisitSnapshot, slot : int, counter_position : Vector2) -> void:
	var visit := GroupVisit.new(snap.event_data, slot, _next_dialogue_slot(), counter_position)
	visit.restore(snap)
	var shift : Vector2 = counter_position - snap.counter_position
	for member_snap : CustomerSnapshot in snap.members:
		visit.members.append(_resume_member(visit, member_snap, shift) if member_snap != null else null)
	if snap.bubble_time_left > 0.0:
		_show_bubble(visit, snap.bubble_text, snap.bubble_position + shift, snap.bubble_time_left, snap.bubble_fade)
	await _play(visit, snap.time_left)


## Every visit under way, frozen for the save.
func snapshots() -> Array[GroupVisitSnapshot]:
	var snaps : Array[GroupVisitSnapshot] = []
	for visit : GroupVisit in _visits:
		if visit.has_anyone_here():
			snaps.append(visit.snapshot())
	return snaps


## Runs the stages from the visit's own on. `resume_seconds` is what was left of the
## first stage's wait when saved, or negative for a fresh start.
func _play(visit : GroupVisit, resume_seconds : float) -> void:
	_visits.append(visit)
	while visit.stage != GroupVisit.Stage.DONE:
		if not await _run_stage(visit, resume_seconds):
			break
		resume_seconds = -1.0
		visit.stage = (visit.stage + 1) as GroupVisit.Stage
	_visits.erase(visit)


## False when the visit must stop (host freed, nobody left).
func _run_stage(visit : GroupVisit, resume_seconds : float) -> bool:
	match visit.stage:
		GroupVisit.Stage.SPAWNING:
			return await _spawn_members(visit, resume_seconds)
		GroupVisit.Stage.CHANTING:
			return await _chant_until_arrival(visit, resume_seconds)
		GroupVisit.Stage.ORDERING:
			return await _order(visit, resume_seconds)
		GroupVisit.Stage.SERVING:
			return await _serve_burst(visit, resume_seconds)
		GroupVisit.Stage.TALKING:
			return await _talk(visit, resume_seconds)
		GroupVisit.Stage.DISMISSING:
			return await _dismiss(visit, resume_seconds)
	return false


## False when the host was freed meanwhile (scene change): the visit must stop.
func _wait(visit : GroupVisit, seconds : float) -> bool:
	if not is_instance_valid(_host):
		return false
	visit.timer = _host.get_tree().create_timer(seconds)
	await visit.timer.timeout
	return is_instance_valid(_host)


func _next_dialogue_slot() -> int:
	var dialogue_slot : int = DIALOGUE_SLOT_BASE + (_dialogue_slot_counter % DIALOGUE_SLOT_RANGE)
	_dialogue_slot_counter += 1
	return dialogue_slot


func _spawn_members(visit : GroupVisit, resume_seconds : float) -> bool:
	if resume_seconds >= 0.0 and not await _wait(visit, resume_seconds):
		return false
	while visit.size() < visit.group_size:
		visit.members.append(_spawn_member(visit, visit.size()))
		if visit.size() < visit.group_size and not await _wait(visit, visit.event_data.walk_in_stagger_seconds):
			return false
	return true


func _spawn_member(visit : GroupVisit, index : int) -> Customer:
	var member : Customer = CUSTOMER_SCENE.instantiate()
	_host.add_child(member)
	member.global_position = _host.global_position
	member.customer_data = visit.event_data.customer_data_options.pick_random()
	member.assigned_slot = visit.slot
	member.dialogue_slot = visit.dialogue_slot
	CustomerManager.register_active_customer(visit.slot, member)

	# Applied after the stairs, a shared bottleneck, so paths diverge only past them.
	var offset : Vector2 = _formation_offset_for(index, visit.group_size, visit.event_data.formation_spacing_px)
	member.walk_complex_route(_stairs_marker.global_position, _room_center_marker.global_position + offset, visit.counter_position + offset, true)
	return member


## One already walking out without a pickup holds no counter spot. `shift` moves the
## counter end of a route when the visit resumes at another spot.
func _resume_member(visit : GroupVisit, snap : CustomerSnapshot, shift : Vector2) -> Customer:
	var member : Customer = CUSTOMER_SCENE.instantiate()
	_host.add_child(member)
	member.customer_data = snap.data
	member.dialogue_slot = visit.dialogue_slot
	if snap.phase != CustomerSnapshot.Phase.LEAVING:
		if snap.route.size() == 4:
			snap.route[3] += shift
		if snap.phase == CustomerSnapshot.Phase.WAITING:
			snap.position += shift
	if snap.phase != CustomerSnapshot.Phase.LEAVING or snap.walks_to_pickup:
		member.assigned_slot = visit.slot
		CustomerManager.register_active_customer(visit.slot, member)
	member.resume(snap)
	return member


## Only the first member walks to the marker itself; the rest stand down-screen.
func _formation_offset_for(index : int, group_size : int, spacing : float) -> Vector2:
	if index == 0:
		return Vector2.ZERO
	var offset : Vector2 = formation_offset(index - 1, group_size - 1, spacing)
	offset.y += STANDBY_Y_OFFSET_PX
	return offset


## The last member specifically: an earlier order could overlap the chant.
func _chant_until_arrival(visit : GroupVisit, resume_seconds : float) -> bool:
	if resume_seconds >= 0.0 and not await _wait(visit, resume_seconds):
		return false
	var last_member : Variant = visit.members.back()
	while is_instance_valid(last_member) and last_member.is_walking_in():
		var chant_text : String = tr(visit.event_data.get_chant_text(visit.chant_index))
		visit.chant_index += 1
		if not chant_text.is_empty():
			var display_time : float = visit.event_data.chant_interval_seconds + CHANT_BUBBLE_EXTRA_SECONDS
			_show_bubble(visit, chant_text, last_member.global_position, display_time, CHANT_BUBBLE_FADE_SECONDS)
			BrewerySignals.customer_spoke.emit(last_member.global_position, last_member.customer_data.voice_pitch)
		if not await _wait(visit, visit.event_data.chant_interval_seconds):
			return false
	return true


## Evicting the group does not stop the visit: it bails out here if every member is gone.
## The sale ends the stage in the same frame, so a save never lands between the two.
func _order(visit : GroupVisit, resume_seconds : float) -> bool:
	if resume_seconds < 0.0:
		if not visit.has_anyone_here():
			return false
		visit.order_data = build_order_data(visit.event_data.customer_data_options, visit.size(), _active_styles.call())
		_say(visit, SPEECH_FORMAT % [_group_label(visit), tr(visit.order_data.dialogue_intro)])
		resume_seconds = Customer.PREVIEW_DELAY_SECONDS
	if not await _wait(visit, resume_seconds):
		return false
	_sell(visit)
	return true


func _sell(visit : GroupVisit) -> void:
	# Synchronous, so signals fired during it belong to this sale.
	var outcome := SaleOutcomeCapture.new()
	outcome.start()
	visit.response_text = CustomerManager.process_auto_sale(visit.order_data)
	outcome.stop()

	visit.outcome = outcome
	visit.beer_ebc = outcome.beer_ebc
	visit.bar_fight_bottles = outcome.bar_fight_bottles
	for member : Variant in visit.members:
		if is_instance_valid(member):
			member.fill_glasses(outcome.beer_ebc)
	if outcome.xp > 0:
		visit.mark_purchased()
		_mark_members_served(visit, visit.order_data.title)
		outcome.emit_xp_popup(visit.counter_position)


func _group_label(visit : GroupVisit) -> String:
	return tr(GROUP_LABEL_FORMAT) % [tr(visit.order_data.title), visit.size()]


## The sale reported the ordering type as served; a mixed group drank the round too.
func _mark_members_served(visit : GroupVisit, order_title : String) -> void:
	var reported : Dictionary = {order_title: true}
	for member : Variant in visit.members:
		if is_instance_valid(member) and not reported.has(member.customer_data.title):
			reported[member.customer_data.title] = true
			BrewerySignals.customer_served.emit(member.customer_data)


## The whole group rampages, but the broken glasses are shared out, not multiplied:
## the sale already charged the fight once.
func _start_group_rampage(visit : GroupVisit, broken_bottles : int) -> void:
	for i : int in visit.size():
		var member : Variant = visit.members[i]
		if is_instance_valid(member):
			member.play_rampage(BarFightRampage.share_of(i, broken_bottles, visit.size()))


## One sale, many drinks: a sped-up pour per member, then the sale's popups.
func _serve_burst(visit : GroupVisit, resume_seconds : float) -> bool:
	if visit.purchased:
		var bartender := _host.get_tree().get_first_node_in_group(Bartender.BARTENDER_GROUP) as Bartender
		while visit.served < visit.size():
			var seconds : float = resume_seconds if resume_seconds >= 0.0 else SERVE_INTERVAL_SECONDS
			resume_seconds = -1.0
			if not await _wait(visit, seconds):
				return false
			if bartender != null:
				bartender.play_serve_beer(SERVE_ANIMATION_SPEED_SCALE, visit.beer_ebc)
			var member : Variant = visit.members[visit.served]
			visit.served += 1
			if is_instance_valid(member):
				var stack_position : Vector2 = bartender.get_stack_position(visit.glasses_out) if bartender != null else Vector2.INF
				member.show_counter_glass(SERVE_GLASS_SLIDE_SECONDS, stack_position)
				visit.glasses_out += 1
	if visit.outcome != null:
		visit.outcome.emit_reputation_and_money_popups(visit.counter_position)
		visit.outcome = null
	return true


func _talk(visit : GroupVisit, resume_seconds : float) -> bool:
	if resume_seconds < 0.0:
		var display_time : float = _say(visit, SPEECH_FORMAT % [_group_label(visit), visit.response_text])
		resume_seconds = display_time + Customer.FADE_TIME_SECONDS
		if visit.bar_fight_bottles >= 0:
			_start_group_rampage(visit, visit.bar_fight_bottles)
			resume_seconds = maxf(resume_seconds, BarFightRampage.DURATION_SECONDS)
	return await _wait(visit, resume_seconds)


## The representative leaves in place; the rest collect their round first, staggered.
## Members already on their way (a resumed visit) are skipped.
func _dismiss(visit : GroupVisit, resume_seconds : float) -> bool:
	if resume_seconds >= 0.0 and not await _wait(visit, resume_seconds):
		return false
	for i : int in visit.size():
		var member : Variant = visit.members[i]
		if not is_instance_valid(member) or member.is_leaving():
			continue
		if i == 0:
			member.leave_counter()
			continue
		member.leave_counter(visit.counter_position)
		if not await _wait(visit, SERVE_INTERVAL_SECONDS):
			return false
	return true


## Returns how long the line stays up in the shared bubble.
func _say(visit : GroupVisit, text : String) -> float:
	var display_time : float = Customer.get_display_time_for_text(text)
	_show_bubble(visit, text, visit.counter_position, display_time, Customer.FADE_TIME_SECONDS)
	BrewerySignals.customer_spoke.emit(visit.counter_position, _voice_pitch_of(visit))
	return display_time


## Kept on the visit so a save can put the line back up for the time it had left.
func _show_bubble(visit : GroupVisit, text : String, position : Vector2, display_time : float, fade_seconds : float) -> void:
	visit.bubble_text = text
	visit.bubble_position = position
	visit.bubble_fade = fade_seconds
	visit.bubble_timer = _host.get_tree().create_timer(display_time)
	BrewerySignals.dialogue_pushed.emit(text, false, visit.dialogue_slot, position, display_time, fade_seconds)


## The first member still here speaks for the group.
func _voice_pitch_of(visit : GroupVisit) -> float:
	for member : Variant in visit.members:
		if is_instance_valid(member):
			return member.customer_data.voice_pitch
	return 1.0
