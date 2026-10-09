@tool
extends McpTestSuite

## The course seller's perk roll and payment rules.


func suite_name() -> String:
	return "training_course_event_data"


func _make_course() -> TrainingCourseEventData:
	var course := TrainingCourseEventData.new()
	for perk_name : String in ["A", "B", "C"]:
		var perk := RunPerk.new()
		perk.perk_name = perk_name
		course.course_perks.append(perk)
	return course


func test_each_visit_rolls_one_of_the_courses() -> void:
	var course := _make_course()
	var rolled := course.prepared(null, []) as TrainingCourseEventData
	assert_true(rolled != course, "a rolled copy, the shared resource stays clean")
	assert_true(rolled.rolled_perk in course.course_perks)
	assert_eq(rolled.perk_on_success(null), rolled.rolled_perk)


func test_a_course_takes_money_and_no_beer() -> void:
	var course := _make_course()
	assert_false(course.waits_for_delivery())
	assert_eq(course.servings_taken(null), {})
