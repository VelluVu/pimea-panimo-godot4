@tool
extends McpTestSuite

const CustomerSwayScript := preload("res://src/customers/customer_sway.gd")
const TipsyRulesScript := preload("res://src/customers/tipsy_rules.gd")


func suite_name() -> String:
	return "customer_sway"


func test_a_sober_customer_never_sways() -> void:
	var sway := CustomerSwayScript.new()
	assert_false(sway.tick(0.3, 4.0))
	assert_eq(sway.x, 0.0)


func test_a_tipsy_customer_moves_whole_art_pixels() -> void:
	var sway := CustomerSwayScript.new()
	sway.steps = 2
	# A quarter wave in, the sway is at its widest.
	var quarter : float = 0.25 / TipsyRulesScript.SWAY_HZ
	assert_true(sway.tick(quarter, 4.0))
	assert_eq(sway.x, 8.0)


func test_no_move_means_nothing_to_place() -> void:
	var sway := CustomerSwayScript.new()
	sway.steps = 2
	var quarter : float = 0.25 / TipsyRulesScript.SWAY_HZ
	sway.tick(quarter, 4.0)
	assert_false(sway.tick(0.0, 4.0))
