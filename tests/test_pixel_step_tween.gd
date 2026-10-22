@tool
extends McpTestSuite

## PixelStepTween's grid: whole steps from the start, exact landing on the target.

const PixelStepTweenScript := preload("res://src/systems/toolkit/pixel_step_tween.gd")


func suite_name() -> String:
	return "pixel_step_tween"


func test_positions_snap_to_whole_steps_from_the_start() -> void:
	var from := Vector2(10, 20)
	var to := Vector2(30, 20)
	assert_eq(PixelStepTweenScript.snapped_on_path(from, to, Vector2(11.9, 20), 4.0), Vector2(10, 20))
	assert_eq(PixelStepTweenScript.snapped_on_path(from, to, Vector2(12.1, 20), 4.0), Vector2(14, 20))
	assert_eq(PixelStepTweenScript.snapped_on_path(from, to, Vector2(25.0, 20), 4.0), Vector2(26, 20))


func test_end_lands_on_the_target_even_off_the_grid() -> void:
	var to := Vector2(31, 20)
	assert_eq(PixelStepTweenScript.snapped_on_path(Vector2(10, 20), to, to, 4.0), to)


func test_fractional_start_still_draws_on_whole_pixels() -> void:
	var at : Vector2 = PixelStepTweenScript.snapped_on_path(Vector2(10.4, 20.6), Vector2(50, 20.6), Vector2(13.3, 20.6), 1.0)
	assert_eq(at, Vector2(13, 21))


func test_tween_moves_the_node_on_the_grid() -> void:
	var node := Node2D.new()
	var tween : Tween = (Engine.get_main_loop() as SceneTree).create_tween()
	PixelStepTweenScript.move(tween, node, Vector2.ZERO, Vector2(10, 0), 1.0, 4.0)
	tween.pause()
	tween.custom_step(0.55)
	assert_eq(node.position, Vector2(4, 0))
	tween.custom_step(1.0)
	assert_eq(node.position, Vector2(10, 0))
	node.free()


func test_a_property_moves_on_whole_pixels() -> void:
	var label := Label.new()
	var tween : Tween = (Engine.get_main_loop() as SceneTree).create_tween()
	PixelStepTweenScript.move_property(tween, label, &"position", Vector2(0, 0), Vector2(0, -7), 1.0)
	tween.pause()
	tween.custom_step(0.6)
	assert_eq(label.position, Vector2(0, -4))
	tween.custom_step(1.0)
	assert_eq(label.position, Vector2(0, -7))
	label.free()
