@tool
extends McpTestSuite

## Unit tests for KegTunnel: the opening's ellipse and how deep in the keg a point is.

const KegTunnelScript := preload("res://src/brewery/keg_wash/keg_tunnel.gd")


func suite_name() -> String:
	return "keg_tunnel"


func test_reach_is_zero_at_the_centre_and_one_on_the_edge() -> void:
	assert_eq(KegTunnelScript.reach(KegTunnelScript.OPENING_CENTER), 0.0)
	var edge : Vector2 = KegTunnelScript.OPENING_CENTER + Vector2(KegTunnelScript.OPENING_RADII.x, 0.0)
	assert_true(is_equal_approx(KegTunnelScript.reach(edge), 1.0))


func test_the_ellipse_is_wider_than_it_is_tall() -> void:
	var side : Vector2 = KegTunnelScript.OPENING_CENTER + Vector2(KegTunnelScript.OPENING_RADII.y + 1.0, 0.0)
	var below : Vector2 = KegTunnelScript.OPENING_CENTER + Vector2(0.0, KegTunnelScript.OPENING_RADII.y + 1.0)
	assert_true(KegTunnelScript.is_inside(side))
	assert_false(KegTunnelScript.is_inside(below))


func test_point_at_lands_at_the_asked_share_of_the_reach() -> void:
	for angle : float in [0.0, 1.0, 2.5, 4.0]:
		var point : Vector2 = KegTunnelScript.point_at(angle, KegTunnelScript.SPOT_REACH)
		assert_true(is_equal_approx(KegTunnelScript.reach(point), KegTunnelScript.SPOT_REACH))


func test_the_far_bottom_is_full_depth() -> void:
	assert_eq(KegTunnelScript.depth(KegTunnelScript.BOTTOM_CENTER), 1.0)
	var bottom_edge : Vector2 = KegTunnelScript.BOTTOM_CENTER + Vector2(KegTunnelScript.BOTTOM_RADII.x, 0.0)
	assert_true(is_equal_approx(KegTunnelScript.depth(bottom_edge), 1.0))


func test_depth_fades_out_towards_the_rim() -> void:
	var part_way : Vector2 = KegTunnelScript.BOTTOM_CENTER + Vector2(KegTunnelScript.BOTTOM_RADII.x * 1.7, 0.0)
	var depth : float = KegTunnelScript.depth(part_way)
	assert_gt(depth, 0.0)
	assert_gt(1.0, depth)
	assert_eq(KegTunnelScript.depth(KegTunnelScript.BOTTOM_CENTER + Vector2(KegTunnelScript.BOTTOM_RADII.x * 3.0, 0.0)), 0.0)
