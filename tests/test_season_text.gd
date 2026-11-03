@tool
extends McpTestSuite

const SeasonTextScript := preload("res://src/ui/season_text.gd")
const SeasonDataScript := preload("res://src/events/season_data.gd")


func suite_name() -> String:
	return "season_text"


func _halloween() -> SeasonData:
	var data : SeasonData = SeasonDataScript.new()
	data.title = "Halloween"
	data.icon = "👻"
	data.description = "Myrskyöitä."
	return data


func test_the_tooltip_counts_the_days_left() -> void:
	assert_eq(SeasonTextScript.tooltip(_halloween(), 5), "Halloween\nMyrskyöitä.\nVielä 5 päivää.")


func test_the_last_day_says_so() -> void:
	assert_eq(SeasonTextScript.tooltip(_halloween(), 1), "Halloween\nMyrskyöitä.\nViimeinen päivä.")


func test_no_countdown_leaves_the_line_out() -> void:
	assert_eq(SeasonTextScript.tooltip(_halloween(), 0), "Halloween\nMyrskyöitä.")


func test_the_start_toast_points_at_the_icon() -> void:
	assert_eq(SeasonTextScript.started(_halloween()), "Halloween alkoi! Yläpalkin 👻 kertoo, mitä se tuo.")


func test_a_seasonal_ingredient_gets_the_mark() -> void:
	assert_eq(SeasonTextScript.seasonal_name("Kehote", _halloween()), "👻 Kehote")
	assert_eq(SeasonTextScript.seasonal_name("Pilsner-mallas", null), "Pilsner-mallas")


func test_the_menu_line_puts_the_countdown_under_the_name() -> void:
	assert_eq(SeasonTextScript.line(_halloween(), 6), "👻 Halloween\nVielä 6 päivää.")
	assert_eq(SeasonTextScript.line(_halloween(), 0), "👻 Halloween")
