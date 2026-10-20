@tool
extends McpTestSuite


func suite_name() -> String:
	return "character_bust"


func test_region_starts_above_the_head_centred_on_the_figure() -> void:
	var region : Rect2i = CharacterBust.bust_region(Rect2i(10, 4, 12, 26), Vector2i(32, 32), 20)
	assert_eq(region, Rect2i(6, 3, 20, 20))


func test_region_is_clipped_to_the_frame() -> void:
	var region : Rect2i = CharacterBust.bust_region(Rect2i(0, 0, 4, 30), Vector2i(32, 32), 20)
	assert_eq(region, Rect2i(0, 0, 12, 19))


func test_empty_frame_gives_no_region() -> void:
	assert_false(CharacterBust.bust_region(Rect2i(), Vector2i(32, 32), 20).has_area())


func test_crop_has_the_bust_size() -> void:
	var image : Image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill_rect(Rect2i(10, 4, 12, 26), Color.WHITE)
	var bust : Texture2D = CharacterBust.of(ImageTexture.create_from_image(image))
	assert_eq(bust.get_size(), Vector2(20, 20))
