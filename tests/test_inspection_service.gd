@tool
extends McpTestSuite

## Unit tests for InspectionService.raid_fine().

const ServiceScript := preload("res://src/brewery/inspection_service.gd")


func suite_name() -> String:
	return "inspection_service"


func test_fine_is_a_share_of_money_times_escalation() -> void:
	assert_eq(ServiceScript.raid_fine(100.0, 2.0), 60.0)


func test_fine_is_capped() -> void:
	assert_eq(ServiceScript.raid_fine(2000.0, 3.0), ServiceScript.LVV_RAID_FINE_MAX)


func test_debt_is_never_fined_into_a_payout() -> void:
	assert_eq(ServiceScript.raid_fine(-50.0, 1.0), 0.0)
