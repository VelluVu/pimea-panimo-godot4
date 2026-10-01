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


func test_frame_index_wraps_around_the_table() -> void:
	assert_eq(HandOffsetsScript.position_for("", 4), HandOffsetsScript.DEFAULT_OFFSETS[0])
