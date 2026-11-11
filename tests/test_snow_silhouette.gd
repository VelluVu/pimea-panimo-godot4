@tool
extends McpTestSuite

## Unit tests for SnowSilhouette: which pixels of a sprite frame snow settles on.

const SnowSilhouetteScript := preload("res://src/customers/effects/snow_silhouette.gd")


func suite_name() -> String:
	return "snow_silhouette"


func _image(width : int, height : int, opaque : Array[Vector2i]) -> Image:
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	for cell in opaque:
		image.set_pixelv(cell, Color.WHITE)
	return image


func test_snow_sits_on_the_top_pixel_of_each_column() -> void:
	var tops : PackedInt32Array = SnowSilhouetteScript.top_edge(_image(3, 6, [Vector2i(0, 4), Vector2i(1, 2), Vector2i(1, 3), Vector2i(2, 5)]))
	assert_eq(tops[0], 4)
	assert_eq(tops[1], 2)
	assert_eq(tops[2], 5)


func test_an_empty_column_holds_no_snow() -> void:
	var tops : PackedInt32Array = SnowSilhouetteScript.top_edge(_image(2, 4, [Vector2i(0, 1)]))
	assert_eq(tops[1], -1)


func test_a_column_far_below_the_head_holds_no_snow() -> void:
	var drop : int = SnowSilhouetteScript.MAX_DROP_ROWS
	var image := _image(3, drop + 4, [Vector2i(0, 1), Vector2i(1, 1 + drop), Vector2i(2, 2 + drop)])
	var tops : PackedInt32Array = SnowSilhouetteScript.top_edge(image)
	assert_eq(tops[1], 1 + drop)
	assert_eq(tops[2], -1)


func test_see_through_pixels_are_not_the_top() -> void:
	var image := _image(1, 4, [Vector2i(0, 3)])
	image.set_pixel(0, 1, Color(1.0, 1.0, 1.0, 0.2))
	assert_eq(SnowSilhouetteScript.top_edge(image)[0], 3)
