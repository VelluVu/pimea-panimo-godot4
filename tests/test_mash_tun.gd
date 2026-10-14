@tool
extends McpTestSuite

## Unit tests for MashTun: how much malt one brew can hold.

const MashTunScript := preload("res://src/brewing/mash_tun.gd")


func suite_name() -> String:
	return "mash_tun"


func test_capacity_grows_with_the_upgrade() -> void:
	assert_eq(MashTunScript.capacity_kg(0), MashTunScript.BASE_CAPACITY_KG)
	assert_eq(MashTunScript.capacity_kg(4), MashTunScript.BASE_CAPACITY_KG + 4.0)


func test_a_full_tun_still_holds() -> void:
	assert_true(MashTunScript.holds(6.0, 6.0))
	assert_false(MashTunScript.holds(6.1, 6.0))


func test_packs_adding_up_to_the_limit_still_fit() -> void:
	# Ten 100 g packs summed in floats land a hair over 1.0.
	var kg : float = 5.0
	for i : int in 10:
		kg += 0.1
	assert_true(MashTunScript.holds(kg, 6.0))
