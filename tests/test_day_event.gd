@tool
extends McpTestSuite

## Unit tests for DayEventData's pure logic (see src/classes/day_event_data.gd).
## The actual roll/window-timing/bias integration (DayEventManager,
## CustomerRegistry.get_random_customer_data(), CustomerSpawner._pick_group_event())
## needs a running game with live autoload state and isn't covered here —
## same reach-into-autoload-state category test_group_visit.gd's own
## class-level note (and test_brew_resolver.gd's) already explain; verified
## live instead this session (see the playtest notes for this feature).


func suite_name() -> String:
	return "day_event"


func test_defaults() -> void:
	var event := DayEventData.new()
	assert_eq(event.event_name, "")
	assert_true(event.featured_group_event == null)
	assert_true(event.featured_customer_titles.is_empty())
	assert_true(event.window_fraction_min <= event.window_fraction_max)
	assert_true(event.start_delay_fraction_min <= event.start_delay_fraction_max)
	assert_eq(event.effect_type, DayEventData.EffectType.NONE)


func test_get_window_fraction_stays_within_configured_range() -> void:
	var event := DayEventData.new()
	event.window_fraction_min = 0.2
	event.window_fraction_max = 0.4

	for i in range(20):
		var fraction := event.get_window_fraction()
		assert_true(fraction >= 0.2 and fraction <= 0.4, "window fraction out of range: %s" % fraction)


func test_get_start_delay_fraction_stays_within_configured_range() -> void:
	var event := DayEventData.new()
	event.start_delay_fraction_min = 0.0
	event.start_delay_fraction_max = 0.25

	for i in range(20):
		var fraction := event.get_start_delay_fraction()
		assert_true(fraction >= 0.0 and fraction <= 0.25, "start delay fraction out of range: %s" % fraction)


func test_get_effect_amount_stays_within_configured_range() -> void:
	var event := DayEventData.new()
	event.effect_amount_min = 2
	event.effect_amount_max = 5

	for i in range(20):
		var amount := event.get_effect_amount()
		assert_true(amount >= 2 and amount <= 5, "effect amount out of range: %s" % amount)


## Every "unfortunate" event (effect_type != NONE) needs a toast format to
## actually report what it did — an empty format would show a blank/broken
## toast instead of silently no-opping, so this is caught here rather than
## only at the moment such an event happens to roll live.
func test_shipped_day_events_with_effect_have_toast_format() -> void:
	var dir := DirAccess.open("res://src/resources/day_events/")
	assert_true(dir != null, "day_events folder should exist")

	dir.list_dir_begin()
	var file_name := dir.get_next()
	var checked_with_effect := 0
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var event : DayEventData = load("res://src/resources/day_events/" + file_name)
			if event.effect_type != DayEventData.EffectType.NONE:
				checked_with_effect += 1
				assert_false(event.effect_toast_format.is_empty(),
					"%s: effect_type set but effect_toast_format is empty" % file_name)
				assert_true(event.effect_amount_min <= event.effect_amount_max,
					"%s: effect_amount_min > effect_amount_max" % file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	assert_true(checked_with_effect >= 2, "expected at least the 2 shipped unfortunate day events, found %d" % checked_with_effect)


## A day event never covers the whole day — window_fraction_max should
## always leave real room for a start delay too, so the two together can
## never push the window past the day's own end. Guards the "part of the
## day, not all of it" requirement this feature exists for (see
## DayEventData's own docstring) directly on every shipped resource, not
## just the base class defaults above.
func test_shipped_day_events_never_cover_the_whole_day() -> void:
	var dir := DirAccess.open("res://src/resources/day_events/")
	assert_true(dir != null, "day_events folder should exist")

	dir.list_dir_begin()
	var file_name := dir.get_next()
	var checked := 0
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var event : DayEventData = load("res://src/resources/day_events/" + file_name)
			assert_true(event.window_fraction_max + event.start_delay_fraction_max <= 1.0,
				"%s: window_fraction_max + start_delay_fraction_max exceeds a full day" % file_name)
			checked += 1
		file_name = dir.get_next()
	dir.list_dir_end()

	assert_true(checked >= 9, "expected at least the 9 shipped day events, found %d" % checked)
