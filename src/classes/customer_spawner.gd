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

## A group's shared order resolves as one process_auto_sale() call (see
## _run_shared_group_order()), but the bartender still serves each member
## individually — these three tune that serving burst to read as fast and
## dynamic (a beer landing every GROUP_SERVE_INTERVAL_SECONDS) rather than
## the slower, "wait for the full pour" pacing a solo customer's single
## glass uses (Customer.SERVE_BEER_WAIT_SECONDS/GLASS_SLIDE_DURATION_SECONDS).
const GROUP_SERVE_INTERVAL_SECONDS : float = 0.3
const GROUP_SERVE_ANIMATION_SPEED_SCALE : float = 3.0
const GROUP_SERVE_GLASS_SLIDE_SECONDS : float = 0.25

## Pushes every group member except the order-place representative (see
## _spawn_group_members()) this much further down-screen (away from the
## counter, toward the room) than their formation offset alone would place
## them — a crowd huddled right up against the counter otherwise blocks the
## Bartender fixture standing just behind it, hiding the very pour/serve
## burst this whole group-order flow exists to show off.
const GROUP_STANDBY_Y_OFFSET_PX : float = 56.0

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


## Used by LvvRaidSpawner while a raid squad is walking in/out — nobody
## should be ordering a beer while inspectors are hauling kegs out the door.
## Only stops scheduling NEW walk-ins/group events; any customer already at
## the counter is left alone to finish naturally, same as any other timing
## edge case in this system. start_spawning() (called again once the raid
## visual is done) re-rolls fresh intervals rather than resuming a paused
## countdown — acceptably simpler given how rare/short a raid is relative to
## the normal spawn cadence.
func pause_spawning() -> void:
	walk_in_timer.stop()
	group_event_timer.stop()


func _start_next_walk_in_timer() -> void:
	var factor := _get_reputation_spawn_factor() * _get_perk_spawn_interval_multiplier()
	var min_time := maxf(WALK_IN_INTERVAL_FLOOR_SECONDS, WALK_IN_INTERVAL_MIN_SECONDS * factor)
	var max_time := maxf(min_time, WALK_IN_INTERVAL_MAX_SECONDS * factor)
	var next_time = randf_range(min_time, max_time)
	walk_in_timer.start(next_time)


func _start_next_group_event_timer() -> void:
	var factor := _get_reputation_spawn_factor() * _get_perk_spawn_interval_multiplier() * _get_perk_group_event_interval_multiplier()
	var min_time := maxf(GROUP_EVENT_FLOOR_SECONDS, GROUP_EVENT_INTERVAL_MIN_SECONDS * factor)
	var max_time := maxf(min_time, GROUP_EVENT_INTERVAL_MAX_SECONDS * factor)
	var next_time = randf_range(min_time, max_time)
	group_event_timer.start(next_time)


func _get_reputation_spawn_factor() -> float:
	var brewery = BrewEngine.current_brewery
	if brewery == null:
		return 1.0
	return REPUTATION_SPAWN_SOFT_CAP / (REPUTATION_SPAWN_SOFT_CAP + brewery.reputation)


## RunPerk.spawn_interval_multiplier (e.g. MetaUnlockData's "Kanta-
## asiakkaat" bar-work node) layered on top of the reputation factor above
## — below 1.0 shortens both walk-in and group-event waits. Still clamped
## by WALK_IN_INTERVAL_FLOOR_SECONDS/GROUP_EVENT_FLOOR_SECONDS via the
## maxf() calls in both callers, so this can never make spawns instant.
func _get_perk_spawn_interval_multiplier() -> float:
	var brewery = BrewEngine.current_brewery
	if brewery == null:
		return 1.0
	return brewery.get_spawn_interval_multiplier()


## RunPerk.group_event_interval_multiplier (e.g. MetaUnlockData's
## "Mainoskampanja" marketing node) — layered on top of both the reputation
## factor and _get_perk_spawn_interval_multiplier() above, but only inside
## _start_next_group_event_timer(). Unlike that shared multiplier, this one
## never touches _start_next_walk_in_timer().
func _get_perk_group_event_interval_multiplier() -> float:
	var brewery = BrewEngine.current_brewery
	if brewery == null:
		return 1.0
	return brewery.get_group_event_interval_multiplier()


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

	var event_data = forced_event_data if forced_event_data != null else _pick_group_event()
	if event_data == null or event_data.customer_data_options.is_empty():
		_start_next_group_event_timer()
		return

	BrewerySignals.group_visit_announced.emit(event_data.banner_text)
	_spawn_group_members(event_data, free_slot)

	_start_next_group_event_timer()


## During an active DayEventData window (see DayEventManager), rolls toward
## that event's own featured_group_event at its own featured_group_event_chance
## instead of always using the plain random pool — same "weighted, not
## forced" shape CustomerRegistry.get_random_customer_data() uses for solo
## walk-ins, so a themed day's group visits skew toward its own crowd
## without turning every single group event into a rerun of the same one.
func _pick_group_event() -> GroupVisitEventData:
	var day_event : DayEventData = DayEventManager.get_active_event()
	if day_event != null and day_event.featured_group_event != null and randf() < day_event.featured_group_event_chance:
		return day_event.featured_group_event
	return CustomerRegistry.get_random_group_event()


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
	# The lower of two independent rolls, not one flat randi_range() — skews
	# the result toward event_data.min_group_size (a small 3-5 person crowd
	# is the common case) while still leaving the full range reachable, just
	# increasingly unlikely near max_group_size (both rolls have to land high
	# at once), so a big lauma stays a rare, notable event instead of the
	# every-time norm the flat uniform roll produced.
	var group_size = mini(
		randi_range(event_data.min_group_size, event_data.max_group_size),
		randi_range(event_data.min_group_size, event_data.max_group_size)
	)
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

		# Only the first-spawned member actually walks up to the counter
		# marker itself — the group's "order place" representative, standing
		# exactly where a solo customer would (see _run_shared_group_order(),
		# which places the shared dialogue/popups at marker.global_position
		# too). Everyone else in the crowd gets a formation slot (re-centered
		# over the remaining group_size - 1 members, so there's no empty gap
		# where the representative would have sat) pushed further down-screen
		# by GROUP_STANDBY_Y_OFFSET_PX — clustered nearby but out of the
		# Bartender's sightline instead of hugging the counter three-deep and
		# hiding the pour/serve burst the player is meant to actually watch.
		var formation_offset := Vector2.ZERO
		if i > 0:
			formation_offset = _get_group_formation_offset(i - 1, group_size - 1, event_data.formation_spacing_px)
			formation_offset.y += GROUP_STANDBY_Y_OFFSET_PX

		# Applied to every waypoint after the stairs (not the stairs
		# themselves, which stay a shared single-file bottleneck), so each
		# member's path visibly diverges the moment they step off the
		# stairs instead of walking single-file on top of each other until
		# snapping into place at the very end.
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

	var chant_index : int = 0
	while state.walking and is_instance_valid(last_member):
		var chant_text : String = event_data.get_chant_text(chant_index)
		chant_index += 1
		if not chant_text.is_empty():
			BrewerySignals.dialogue_pushed.emit(chant_text, false, dialogue_slot, last_member.global_position, event_data.chant_interval_seconds + 0.3, 0.3)
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

		# Deliberately NOT the solo-customer pacing (wait the full pour, then
		# reveal): a group order is one sale but many drinks, so this instead
		# throws one glass per member in a fast one-by-one burst — bartender
		# sped up via GROUP_SERVE_ANIMATION_SPEED_SCALE and re-triggered every
		# GROUP_SERVE_INTERVAL_SECONDS (restarting the pour anim from frame 0
		# each time reads as a rapid flurry of pours, not a glitch). Each
		# glass rests in Bartender.get_stack_position()'s on-counter stack,
		# not out at that member's own (now far-back, see
		# GROUP_STANDBY_Y_OFFSET_PX) seat — the round physically piles up on
		# the bar, the way a real round of drinks would, instead of every
		# glass individually flying out across the room to its owner.
		var bartender := get_tree().get_first_node_in_group(Bartender.BARTENDER_GROUP) as Bartender
		var stack_index := 0
		for member in members:
			await get_tree().create_timer(GROUP_SERVE_INTERVAL_SECONDS).timeout
			if bartender != null:
				bartender.play_serve_beer(GROUP_SERVE_ANIMATION_SPEED_SCALE)
			if is_instance_valid(member):
				var stack_position := bartender.get_stack_position(stack_index) if bartender != null else Vector2.INF
				member.show_counter_glass(GROUP_SERVE_GLASS_SLIDE_SECONDS, stack_position)
				stack_index += 1
	if reputation_capture.amount != 0:
		BrewerySignals.reputation_popup_requested.emit(reputation_capture.amount, group_position)
	if tip_capture.amount > 0:
		BrewerySignals.tip_popup_requested.emit(tip_capture.amount, group_position)

	var final_text := "%s: %s" % [group_label, response_text]
	var display_time := Customer._get_display_time_for_text(final_text)
	BrewerySignals.dialogue_pushed.emit(final_text, false, dialogue_slot, group_position, display_time, Customer.FADE_TIME_SECONDS)

	await get_tree().create_timer(display_time + Customer.FADE_TIME_SECONDS).timeout

	# Only the order-place representative (members[0], already standing right
	# at the counter — see _spawn_group_members()) leaves straight from where
	# they're standing. Everyone else first walks up to the counter to grab
	# their round off the stack (Customer.leave_counter()'s pickup walk)
	# before turning to leave, instead of the beer just appearing in their
	# hand from their standby spot further back. Staggered by the same
	# GROUP_SERVE_INTERVAL_SECONDS beat the serving burst used, so the crowd
	# peels off the counter one by one instead of every standby member
	# converging on the exact same spot at once.
	for i in range(members.size()):
		var member = members[i]
		if not is_instance_valid(member):
			continue
		if i == 0:
			member.leave_counter()
		else:
			member.leave_counter(group_position)
			await get_tree().create_timer(GROUP_SERVE_INTERVAL_SECONDS).timeout


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
