@tool
extends McpTestSuite

const MashProgramScript := preload("res://src/brewing/brew_day/mash_program.gd")


func suite_name() -> String:
	return "mash_program"


func test_every_program_lasts_the_same() -> void:
	for count : int in [1, 2, 3, 4, 5]:
		var total : float = 0.0
		for seconds : float in MashProgramScript.step_seconds(count):
			total += seconds
		assert_eq(snappedf(total, 0.001), MashProgramScript.MASH_SECONDS, "%d steps" % count)


func test_a_step_mash_rests_short_first() -> void:
	var seconds : Array[float] = MashProgramScript.step_seconds(3)
	assert_eq(seconds.size(), 3)
	assert_true(seconds[0] < seconds[2])
