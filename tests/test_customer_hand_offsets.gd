@tool
extends McpTestSuite

## Unit tests for CustomerHandOffsets, the per-archetype held-glass positions
## used while a customer walks away with a beer.

const HandOffsetsScript := preload("res://src/customers/customer_hand_offsets.gd")


func suite_name() -> String:
	return "customer_hand_offsets"


func test_unknown_title_uses_the_default_table() -> void:
	assert_eq(HandOffsetsScript.position_for("Tuntematon", 1), HandOffsetsScript.DEFAULT_OFFSETS[1])


func test_special_titles_use_their_own_tables() -> void:
	assert_eq(HandOffsetsScript.position_for(HandOffsetsScript.ZGEN_TITLE, 0), HandOffsetsScript.ZGEN_OFFSETS[0])
	assert_eq(HandOffsetsScript.position_for(HandOffsetsScript.RAKSAMIES_TITLE, 3), HandOffsetsScript.RAKSAMIES_OFFSETS[3])
	assert_eq(HandOffsetsScript.position_for(HandOffsetsScript.LEIJONAFANI_TITLE, 1), HandOffsetsScript.LEIJONAFANI_OFFSETS[1])
	assert_eq(HandOffsetsScript.position_for(HandOffsetsScript.DRONE_TITLE, 1), HandOffsetsScript.DRONE_OFFSETS[1])


## Fails if the drone is renamed in its .tres and its table silently falls back to the default.
func test_drone_title_matches_its_resource() -> void:
	assert_eq((load("res://src/resources/customers/drone.tres") as CustomerData).title, HandOffsetsScript.DRONE_TITLE)


## The praying customers' tables are keyed by title, so a renamed .tres would drop the glass
## back to the default hand.
func test_praying_titles_match_their_resources() -> void:
	assert_eq((load("res://src/resources/customers/munkki.tres") as CustomerData).title, HandOffsetsScript.MUNKKI_TITLE)
	assert_eq((load("res://src/resources/customers/halloweeni_vieras.tres") as CustomerData).title, HandOffsetsScript.KURPITSAPAA_TITLE)


func test_tarjoushaukka_titles_match_their_resources() -> void:
	for file : String in ["tarjoushaukka.tres", "tarjoushaukka_naaras.tres"]:
		assert_eq((load("res://src/resources/customers/" + file) as CustomerData).title, HandOffsetsScript.TARJOUSHAUKKA_TITLE)


func test_kyborgi_title_matches_its_resource() -> void:
	assert_eq((load("res://src/resources/customers/kyborgi.tres") as CustomerData).title, HandOffsetsScript.KYBORGI_TITLE)


func test_only_tarjoushaukka_bags_the_glass() -> void:
	assert_eq(HandOffsetsScript.glass_region_for(HandOffsetsScript.TARJOUSHAUKKA_TITLE), HandOffsetsScript.BAGGED_GLASS_REGION)
	assert_false(HandOffsetsScript.glass_region_for(HandOffsetsScript.ZGEN_TITLE).has_area())
	assert_false(HandOffsetsScript.glass_region_for("").has_area())


func test_praying_customers_hold_the_glass_at_the_middle() -> void:
	for frame : int in 4:
		assert_eq(HandOffsetsScript.position_for(HandOffsetsScript.MUNKKI_TITLE, frame).x, 0.0)
		assert_eq(HandOffsetsScript.position_for(HandOffsetsScript.KURPITSAPAA_TITLE, frame).x, 0.0)


func test_frame_index_wraps_around_the_table() -> void:
	assert_eq(HandOffsetsScript.position_for("", 4), HandOffsetsScript.DEFAULT_OFFSETS[0])


## A customer's own table wins over its title's, so the small tonttu holds the glass lower.
func test_own_offsets_override_the_title_table() -> void:
	var own : Array[Vector2] = [Vector2(22, -14), Vector2(22, -22)]
	assert_eq(HandOffsetsScript.position_for(HandOffsetsScript.MUNKKI_TITLE, 1, own), Vector2(22, -22))
	assert_eq(HandOffsetsScript.position_for("", 2, own), Vector2(22, -14))


func test_glass_flips_only_on_listed_frames() -> void:
	var flipped : Array[int] = [3]
	assert_true(HandOffsetsScript.is_flipped(3, flipped, 4))
	assert_true(HandOffsetsScript.is_flipped(7, flipped, 4))
	assert_false(HandOffsetsScript.is_flipped(1, flipped, 4))
	assert_false(HandOffsetsScript.is_flipped(3, [] as Array[int], 4))


func test_every_tonttu_has_its_own_hand_offsets() -> void:
	for name : String in ["harmaa", "sydan", "punainen"]:
		var tonttu : CustomerData = load("res://src/resources/customers/tonttu_%s.tres" % name)
		assert_eq(tonttu.hand_offsets.size(), 4, name)
		assert_true(tonttu.sprite_frames.has_animation(&"walk_towards"), name)
