@tool
extends McpTestSuite

const StatChipScript := preload("res://src/ui/stat_chip.gd")

var _chips : Array[Node] = []


func suite_name() -> String:
	return "stat_chip"


func teardown() -> void:
	for chip : Node in _chips:
		chip.queue_free()
	_chips.clear()


func _chip(meter : int = 0) -> Node:
	var chip : Node = StatChipScript.new()
	chip.set(&"meter", meter)
	(Engine.get_main_loop() as SceneTree).root.add_child(chip)
	_chips.append(chip)
	return chip


func test_value_shows_on_the_label() -> void:
	var chip : Node = _chip()
	chip.set_value("186,40 €")
	assert_eq(chip.value_label().text, "186,40 €")


func test_meter_clamps_to_full() -> void:
	var chip : Node = _chip(StatChipScript.Meter.BEER)
	chip.set_meter(1.6)
	assert_eq(chip.meter_value(), 1.0)
	chip.set_meter(-0.2)
	assert_eq(chip.meter_value(), 0.0)


func test_chip_without_meter_ignores_it() -> void:
	var chip : Node = _chip()
	chip.set_meter(0.5)
	assert_eq(chip.meter_value(), 0.0)


func test_icon_picks_its_frame_from_the_sheet() -> void:
	var chip : Node = _chip()
	chip.set_icon(StatChipScript.TopBarIcon.SIREN_ON)
	var atlas : AtlasTexture = chip._icon_atlas
	assert_eq(atlas.region, Rect2(0, 27, 9, 9))


func test_clear_colour_returns_to_the_theme_colour() -> void:
	var chip : Node = _chip()
	chip.set_value_color(Color.RED)
	assert_true(chip.value_label().has_theme_color_override(&"font_color"))
	chip.set_value_color(Color(0, 0, 0, 0))
	assert_false(chip.value_label().has_theme_color_override(&"font_color"))
