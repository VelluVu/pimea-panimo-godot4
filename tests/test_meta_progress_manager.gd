@tool
extends McpTestSuite

## Unit tests for MetaProgressManager's pure renown formula and the
## leveled unlock-purchase state machine. A fresh instance is created via
## preload() rather than the MetaProgressManager autoload singleton — same
## reasoning as test_leaderboard_manager.gd — so these tests never touch
## the real user://meta_progress.cfg or its real unlock_pool. _ready()
## (which would load the real file, scan the real unlock folder, and
## connect autoload signals) is deliberately never called on these fresh
## instances; _config/unlock_pool are set up by hand instead.
##
## Unlike test_leaderboard_manager.gd's tests (which only ever READ
## manually-seeded _config state, never calling a method that saves),
## purchase_next_level()/add_renown() below genuinely call _config.save()
## as part of what's being tested — so every instance here gets its
## _save_path redirected to a dedicated throwaway file, never the real
## SAVE_PATH, to avoid actually writing fake renown/unlocks into the
## player's real save (see feedback_configfile_test_isolation memory).

const MetaProgressManagerScript := preload("res://src/autoload/meta_progress_manager.gd")
const LeaderboardManagerScript := preload("res://src/autoload/leaderboard_manager.gd")
const TEST_SAVE_PATH : String = "user://test_meta_progress_manager.cfg"


func suite_name() -> String:
	return "meta_progress_manager"


func _make_manager() -> MetaProgressManagerScript:
	var manager := MetaProgressManagerScript.new()
	manager._save_path = TEST_SAVE_PATH
	return manager


func _make_unlock(id : String, cost_per_level : int, max_level : int = 3, prerequisite_ids : Array[String] = []) -> MetaUnlockData:
	var unlock := MetaUnlockData.new()
	unlock.unlock_id = id
	unlock.renown_cost_per_level = cost_per_level
	unlock.max_level = max_level
	unlock.prerequisite_ids = prerequisite_ids
	return unlock


func test_calculate_renown_matches_leaderboard_score_scaled_down() -> void:
	var score : int = LeaderboardManagerScript.calculate_score(10, 20, 30)
	var expected : int = maxi(MetaProgressManagerScript.RENOWN_FLOOR, roundi(score / MetaProgressManagerScript.RENOWN_SCORE_DIVISOR))
	assert_eq(MetaProgressManagerScript.calculate_renown(10, 20, 30), expected)


func test_calculate_renown_floors_a_near_zero_score() -> void:
	assert_eq(MetaProgressManagerScript.calculate_renown(0, 0, 0), MetaProgressManagerScript.RENOWN_FLOOR)


func test_get_node_level_defaults_to_zero() -> void:
	var manager := _make_manager()
	manager.unlock_pool = [_make_unlock("cheap", 50)]
	assert_eq(manager.get_node_level("cheap"), 0)
	assert_false(manager.is_maxed("cheap"))


func test_purchase_next_level_fails_when_renown_is_insufficient() -> void:
	var manager := _make_manager()
	manager.unlock_pool = [_make_unlock("cheap", 50)]
	manager._config.set_value(MetaProgressManagerScript.SECTION, MetaProgressManagerScript.KEY_RENOWN, 10)

	assert_false(manager.purchase_next_level("cheap"))
	assert_eq(manager.get_node_level("cheap"), 0)
	assert_eq(manager.get_renown(), 10)


func test_purchase_next_level_spends_renown_and_increments_level() -> void:
	var manager := _make_manager()
	manager.unlock_pool = [_make_unlock("cheap", 50)]
	manager._config.set_value(MetaProgressManagerScript.SECTION, MetaProgressManagerScript.KEY_RENOWN, 80)

	assert_true(manager.purchase_next_level("cheap"))
	assert_eq(manager.get_node_level("cheap"), 1)
	assert_eq(manager.get_renown(), 30)


func test_purchase_next_level_can_buy_up_to_max_then_refuses() -> void:
	var manager := _make_manager()
	manager.unlock_pool = [_make_unlock("cheap", 50, 2)]
	manager._config.set_value(MetaProgressManagerScript.SECTION, MetaProgressManagerScript.KEY_RENOWN, 200)

	assert_true(manager.purchase_next_level("cheap"))
	assert_true(manager.purchase_next_level("cheap"))
	assert_eq(manager.get_node_level("cheap"), 2)
	assert_true(manager.is_maxed("cheap"))

	assert_false(manager.purchase_next_level("cheap"), "a node already at max_level should refuse a further purchase")
	assert_eq(manager.get_renown(), 100, "renown should only be spent for the two levels actually bought")


func test_purchase_next_level_refuses_an_unknown_id() -> void:
	var manager := _make_manager()
	manager.unlock_pool = [_make_unlock("cheap", 50)]
	manager._config.set_value(MetaProgressManagerScript.SECTION, MetaProgressManagerScript.KEY_RENOWN, 200)

	assert_false(manager.purchase_next_level("does_not_exist"))


func test_meets_prerequisites_true_for_a_root_node() -> void:
	var manager := _make_manager()
	manager.unlock_pool = [_make_unlock("root", 10)]
	assert_true(manager.meets_prerequisites("root"))


func test_meets_prerequisites_false_until_prerequisite_is_invested() -> void:
	var manager := _make_manager()
	manager.unlock_pool = [_make_unlock("root", 10), _make_unlock("child", 10, 3, ["root"])]
	assert_false(manager.meets_prerequisites("child"))


func test_meets_prerequisites_true_once_prerequisite_has_a_level() -> void:
	var manager := _make_manager()
	manager.unlock_pool = [_make_unlock("root", 10), _make_unlock("child", 10, 3, ["root"])]
	manager._config.set_value(MetaProgressManagerScript.SECTION, MetaProgressManagerScript.KEY_RENOWN, 100)

	manager.purchase_next_level("root")
	assert_true(manager.meets_prerequisites("child"))


## A capstone with two prerequisites needs BOTH invested, not just one —
## the converging-branch case (see e.g. bar_capstone_baarimestari.tres).
func test_meets_prerequisites_requires_every_listed_prerequisite() -> void:
	var manager := _make_manager()
	manager.unlock_pool = [
		_make_unlock("left", 10),
		_make_unlock("right", 10),
		_make_unlock("capstone", 10, 1, ["left", "right"]),
	]
	manager._config.set_value(MetaProgressManagerScript.SECTION, MetaProgressManagerScript.KEY_RENOWN, 100)

	manager.purchase_next_level("left")
	assert_false(manager.meets_prerequisites("capstone"), "only one of two prerequisites invested should not be enough")

	manager.purchase_next_level("right")
	assert_true(manager.meets_prerequisites("capstone"))


func test_purchase_next_level_refuses_when_prerequisite_unmet() -> void:
	var manager := _make_manager()
	manager.unlock_pool = [_make_unlock("root", 10), _make_unlock("child", 10, 3, ["root"])]
	manager._config.set_value(MetaProgressManagerScript.SECTION, MetaProgressManagerScript.KEY_RENOWN, 100)

	assert_false(manager.purchase_next_level("child"))
	assert_eq(manager.get_node_level("child"), 0)
	assert_eq(manager.get_renown(), 100, "a refused purchase should never spend renown")


func test_get_active_perks_scales_by_level() -> void:
	var manager := _make_manager()
	var node := _make_unlock("cheap", 10, 5)
	node.quality_bonus = 0.02
	manager.unlock_pool = [node]
	manager._config.set_value(MetaProgressManagerScript.SECTION, MetaProgressManagerScript.KEY_RENOWN, 100)

	manager.purchase_next_level("cheap")
	manager.purchase_next_level("cheap")

	var active := manager.get_active_perks()
	assert_eq(active.size(), 1)
	assert_true(is_equal_approx(active[0].quality_bonus, 0.04), "2 invested levels of a +0.02/level node should scale to +0.04")


## Direct coverage of MetaUnlockData.get_scaled_perk() for every field it's
## supposed to propagate — added after a real bug where 4 new fields
## (brew_yield_multiplier, ingredient_refund_chance, peak_speed_multiplier,
## decline_rate_multiplier) were added to RunPerk/MetaUnlockData and to
## shipped .tres resources, but get_scaled_perk() itself was never updated
## to copy them onto the returned RunPerk — so those nodes displayed
## correctly (the UI's own short-bonus formatter read the raw per-level
## unlock fields directly) but had ZERO actual gameplay effect, since
## Brewery.active_perks only ever sees get_scaled_perk()'s output. Caught
## only by a live screenshot showing "-" where a real number should have
## been. This test exists so a future new field added the same
## incomplete way fails immediately instead of silently doing nothing.
func test_get_scaled_perk_propagates_every_field() -> void:
	var unlock := MetaUnlockData.new()
	unlock.quality_bonus = 0.02
	unlock.reputation_gain_multiplier = 1.03
	unlock.tip_income_multiplier = 1.04
	unlock.raid_threshold_multiplier = 1.05
	unlock.distribution_income_multiplier = 1.06
	unlock.ingredient_price_multiplier = 0.97
	unlock.brew_yield_multiplier = 1.08
	unlock.ingredient_refund_chance = 0.1
	unlock.peak_speed_multiplier = 0.9
	unlock.decline_rate_multiplier = 0.85
	unlock.spawn_interval_multiplier = 0.96
	unlock.agentti_appearance_multiplier = 0.92
	unlock.mafioso_appearance_multiplier = 1.12
	unlock.tip_double_chance = 0.05
	unlock.bar_fight_chance_multiplier = 0.9
	unlock.counter_price_multiplier = 1.03
	unlock.group_event_interval_multiplier = 0.94
	unlock.extra_raid_strikes = 1
	unlock.raid_hidden_batch_count = 1

	var scaled := unlock.get_scaled_perk(2)

	assert_true(is_equal_approx(scaled.quality_bonus, 0.04), "quality_bonus")
	assert_true(is_equal_approx(scaled.reputation_gain_multiplier, 1.06), "reputation_gain_multiplier")
	assert_true(is_equal_approx(scaled.tip_income_multiplier, 1.08), "tip_income_multiplier")
	assert_true(is_equal_approx(scaled.raid_threshold_multiplier, 1.10), "raid_threshold_multiplier")
	assert_true(is_equal_approx(scaled.distribution_income_multiplier, 1.12), "distribution_income_multiplier")
	assert_true(is_equal_approx(scaled.ingredient_price_multiplier, 0.94), "ingredient_price_multiplier")
	assert_true(is_equal_approx(scaled.brew_yield_multiplier, 1.16), "brew_yield_multiplier")
	assert_true(is_equal_approx(scaled.ingredient_refund_chance, 0.2), "ingredient_refund_chance")
	assert_true(is_equal_approx(scaled.peak_speed_multiplier, 0.8), "peak_speed_multiplier")
	assert_true(is_equal_approx(scaled.decline_rate_multiplier, 0.7), "decline_rate_multiplier")
	assert_true(is_equal_approx(scaled.spawn_interval_multiplier, 0.92), "spawn_interval_multiplier")
	assert_true(is_equal_approx(scaled.agentti_appearance_multiplier, 0.84), "agentti_appearance_multiplier")
	assert_true(is_equal_approx(scaled.mafioso_appearance_multiplier, 1.24), "mafioso_appearance_multiplier")
	assert_true(is_equal_approx(scaled.tip_double_chance, 0.1), "tip_double_chance")
	assert_true(is_equal_approx(scaled.bar_fight_chance_multiplier, 0.8), "bar_fight_chance_multiplier")
	assert_true(is_equal_approx(scaled.counter_price_multiplier, 1.06), "counter_price_multiplier")
	assert_true(is_equal_approx(scaled.group_event_interval_multiplier, 0.88), "group_event_interval_multiplier")
	assert_eq(scaled.extra_raid_strikes, 2, "extra_raid_strikes")
	assert_eq(scaled.raid_hidden_batch_count, 2, "raid_hidden_batch_count")


func test_get_active_perks_omits_nodes_with_no_investment() -> void:
	var manager := _make_manager()
	manager.unlock_pool = [_make_unlock("cheap", 10), _make_unlock("pricey", 500)]
	manager._config.set_value(MetaProgressManagerScript.SECTION, MetaProgressManagerScript.KEY_RENOWN, 100)

	manager.purchase_next_level("cheap")
	assert_eq(manager.get_active_perks().size(), 1)


## Every shipped MetaUnlockData needs a non-empty, unique unlock_id — a
## duplicate would let two different nodes silently share one purchase
## flag, and an empty one would collide with every other empty-id node.
## Also enforces the "1 to 5 points per node" design requirement, which
## nothing in-engine otherwise clamps.
func test_shipped_meta_unlocks_have_unique_nonempty_ids_and_valid_levels() -> void:
	var dir := DirAccess.open("res://src/resources/meta_unlocks/")
	assert_true(dir != null, "meta_unlocks folder should exist")

	var seen_ids : Array[String] = []
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var unlock : MetaUnlockData = load("res://src/resources/meta_unlocks/" + file_name)
			assert_false(unlock.unlock_id.is_empty(), "%s: unlock_id is empty" % file_name)
			assert_false(seen_ids.has(unlock.unlock_id), "%s: duplicate unlock_id '%s'" % [file_name, unlock.unlock_id])
			seen_ids.append(unlock.unlock_id)
			assert_true(unlock.renown_cost_per_level > 0, "%s: renown_cost_per_level should be positive" % file_name)
			assert_true(unlock.max_level >= 1 and unlock.max_level <= 5, "%s: max_level should be 1-5, was %d" % [file_name, unlock.max_level])
		file_name = dir.get_next()
	dir.list_dir_end()

	assert_true(seen_ids.size() >= 18, "expected at least the 18 shipped meta unlocks (6 per path), found %d" % seen_ids.size())


## Every prerequisite_id referenced anywhere must actually exist as a
## shipped node — a typo'd id would silently make a node permanently
## unreachable (meets_prerequisites() only ever sees get_node_level() of
## an id nobody can ever invest in) instead of throwing anywhere obvious.
func test_shipped_meta_unlocks_have_no_dangling_prerequisites() -> void:
	var dir := DirAccess.open("res://src/resources/meta_unlocks/")
	assert_true(dir != null, "meta_unlocks folder should exist")

	var all_unlocks : Array[MetaUnlockData] = []
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			all_unlocks.append(load("res://src/resources/meta_unlocks/" + file_name))
		file_name = dir.get_next()
	dir.list_dir_end()

	var known_ids : Array[String] = []
	for unlock : MetaUnlockData in all_unlocks:
		known_ids.append(unlock.unlock_id)

	for unlock : MetaUnlockData in all_unlocks:
		for prereq_id : String in unlock.prerequisite_ids:
			assert_true(known_ids.has(prereq_id), "%s: prerequisite_id '%s' does not match any shipped unlock_id" % [unlock.unlock_id, prereq_id])


## Every shipped path needs exactly one root node (empty prerequisite_ids)
## to anchor its tree — more than one would mean two disconnected trees
## drawn in the same column, and zero would mean nothing in that path is
## ever purchasable at all.
func test_shipped_meta_unlocks_have_one_root_per_path() -> void:
	var dir := DirAccess.open("res://src/resources/meta_unlocks/")
	assert_true(dir != null, "meta_unlocks folder should exist")

	var root_counts : Dictionary = {}
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var unlock : MetaUnlockData = load("res://src/resources/meta_unlocks/" + file_name)
			if unlock.prerequisite_ids.is_empty():
				root_counts[unlock.path] = root_counts.get(unlock.path, 0) + 1
		file_name = dir.get_next()
	dir.list_dir_end()

	for path : MetaUnlockData.Path in [MetaUnlockData.Path.BAR_WORK, MetaUnlockData.Path.BREWING, MetaUnlockData.Path.MARKETING]:
		assert_eq(root_counts.get(path, 0), 1, "path %d should have exactly one root node, found %d" % [path, root_counts.get(path, 0)])


## Every shipped path (Baarityöskentely/Oluenpanotaito/Markkinointi) needs
## at least one node, or Olutoppi's tree would show an empty column.
func test_shipped_meta_unlocks_cover_every_path() -> void:
	var dir := DirAccess.open("res://src/resources/meta_unlocks/")
	assert_true(dir != null, "meta_unlocks folder should exist")

	var seen_paths : Dictionary = {}
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var unlock : MetaUnlockData = load("res://src/resources/meta_unlocks/" + file_name)
			seen_paths[unlock.path] = true
		file_name = dir.get_next()
	dir.list_dir_end()

	assert_true(seen_paths.has(MetaUnlockData.Path.BAR_WORK), "no shipped node for BAR_WORK")
	assert_true(seen_paths.has(MetaUnlockData.Path.BREWING), "no shipped node for BREWING")
	assert_true(seen_paths.has(MetaUnlockData.Path.MARKETING), "no shipped node for MARKETING")
