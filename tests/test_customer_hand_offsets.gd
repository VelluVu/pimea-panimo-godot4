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


## The 8x7 bucket at 4x: its corner must sit on a multiple of 4 like the body's pixels.
func test_held_item_snaps_to_the_body_pixel_grid() -> void:
	var on_grid : Vector2 = HandOffsetsScript.snap_to_art_grid(Vector2(-31, -40), Vector2(8, 7), 4.0)
	assert_eq(on_grid, Vector2(-32, -42))
	var corner : Vector2 = on_grid - Vector2(16, 14)
	assert_eq(fposmod(corner.x, 4.0), 0.0)
	assert_eq(fposmod(corner.y, 4.0), 0.0)


func test_held_item_on_the_grid_stays_put() -> void:
	assert_eq(HandOffsetsScript.snap_to_art_grid(Vector2(-28, -34), Vector2(8, 7), 4.0), Vector2(-28, -34))


func test_walk_out_uses_the_carrying_walk_only_with_a_glass_and_a_sheet_that_has_it() -> void:
	var with_row := SpriteFrames.new()
	with_row.add_animation(HandOffsetsScript.CARRYING_WALK)
	var without_row := SpriteFrames.new()
	assert_eq(HandOffsetsScript.walk_out_animation(with_row, true, &"walk_towards"), HandOffsetsScript.CARRYING_WALK)
	assert_eq(HandOffsetsScript.walk_out_animation(with_row, false, &"walk_towards"), &"walk_towards")
	assert_eq(HandOffsetsScript.walk_out_animation(without_row, true, &"walk_towards"), &"walk_towards")
	assert_eq(HandOffsetsScript.walk_out_animation(null, true, &"walk_towards"), &"walk_towards")


## His sword hand is free only on the carrying row, so the glass needs both.
func test_ritari_carries_the_glass_on_his_own_row() -> void:
	var ritari : CustomerData = load("res://src/resources/customers/ritari.tres")
	assert_true(ritari.carries_glass_out)
	assert_eq(ritari.hand_offsets.size(), 4)
	assert_true(ritari.sprite_frames.has_animation(HandOffsetsScript.CARRYING_WALK))


## Sword and shield stay on the sides his sheet draws them: both walks have unflipped frames.
func test_ritari_is_not_flipped_walking_towards_the_camera() -> void:
	var frames : SpriteFrames = (load("res://src/resources/customers/ritari.tres") as CustomerData).sprite_frames
	assert_true(frames.has_animation(&"walk_towards_mirrored"))
	assert_true(frames.has_animation(StringName(String(HandOffsetsScript.CARRYING_WALK) + MirroredAnimation.SUFFIX)))


## Flipping the walk would swap the hand that holds their briefcase, rifle or vihta.
func test_one_handed_customers_are_not_flipped_walking_towards_the_camera() -> void:
	for name : String in ["lottovoittaja", "sovittelija", "sovittelija_naaras", "metsastaja", "metsastaja_naaras",
			"pubivisailija", "pubivisailija_naaras", "saunamies", "saunanainen", "snobi", "joulupukki", "persuasiakas"]:
		var data : CustomerData = load("res://src/resources/customers/%s.tres" % name)
		assert_true(data.sprite_frames.has_animation(&"walk_towards_mirrored"), name)


func test_every_tonttu_has_its_own_hand_offsets() -> void:
	for name : String in ["harmaa", "sydan", "punainen"]:
		var tonttu : CustomerData = load("res://src/resources/customers/tonttu_%s.tres" % name)
		assert_eq(tonttu.hand_offsets.size(), 4, name)
		assert_true(tonttu.sprite_frames.has_animation(&"walk_towards"), name)
