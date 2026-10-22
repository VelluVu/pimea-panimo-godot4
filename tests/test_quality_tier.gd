@tool
extends McpTestSuite

## Unit tests for QualityTier: the quality grades and their bars.

const QualityTierScript := preload("res://src/brewing/quality_tier.gd")


func suite_name() -> String:
	return "quality_tier"


func test_each_bar_starts_its_grade() -> void:
	assert_eq(QualityTierScript.text(0.69), QualityTierScript.POOR_TEXT)
	assert_eq(QualityTierScript.text(0.7), QualityTierScript.MEDIOCRE_TEXT)
	assert_eq(QualityTierScript.text(0.89), QualityTierScript.MEDIOCRE_TEXT)
	assert_eq(QualityTierScript.text(0.9), QualityTierScript.GOOD_TEXT)
	assert_eq(QualityTierScript.text(1.1), QualityTierScript.EXCELLENT_TEXT)
	assert_eq(QualityTierScript.text(1.3), QualityTierScript.MASTERFUL_TEXT)


## A default recipe at 1.0 lands on 0.9 on a normal brew day, which must still be good.
func test_a_normal_day_default_recipe_is_good() -> void:
	assert_eq(QualityTierScript.text(snappedf(1.0 * 0.9, 0.01)), QualityTierScript.GOOD_TEXT)
