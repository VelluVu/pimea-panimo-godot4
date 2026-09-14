class_name CustomerSpawner
extends Node2D


const WALK_IN_INTERVAL_MIN_SECONDS = 30.0
const WALK_IN_INTERVAL_MAX_SECONDS = 90.0
const WALK_IN_INTERVAL_FLOOR_SECONDS = 10.0
const REPUTATION_SPAWN_SOFT_CAP = 100.0

## Halved from the original 240-480s: against the default 300s day, that
## average (360s) meant most days saw zero group visits by pure chance —
## see playtest_notes_2.txt. Now reputation-scaled the same way walk-ins
## already are (GROUP_EVENT_FLOOR_SECONDS keeps it meaningfully rarer than
## a walk-in even at high reputation), so the feature stays visible at day
## one and keeps paying off as reputation climbs past the point where the
## customer roster is fully unlocked.
const GROUP_EVENT_INTERVAL_MIN_SECONDS = 150.0
const GROUP_EVENT_INTERVAL_MAX_SECONDS = 300.0
const GROUP_EVENT_FLOOR_SECONDS = 120.0
const GROUP_DIALOGUE_SLOT_BASE = 10
const GROUP_DIALOGUE_SLOT_RANGE = 90

const CUSTOMER_SCENE = preload("res://scenes/customer.tscn")

@onready var counter_positions_parent: Node2D = $CounterPositionsParent
@onready var stairs_bottom_marker: Marker2D = $StairsBottomMarker
@onready var room_center_marker: Marker2D = $RoomCenterMarker

var walk_in_timer: Timer
var group_event_timer: Timer
var counter_markers: Array[Node2D] = []
var _group_dialogue_slot_counter: int = 0


func _ready() -> void:
	_setup_timer()
	_setup_group_timer()
	_setup_positions()
	CustomerManager.register_spawner(self)


func _setup_timer() -> void:
	walk_in_timer = Timer.new()
	walk_in_timer.process_callback = Timer.TIMER_PROCESS_IDLE
	walk_in_timer.one_shot = true
	walk_in_timer.timeout.connect(_on_walk_in_timer_timeout)
	add_child(walk_in_timer)


func _setup_group_timer() -> void:
	group_event_timer = Timer.new()
	group_event_timer.process_callback = Timer.TIMER_PROCESS_IDLE
	group_event_timer.one_shot = true
	group_event_timer.timeout.connect(_on_group_event_timer_timeout)
	add_child(group_event_timer)


func _setup_positions() -> void:
	if counter_positions_parent:
		for child in counter_positions_parent.get_children():
			if child is Node2D:
				counter_markers.append(child)


func start_spawning() -> void:
	if walk_in_timer.is_stopped():
		_start_next_walk_in_timer()
	if group_event_timer.is_stopped():
		_start_next_group_event_timer()


func _start_next_walk_in_timer() -> void:
	var factor := _get_reputation_spawn_factor()
	var min_time := maxf(WALK_IN_INTERVAL_FLOOR_SECONDS, WALK_IN_INTERVAL_MIN_SECONDS * factor)
	var max_time := maxf(min_time, WALK_IN_INTERVAL_MAX_SECONDS * factor)
	var next_time = randf_range(min_time, max_time)
	walk_in_timer.start(next_time)


func _start_next_group_event_timer() -> void:
	var factor := _get_reputation_spawn_factor()
	var min_time := maxf(GROUP_EVENT_FLOOR_SECONDS, GROUP_EVENT_INTERVAL_MIN_SECONDS * factor)
	var max_time := maxf(min_time, GROUP_EVENT_INTERVAL_MAX_SECONDS * factor)
	var next_time = randf_range(min_time, max_time)
	group_event_timer.start(next_time)


func _get_reputation_spawn_factor() -> float:
	var brewery = BrewEngine.current_brewery
	if brewery == null:
		return 1.0
	return REPUTATION_SPAWN_SOFT_CAP / (REPUTATION_SPAWN_SOFT_CAP + brewery.reputation)


## Deliberately does NOT check for empty inventory — that gate only applies
## to the very first spawn ever (see CustomerManager.register_spawner() /
## _on_brewery_state_changed(), which withhold start_spawning() until the
## player's first brew). Once spawning has begun, running out of stock
## later is on the player: customers keep walking in and simply get turned
## away (Customer._on_preview_timeout()'s NOTHING_AVAILABLE_TEXT_FORMAT,
## then CustomerManager.process_auto_sale()'s no-match branch), costing
## reputation and risk same as any other bad visit.
func _on_walk_in_timer_timeout(forced_data: CustomerData = null) -> void:
	if BrewEngine.current_brewery == null or counter_markers.is_empty():
		_start_next_walk_in_timer()
		return

	var free_slot = CustomerManager.get_free_slot_index()
	if free_slot == -1 or free_slot >= counter_markers.size():
		_start_next_walk_in_timer()
		return

	var data = forced_data if forced_data != null else CustomerManager.get_random_customer_data()
	if data == null:
		_start_next_walk_in_timer()
		return

	if data.randomizes_preference:
		data = data.duplicate()
		data.reroll_preference()

	var new_customer = CUSTOMER_SCENE.instantiate()
	add_child(new_customer)
	new_customer.generated_name = data.generate_display_name()
	new_customer.global_position = global_position
	new_customer.customer_data = data
	new_customer.assigned_slot = free_slot
	new_customer.dialogue_slot = free_slot

	CustomerManager.register_active_customer(free_slot, new_customer)
	
	var marker = counter_markers[free_slot]
	new_customer.walk_complex_route(stairs_bottom_marker.global_position, room_center_marker.global_position, marker.global_position)

	_start_next_walk_in_timer()


## Crowd walk-in: a whole group shares a single counter slot (there are only
## as many physical slots as counter_markers, far fewer than a group's size),
## clustering with a small jitter around one marker instead of each member
## claiming their own spot. Members are spawned on a stagger so the crowd
## visibly floods in rather than popping in all at once.
## See _on_walk_in_timer_timeout()'s docstring — same reasoning, no empty-
## inventory check here either. A group that finds nothing to buy still
## runs the normal shared order through process_auto_sale()'s no-match
## branch (_run_shared_group_order() below), it just leaves empty-handed.
func _on_group_event_timer_timeout(forced_event_data: GroupVisitEventData = null) -> void:
	if BrewEngine.current_brewery == null or counter_markers.is_empty():
		_start_next_group_event_timer()
		return

	var free_slot = CustomerManager.get_free_slot_index()
	if free_slot == -1 or free_slot >= counter_markers.size():
		_start_next_group_event_timer()
		return

	var event_data = forced_event_data if forced_event_data != null else CustomerRegistry.get_random_group_event()
	if event_data == null or event_data.customer_data_options.is_empty():
		_start_next_group_event_timer()
		return

	BrewerySignals.group_visit_announced.emit(event_data.banner_text)
	_spawn_group_members(event_data, free_slot)

	_start_next_group_event_timer()


## The crowd acts as one unit, not N independent customers: every member
## walks in and idles at the counter (skip_interaction=true — see
## walk_complex_route), but only ONE shared dialogue_slot is used for the
## whole event, carrying the walking chant, the intro, and the sale result
## in a single bubble, and only ONE order is placed (see
## _run_shared_group_order) rather than each member selling separately.
## The three phases (spawn, chant-while-walking, order) run strictly in
## sequence in this one coroutine — never overlapping — since two things
## pushing to the same shared dialogue_slot at once would race each other's
## hide-timers on the same bubble (this crashed once already; see the
## dialogue_slot comment on Customer).
func _spawn_group_members(event_data: GroupVisitEventData, slot: int) -> void:
	var marker = counter_markers[slot]
	var group_size = randi_range(event_data.min_group_size, event_data.max_group_size)
	var dialogue_slot = GROUP_DIALOGUE_SLOT_BASE + (_group_dialogue_slot_counter % GROUP_DIALOGUE_SLOT_RANGE)
	_group_dialogue_slot_counter += 1

	var members : Array[Node2D] = []
	var last_member : Node2D = null

	for i in range(group_size):
		var new_customer = CUSTOMER_SCENE.instantiate()
		add_child(new_customer)
		new_customer.global_position = global_position
		new_customer.customer_data = event_data.customer_data_options.pick_random()
		new_customer.assigned_slot = slot
		# The group's one shared bubble slot, not a personal one — stored on
		# each member anyway so CustomerManager.evict_active_customers() has
		# something to pass to DialogView when throwing this member out;
		# every member pointing at the same shared slot is exactly right,
		# since clearing it once covers the whole group's bubble.
		new_customer.dialogue_slot = dialogue_slot

		CustomerManager.register_active_customer(slot, new_customer)
		members.append(new_customer)
		last_member = new_customer

		# Applied to every waypoint after the stairs (not the stairs
		# themselves, which stay a shared single-file bottleneck), so each
		# member's path visibly diverges the moment they step off the
		# stairs instead of walking single-file on top of each other until
		# snapping into place at the very end.
		var formation_offset = _get_group_formation_offset(i, group_size, event_data.formation_spacing_px)
		new_customer.walk_complex_route(stairs_bottom_marker.global_position, room_center_marker.global_position + formation_offset, marker.global_position + formation_offset, true)

		if i < group_size - 1:
			await get_tree().create_timer(event_data.walk_in_stagger_seconds).timeout

	# Waits for the LAST-spawned (and so latest-arriving) member specifically,
	# not just any member — starting the order while stragglers are still
	# walking in would look wrong and, more importantly, would risk the
	# chant and the order dialogue overlapping on the shared bubble.
	await _wait_for_group_arrival(event_data, last_member, dialogue_slot)
	_run_shared_group_order(event_data, members, dialogue_slot, marker.global_position)


## Blocks until the last-spawned member's own walk finishes — every other
## member walks the same route with only a small formation offset and
## arrives sooner, so the last spawn is the reliable "everyone's here now"
## signal. Along the way, re-shows the chant in the shared bubble if this
## event has one; with no chant this is just a silent wait for arrival, so
## the order phase never starts while stragglers are still walking in.
func _wait_for_group_arrival(event_data: GroupVisitEventData, last_member: Node2D, dialogue_slot: int) -> void:
	var state := {"walking": true}
	last_member.walk_route_finished.connect(func(): state.walking = false, CONNECT_ONE_SHOT)

	while state.walking and is_instance_valid(last_member):
		if not event_data.chant_text.is_empty():
			BrewerySignals.dialogue_pushed.emit(event_data.chant_text, false, dialogue_slot, last_member.global_position, event_data.chant_interval_seconds + 0.3, 0.3)
		await get_tree().create_timer(event_data.chant_interval_seconds).timeout


## The group's single shared order: one intro line, one preview delay, then
## one process_auto_sale() call against a customer_data duplicate whose
## bottle range is scaled up by the crowd size — so the economy math and
## bar-fight roll stay exactly the existing single-customer logic, just
## sized for "this many people ordered at once" instead of running it once
## per member. All members leave together once the result has been shown.
func _run_shared_group_order(event_data: GroupVisitEventData, members: Array[Node2D], dialogue_slot: int, group_position: Vector2) -> void:
	# This whole order is one coroutine, not a per-member timer chain like a
	# solo customer's (see CustomerManager.evict_active_customers()'s
	# docstring) — evicting the group by freeing its member nodes doesn't
	# stop this from still running and completing process_auto_sale() below
	# on its own. Bail out up front if every member is already gone instead.
	if not members.any(func(member : Node2D) -> bool: return is_instance_valid(member)):
		return

	var order_data : CustomerData = event_data.customer_data_options.pick_random().duplicate()
	if order_data.randomizes_preference:
		order_data.reroll_preference()
	order_data.min_bottles_per_visit *= members.size()
	order_data.max_bottles_per_visit *= members.size()

	var group_label := "%s-lauma (%d hlöä)" % [order_data.title, members.size()]

	var intro_text := "%s: %s" % [group_label, order_data.dialogue_intro]
	var intro_display_time := Customer._get_display_time_for_text(intro_text)
	BrewerySignals.dialogue_pushed.emit(intro_text, false, dialogue_slot, group_position, intro_display_time, Customer.FADE_TIME_SECONDS)

	await get_tree().create_timer(Customer.PREVIEW_DELAY_SECONDS).timeout

	# Same capture pattern as Customer._on_sale_timeout() — see its
	# comment for why this needs a Dictionary, not a plain captured int.
	var xp_capture : Dictionary = {"amount": 0}
	var capture_xp := func(amount : int) -> void: xp_capture.amount = amount
	var reputation_capture : Dictionary = {"amount": 0}
	var capture_reputation := func(amount : int) -> void: reputation_capture.amount = amount
	var tip_capture : Dictionary = {"amount": 0.0}
	var capture_tip := func(amount : float) -> void: tip_capture.amount = amount

	BrewerySignals.sale_xp_gained.connect(capture_xp)
	BrewerySignals.sale_reputation_gained.connect(capture_reputation)
	BrewerySignals.sale_tip_gained.connect(capture_tip)
	var response_text : String = CustomerManager.process_auto_sale(order_data)
	BrewerySignals.sale_xp_gained.disconnect(capture_xp)
	BrewerySignals.sale_reputation_gained.disconnect(capture_reputation)
	BrewerySignals.sale_tip_gained.disconnect(capture_tip)

	if xp_capture.amount > 0:
		for member in members:
			if is_instance_valid(member):
				member.made_purchase = true
		BrewerySignals.xp_popup_requested.emit(xp_capture.amount, group_position)
	if reputation_capture.amount != 0:
		BrewerySignals.reputation_popup_requested.emit(reputation_capture.amount, group_position)
	if tip_capture.amount > 0:
		BrewerySignals.tip_popup_requested.emit(tip_capture.amount, group_position)

	var final_text := "%s: %s" % [group_label, response_text]
	var display_time := Customer._get_display_time_for_text(final_text)
	BrewerySignals.dialogue_pushed.emit(final_text, false, dialogue_slot, group_position, display_time, Customer.FADE_TIME_SECONDS)

	await get_tree().create_timer(display_time + Customer.FADE_TIME_SECONDS).timeout

	for member in members:
		if is_instance_valid(member):
			member.leave_counter()


## A compact two-row huddle centered on the shared marker, rather than a
## single wide line (the gap between adjacent counter markers is only
## ~43px, so a full-width single-row line for a 10-person crowd would
## sprawl across several neighboring counter positions) or random jitter
## (which can place two members on almost the same spot). Members alternate
## rows so consecutive spawns land visibly apart even with tight spacing.
func _get_group_formation_offset(index: int, group_size: int, spacing: float) -> Vector2:
	var centered_index := float(index) - (float(group_size - 1) / 2.0)
	var row := index % 2
	return Vector2(centered_index * spacing, row * spacing * 0.7)
