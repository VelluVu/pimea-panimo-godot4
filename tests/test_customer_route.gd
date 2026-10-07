@tool
extends McpTestSuite

const CustomerRouteScript := preload("res://src/customers/customer_route.gd")


func suite_name() -> String:
	return "customer_route"


func test_a_half_done_descent_has_half_its_steps_left() -> void:
	assert_eq(CustomerRouteScript.stair_steps_left(Vector2(0, 0), Vector2(0, 100), Vector2(0, 50), 15), 8)


func test_the_last_bit_of_stairs_is_still_one_step() -> void:
	assert_eq(CustomerRouteScript.stair_steps_left(Vector2(0, 0), Vector2(0, 100), Vector2(0, 99), 15), 1)


func test_at_the_bottom_no_steps_are_left() -> void:
	assert_eq(CustomerRouteScript.stair_steps_left(Vector2(0, 0), Vector2(0, 100), Vector2(0, 100), 15), 0)


func test_the_rest_of_a_walk_takes_its_share_of_time() -> void:
	assert_true(is_equal_approx(CustomerRouteScript.seconds_left(Vector2(0, 0), Vector2(30, 40), 25.0), 2.0))
