@tool
extends McpTestSuite

## Unit tests for ReputationFavourEventData's offer gate.

const FavourScript := preload("res://src/events/reputation_favour_event_data.gd")


func suite_name() -> String:
	return "reputation_favour_event_data"


func test_favour_is_never_offered_below_its_cost() -> void:
	assert_eq(FavourScript.affordable_weight(19, 20, 3.0), 0.0)


func test_favour_keeps_its_weight_once_affordable() -> void:
	assert_eq(FavourScript.affordable_weight(20, 20, 3.0), 3.0)
	assert_eq(FavourScript.affordable_weight(150, 20, 1.0), 1.0)
