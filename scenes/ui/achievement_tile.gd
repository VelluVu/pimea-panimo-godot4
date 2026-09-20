class_name AchievementTile
extends PanelContainer

## One cell of the achievements grid: a placeholder icon as header and the
## title below it. The description and progress live in the tooltip. Built in
## code by AchievementsWindow. Locked achievements are dimmed.

const TILE_SIZE: Vector2 = Vector2(100, 68)
const ICON_SIZE: Vector2 = Vector2(28, 28)
const ICON_CORNER_RADIUS: int = 6
const TITLE_FONT_SIZE: int = 11
const UNLOCKED_ICON_GLYPH: String = "!"
const LOCKED_ICON_GLYPH: String = "?"
const UNLOCKED_COLOR: Color = Color(0.95, 0.79, 0.42)
const LOCKED_COLOR: Color = Color(0.45, 0.45, 0.45)
const UNLOCKED_TOOLTIP_FORMAT: String = "%s\n%s\nAvattu"
const LOCKED_TOOLTIP_FORMAT: String = "%s\n%s\nEdistyminen: %d/%d"


func setup(achievement: AchievementData, unlocked: bool, progress: int) -> void:
	custom_minimum_size = TILE_SIZE
	var color: Color = UNLOCKED_COLOR if unlocked else LOCKED_COLOR
	modulate = Color.WHITE if unlocked else Color(1, 1, 1, 0.8)

	if unlocked:
		tooltip_text = UNLOCKED_TOOLTIP_FORMAT % [achievement.title, achievement.description]
	else:
		tooltip_text = LOCKED_TOOLTIP_FORMAT % [achievement.title, achievement.description, progress, achievement.target_value]

	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 4)
	add_child(column)

	var icon_holder := CenterContainer.new()
	icon_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(icon_holder)
	icon_holder.add_child(_build_icon(color, UNLOCKED_ICON_GLYPH if unlocked else LOCKED_ICON_GLYPH))

	var title_label := Label.new()
	title_label.text = achievement.title
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	title_label.add_theme_color_override("font_color", color)
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(title_label)


func _make_custom_tooltip(for_text: String) -> Object:
	return TooltipFactory.make_wrapped_tooltip(for_text)


## Placeholder until real icons exist: a rounded square with a glyph.
func _build_icon(color: Color, glyph: String) -> Control:
	var icon := Panel.new()
	icon.custom_minimum_size = ICON_SIZE
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := StyleBoxFlat.new()
	box.bg_color = Color(color, 0.25)
	box.border_color = color
	box.set_border_width_all(2)
	box.set_corner_radius_all(ICON_CORNER_RADIUS)
	icon.add_theme_stylebox_override("panel", box)

	var glyph_label := Label.new()
	glyph_label.text = glyph
	glyph_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glyph_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	glyph_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	glyph_label.add_theme_color_override("font_color", color)
	glyph_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.add_child(glyph_label)
	return icon
