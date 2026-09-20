class_name GroupVisitDirector
extends RefCounted

## Runs one crowd visit: members walk in, chant while the last one arrives,
## then place a single shared order, get served and leave together. Owned by
## CustomerSpawner, which decides when a visit happens and hands over the
## node the members are spawned under.

const CUSTOMER_SCENE = preload("res://scenes/customer.tscn")

const GROUP_DIALOGUE_SLOT_BASE = 10

const GROUP_DIALOGUE_SLOT_RANGE = 90

## Group serving burst: a glass every GROUP_SERVE_INTERVAL_SECONDS, faster than a
## solo customer's pacing.
const GROUP_SERVE_INTERVAL_SECONDS : float = 0.3

const GROUP_SERVE_ANIMATION_SPEED_SCALE : float = 3.0

const GROUP_SERVE_GLASS_SLIDE_SECONDS : float = 0.25

## Extra distance every member except the order-place representative stands from
## the counter, so the crowd does not hide the bartender.
const GROUP_STANDBY_Y_OFFSET_PX : float = 56.0

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


## Waits on the host's tree. False when the host was freed meanwhile (scene
## change), so the visit can stop instead of touching freed nodes.
func _wait(seconds : float) -> bool:
	if not is_instance_valid(_host):
		return false
	await _host.get_tree().create_timer(seconds).timeout
	return is_instance_valid(_host)


## Spawns the crowd, waits for the last member to arrive (chanting meanwhile), then
## runs the shared order. The phases run strictly in sequence: two things pushing to
## one dialogue slot would race each other's hide timers.
func run(event_data: GroupVisitEventData, slot: int, counter_position: Vector2) -> void:
	# The lower of two rolls skews toward min_group_size, keeping big crowds rare.
	var group_size = mini(
		randi_range(event_data.min_group_size, event_data.max_group_size),
		randi_range(event_data.min_group_size, event_data.max_group_size)
	)
	var dialogue_slot = GROUP_DIALOGUE_SLOT_BASE + (_dialogue_slot_counter % GROUP_DIALOGUE_SLOT_RANGE)
	_dialogue_slot_counter += 1

	var members : Array[Node2D] = []
	var last_member : Node2D = null

	for i in range(group_size):
		var new_customer = CUSTOMER_SCENE.instantiate()
		_host.add_child(new_customer)
		new_customer.global_position = _host.global_position
		new_customer.customer_data = event_data.customer_data_options.pick_random()
		new_customer.assigned_slot = slot
		# Every member carries the group's shared bubble slot, so evicting any of them
		# clears the whole group's bubble.
		new_customer.dialogue_slot = dialogue_slot

		CustomerManager.register_active_customer(slot, new_customer)
		members.append(new_customer)
		last_member = new_customer

		# Only the first member walks to the counter marker (the order-place representative).
		# The rest take a formation slot pushed down-screen by GROUP_STANDBY_Y_OFFSET_PX, so
		# the crowd does not hide the bartender's pour.
		var formation_offset := Vector2.ZERO
		if i > 0:
			formation_offset = formation_offset(i - 1, group_size - 1, event_data.formation_spacing_px)
			formation_offset.y += GROUP_STANDBY_Y_OFFSET_PX

		# The offset applies after the stairs (a shared bottleneck), so paths diverge as
		# soon as members step off them.
		new_customer.walk_complex_route(_stairs_marker.global_position, _room_center_marker.global_position + formation_offset, counter_position + formation_offset, true)

		if i < group_size - 1:
			if not await _wait(event_data.walk_in_stagger_seconds):
				return

	# Wait for the last member specifically: an earlier order could overlap the chant on
	# the shared bubble.
	await _wait_for_group_arrival(event_data, last_member, dialogue_slot)
	_run_shared_group_order(event_data, members, dialogue_slot, counter_position)


## Waits for the last-spawned member's walk to finish, chanting into the shared
## bubble meanwhile if the event has a chant.
func _wait_for_group_arrival(event_data: GroupVisitEventData, last_member: Node2D, dialogue_slot: int) -> void:
	var state := {"walking": true}
	last_member.walk_route_finished.connect(func(): state.walking = false, CONNECT_ONE_SHOT)

	var chant_index : int = 0
	while state.walking and is_instance_valid(last_member):
		var chant_text : String = event_data.get_chant_text(chant_index)
		chant_index += 1
		if not chant_text.is_empty():
			BrewerySignals.dialogue_pushed.emit(chant_text, false, dialogue_slot, last_member.global_position, event_data.chant_interval_seconds + 0.3, 0.3)
		if not await _wait(event_data.chant_interval_seconds):
			return


## One intro line, then one process_auto_sale() against a copy of the customer data
## with its bottle range scaled by crowd size, then everyone leaves together.
func _run_shared_group_order(event_data: GroupVisitEventData, members: Array[Node2D], dialogue_slot: int, group_position: Vector2) -> void:
	# The order is one coroutine, so evicting the group does not stop it: bail out if
	# every member is already gone.
	if not members.any(func(member : Node2D) -> bool: return is_instance_valid(member)):
		return

	var order_data : CustomerData = event_data.customer_data_options.pick_random().duplicate()
	if order_data.randomizes_preference:
		order_data.reroll_preference(_active_styles.call())
	order_data.min_bottles_per_visit *= members.size()
	order_data.max_bottles_per_visit *= members.size()

	var group_label := "%s-lauma (%d hlöä)" % [order_data.title, members.size()]

	var intro_text := "%s: %s" % [group_label, order_data.dialogue_intro]
	var intro_display_time := Customer._get_display_time_for_text(intro_text)
	BrewerySignals.dialogue_pushed.emit(intro_text, false, dialogue_slot, group_position, intro_display_time, Customer.FADE_TIME_SECONDS)

	if not await _wait(Customer.PREVIEW_DELAY_SECONDS):
		return

	# Same capture pattern as Customer._on_sale_timeout().
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

		# One sale but many drinks: serve one glass per member in a fast burst (sped-up
		# bartender, one glass per GROUP_SERVE_INTERVAL_SECONDS), each landing on the counter
		# stack.
		var bartender := _host.get_tree().get_first_node_in_group(Bartender.BARTENDER_GROUP) as Bartender
		var stack_index := 0
		for member in members:
			if not await _wait(GROUP_SERVE_INTERVAL_SECONDS):
				return
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

	if not await _wait(display_time + Customer.FADE_TIME_SECONDS):
		return

	# Only the representative (members[0]) leaves from where they stand; the others first
	# collect their round from the counter, staggered so the crowd peels off one by one.
	for i in range(members.size()):
		var member = members[i]
		if not is_instance_valid(member):
			continue
		if i == 0:
			member.leave_counter()
		else:
			member.leave_counter(group_position)
			if not await _wait(GROUP_SERVE_INTERVAL_SECONDS):
				return


## A compact two-row huddle around the shared marker: counter markers are only about
## 43px apart, so one wide line would sprawl over the neighbouring positions.
static func formation_offset(index: int, group_size: int, spacing: float) -> Vector2:
	var centered_index := float(index) - (float(group_size - 1) / 2.0)
	var row := index % 2
	return Vector2(centered_index * spacing, row * spacing * 0.7)
