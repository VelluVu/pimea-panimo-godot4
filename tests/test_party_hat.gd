extends McpTestSuite

const PartyHatScript := preload("res://src/customers/effects/party_hat.gd")


func suite_name() -> String:
	return "party_hat"


## A 32x32 frame with a 10 px wide head from x 10 (to 20) starting at row 5, and a one-pixel
## tuft at x 19 on row 4.
func _frame() -> Image:
	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill_rect(Rect2i(10, 5, 10, 20), Color.WHITE)
	image.set_pixel(19, 4, Color.WHITE)
	return image


func test_the_head_top_is_the_first_row_and_the_heads_middle() -> void:
	assert_eq(PartyHatScript.head_top(_frame()), Vector2i(15, 4), "the tuft sets the row, the head under it the middle")


func test_an_empty_frame_keeps_the_hat_in_the_middle() -> void:
	assert_eq(PartyHatScript.head_top(Image.create(32, 32, false, Image.FORMAT_RGBA8)), Vector2i(16, 0))


func test_the_hat_sinks_into_the_hair_and_mirrors_with_the_frame() -> void:
	var texture := ImageTexture.create_from_image(_frame())
	var offset := Vector2(-16, -32)
	assert_eq(PartyHatScript.position_for(texture, offset, false), offset + Vector2(12, 4 - 8 + 1))
	assert_eq(PartyHatScript.position_for(texture, offset, true), offset + Vector2(14, 4 - 8 + 1))
