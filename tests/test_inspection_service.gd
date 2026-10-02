@tool
extends McpTestSuite

## Unit tests for InspectionService.raid_fine() and early_close_escalation().

const ServiceScript := preload("res://src/brewery/inspection_service.gd")


func suite_name() -> String:
	return "inspection_service"


func test_fine_is_a_share_of_money_times_escalation() -> void:
	assert_eq(ServiceScript.raid_fine(100.0, 2.0), 60.0)


func test_fine_is_capped() -> void:
	assert_eq(ServiceScript.raid_fine(2000.0, 3.0), ServiceScript.LVV_RAID_FINE_MAX)


func test_debt_is_never_fined_into_a_payout() -> void:
	assert_eq(ServiceScript.raid_fine(-50.0, 1.0), 0.0)


func test_early_close_cost_grows_with_each_close() -> void:
	assert_eq(ServiceScript.early_close_escalation(0), 1.0)
	assert_eq(ServiceScript.early_close_escalation(2), 2.0)


func test_early_close_cost_stops_growing_at_the_cap() -> void:
	assert_eq(ServiceScript.early_close_escalation(20), ServiceScript.EARLY_CLOSE_MAX_ESCALATION)


func test_saved_bottles_round_down() -> void:
	assert_eq(ServiceScript.saved_bottles(45, 0.08), 3)
	assert_eq(ServiceScript.saved_bottles(45, 0.0), 0)


func test_saved_bottles_share_is_capped() -> void:
	assert_eq(ServiceScript.saved_bottles(45, 1.5), 45)
