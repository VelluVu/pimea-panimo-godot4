@tool
extends McpTestSuite

## Unit tests for KettleMouth: the hole, rim and inner wall in the kettle's art pixels.

const KettleMouthScript := preload("res://src/ui/brew_day/kettle_mouth.gd")


func suite_name() -> String:
	return "kettle_mouth"


## A 9 x 7 "kettle": opaque everywhere but a 5 x 3 hole at (2, 2) and an empty top row.
func _art() -> Image:
	var art := Image.create(9, 7, false, Image.FORMAT_RGBA8)
	art.fill(Color.GRAY)
	for x : int in 9:
		art.set_pixel(x, 0, Color.TRANSPARENT)
	for y : int in range(2, 5):
		for x : int in range(2, 7):
			art.set_pixel(x, y, Color.TRANSPARENT)
	return art


func test_the_hole_is_only_the_enclosed_cells() -> void:
	var hole : Array[Vector2i] = KettleMouthScript.hole_cells(_art())
	assert_eq(hole.size(), 15)
	assert_false(hole.has(Vector2i(4, 0)), "the air above is not the hole")


func test_the_rim_rings_the_hole() -> void:
	var art := _art()
	var rim : Array[Vector2i] = KettleMouthScript.rim_cells(art, KettleMouthScript.hole_cells(art))
	assert_eq(rim.size(), 16)
	assert_true(rim.has(Vector2i(4, 1)) and rim.has(Vector2i(1, 3)) and rim.has(Vector2i(4, 5)))
	assert_false(rim.has(Vector2i(1, 1)), "corners only touch diagonally")


func test_no_wall_shows_when_the_liquid_fills_the_hole() -> void:
	var hole : Array[Vector2i] = KettleMouthScript.hole_cells(_art())
	assert_eq(KettleMouthScript.wall_cells(hole, Rect2(1, 1, 7, 5)).size(), 0)


func test_a_lowered_liquid_shows_the_back_wall() -> void:
	var hole : Array[Vector2i] = KettleMouthScript.hole_cells(_art())
	var wall : Array[Vector2i] = KettleMouthScript.wall_cells(hole, Rect2(1, 3, 7, 5))
	assert_true(wall.has(Vector2i(4, 2)), str(wall))
	for cell : Vector2i in wall:
		assert_eq(cell.y, 2, "only the top row is above the waterline")
