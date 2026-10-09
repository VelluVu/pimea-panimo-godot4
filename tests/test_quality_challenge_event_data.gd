@tool
extends McpTestSuite

## How strong the critic's perk is for a batch's quality.


func suite_name() -> String:
	return "quality_challenge_event_data"


func test_perk_is_weakest_at_the_quality_bar() -> void:
	assert_true(is_equal_approx(QualityChallengeEventData.perk_strength(1.2, 1.2, 1.6, 0.25), 0.25))


func test_perk_grows_with_quality() -> void:
	assert_true(is_equal_approx(QualityChallengeEventData.perk_strength(1.4, 1.2, 1.6, 0.25), 0.625))


func test_perk_never_passes_full_strength() -> void:
	assert_true(is_equal_approx(QualityChallengeEventData.perk_strength(2.2, 1.2, 1.6, 0.25), 1.0))
