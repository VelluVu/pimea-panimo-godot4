class_name GroupVisitDirector
extends RefCounted

## Runs one crowd visit: members walk in, chant while the last one arrives, then place a
## single shared order, get served and leave together. Owned by CustomerSpawner, which
## decides when a visit happens and hands over the node the members are spawned under.
## The phases run strictly in sequence: two things pushing to one dialogue slot would
## race each other's hide timers.

const CUSTOMER_SCENE : PackedScene = preload("res://scenes/customer.tscn")

const GROUP_LABEL_FORMAT : String = "%s-lauma (%d hlöä)"
const SPEECH_FORMAT : String = "%s: %s"

const DIALOGUE_SLOT_BASE : int = 10
const DIALOGUE_SLOT_RANGE : int = 90

const CHANT_BUBBLE_EXTRA_SECONDS : float = 0.3
const CHANT_BUBBLE_FADE_SECONDS : float = 0.3

## Serving burst: a glass every SERVE_INTERVAL_SECONDS, faster than a solo customer's pacing.
const SERVE_INTERVAL_SECONDS : float = 0.3
const SERVE_ANIMATION_SPEED_SCALE : float = 3.0
const SERVE_GLASS_SLIDE_SECONDS : float = 0.25

## Extra distance every member except the representative stands from the counter, so the
## crowd does not hide the bartender.
const STANDBY_Y_OFFSET_PX : float = 56.0

var _host : Node2D
var _stairs_marker : Marker2D
var _room_center_marker : Marker2D
## Returns the run's beer styles, for members that roll a random preference.
var _active_styles : Callable
var _dialogue_slot_counter : int = 0


func _init(host : Node2D, stairs_marker : Marker2D, room_center_marker : Marker2D, active_styles : Callable) -> void:
	_host = host
	_stairs_marker = stairs_marker
	_room_center_marker = room_center_marker
	_active_styles = active_styles


## The lower of two rolls skews toward min_size, keeping big crowds rare.
static func roll_group_size(min_size : int, max_size : int) -> int:
	return mini(randi_range(min_size, max_size), randi_range(min_size, max_size))


## A compact two-row huddle around the shared marker: counter markers are only about 43px
## apart, so one wide line would sprawl over the neighbouring positions.
static func formation_offset(index : int, group_size : int, spacing : float) -> Vector2:
	var centered_index : float = float(index) - (float(group_size - 1) / 2.0)
	var row : int = index % 2
	return Vector2(centered_index * spacing, row * spacing * 0.7)


## One copy of a random member's data for the whole crowd's order, its bottle range scaled
## by crowd size. A copy, so the shared resource is never mutated.
static func build_order_data(options : Array[CustomerData], member_count : int, styles : Array[BeerStyle]) -> CustomerData:
	var order_data : CustomerData = options.pick_random().duplicate()
	if order_data.randomizes_preference:
		order_data.reroll_preference(styles)
	order_data.min_bottles_per_visit *= member_count
	order_data.max_bottles_per_visit *= member_count
	return order_data


func run(event_data : GroupVisitEventData, slot : int, counter_position : Vector2) -> void:
	var visit := GroupVisit.new(event_data, slot, _next_dialogue_slot(), counter_position)
	var group_size : int = roll_group_size(event_data.min_group_size, event_data.max_group_size)

	for i : int in group_size:
		visit.members.append(_spawn_member(visit, i, group_size))
		if i < group_size - 1 and not await _wait(event_data.walk_in_stagger_seconds):
			return

	# Wait for the last member specifically: an earlier order could overlap the chant on
	# the shared bubble.
	await _chant_until_arrival(visit)
	_run_shared_order(visit)


## Waits on the host's tree. False when the host was freed meanwhile (scene change), so
## the visit can stop instead of touching freed nodes.
func _wait(seconds : float) -> bool:
	if not is_instance_valid(_host):
		return false
	await _host.get_tree().create_timer(seconds).timeout
	return is_instance_valid(_host)


func _next_dialogue_slot() -> int:
	var dialogue_slot : int = DIALOGUE_SLOT_BASE + (_dialogue_slot_counter % DIALOGUE_SLOT_RANGE)
	_dialogue_slot_counter += 1
	return dialogue_slot


func _spawn_member(visit : GroupVisit, index : int, group_size : int) -> Customer:
	var member : Customer = CUSTOMER_SCENE.instantiate()
	_host.add_child(member)
	member.global_position = _host.global_position
	member.customer_data = visit.event_data.customer_data_options.pick_random()
	member.assigned_slot = visit.slot
	member.dialogue_slot = visit.dialogue_slot
	CustomerManager.register_active_customer(visit.slot, member)

	# The offset applies after the stairs (a shared bottleneck), so paths diverge as soon as
	# members step off them.
	var offset : Vector2 = _formation_offset_for(index, group_size, visit.event_data.formation_spacing_px)
	member.walk_complex_route(_stairs_marker.global_position, _room_center_marker.global_position + offset, visit.counter_position + offset, true)
	return member


## Only the first member walks to the counter marker itself; the rest take a formation slot
## pushed down-screen, so the crowd does not hide the bartender's pour.
func _formation_offset_for(index : int, group_size : int, spacing : float) -> Vector2:
	if index == 0:
		return Vector2.ZERO
	var offset : Vector2 = formation_offset(index - 1, group_size - 1, spacing)
	offset.y += STANDBY_Y_OFFSET_PX
	return offset


## Waits for the last-spawned member's walk to finish, chanting into the shared bubble
## meanwhile if the event has a chant.
func _chant_until_arrival(visit : GroupVisit) -> void:
	var last_member : Customer = visit.members.back()
	var state : Dictionary = {"walking": true}
	last_member.walk_route_finished.connect(func() -> void: state.walking = false, CONNECT_ONE_SHOT)

	var chant_index : int = 0
	while state.walking and is_instance_valid(last_member):
		var chant_text : String = visit.event_data.get_chant_text(chant_index)
		chant_index += 1
		if not chant_text.is_empty():
			var display_time : float = visit.event_data.chant_interval_seconds + CHANT_BUBBLE_EXTRA_SECONDS
			BrewerySignals.dialogue_pushed.emit(chant_text, false, visit.dialogue_slot, last_member.global_position, display_time, CHANT_BUBBLE_FADE_SECONDS)
		if not await _wait(visit.event_data.chant_interval_seconds):
			return


## One intro line, then one process_auto_sale() for the whole crowd, then everyone leaves
## together. It is one coroutine, so evicting the group does not stop it: it bails out if
## every member is already gone.
func _run_shared_order(visit : GroupVisit) -> void:
	if not visit.has_anyone_here():
		return

	var order_data : CustomerData = build_order_data(visit.event_data.customer_data_options, visit.size(), _active_styles.call())
	var group_label : String = GROUP_LABEL_FORMAT % [order_data.title, visit.size()]
	_say(visit, SPEECH_FORMAT % [group_label, order_data.dialogue_intro])
	if not await _wait(Customer.PREVIEW_DELAY_SECONDS):
		return

	# process_auto_sale() is synchronous, so signals fired during it belong to this sale.
	var outcome := SaleOutcomeCapture.new()
	outcome.start()
	var response_text : String = CustomerManager.process_auto_sale(order_data)
	outcome.stop()

	if outcome.xp > 0:
		visit.mark_purchased()
		BrewerySignals.xp_popup_requested.emit(outcome.xp, visit.counter_position)
		if not await _serve_burst(visit):
			return
	if outcome.reputation != 0:
		BrewerySignals.reputation_popup_requested.emit(outcome.reputation, visit.counter_position)
	if outcome.tip > 0:
		BrewerySignals.tip_popup_requested.emit(outcome.tip, visit.counter_position)

	var display_time : float = _say(visit, SPEECH_FORMAT % [group_label, response_text])
	if await _wait(display_time + Customer.FADE_TIME_SECONDS):
		await _dismiss(visit)


## One sale but many drinks: a sped-up bartender pours one glass per member, each landing
## on the counter stack. False when the host was freed meanwhile.
func _serve_burst(visit : GroupVisit) -> bool:
	var bartender := _host.get_tree().get_first_node_in_group(Bartender.BARTENDER_GROUP) as Bartender
	var stack_index : int = 0
	for member : Variant in visit.members:
		if not await _wait(SERVE_INTERVAL_SECONDS):
			return false
		if bartender != null:
			bartender.play_serve_beer(SERVE_ANIMATION_SPEED_SCALE)
		if is_instance_valid(member):
			var stack_position : Vector2 = bartender.get_stack_position(stack_index) if bartender != null else Vector2.INF
			member.show_counter_glass(SERVE_GLASS_SLIDE_SECONDS, stack_position)
			stack_index += 1
	return true


## Only the representative leaves from where they stand; the others first collect their
## round from the counter, staggered so the crowd peels off one by one.
func _dismiss(visit : GroupVisit) -> void:
	for i : int in visit.size():
		var member : Variant = visit.members[i]
		if not is_instance_valid(member):
			continue
		if i == 0:
			member.leave_counter()
			continue
		member.leave_counter(visit.counter_position)
		if not await _wait(SERVE_INTERVAL_SECONDS):
			return


## Pushes a line into the group's shared bubble and returns how long it stays up.
func _say(visit : GroupVisit, text : String) -> float:
	var display_time : float = Customer.get_display_time_for_text(text)
	BrewerySignals.dialogue_pushed.emit(text, false, visit.dialogue_slot, visit.counter_position, display_time, Customer.FADE_TIME_SECONDS)
	return display_time
