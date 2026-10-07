@tool
extends McpTestSuite

const LegacySaveTextScript := preload("res://src/brewery/legacy_save_text.gd")

const OLD_SAVE : String = """[gd_resource type="Resource" script_class="Brewery" format=3]

[ext_resource type="Script" path="res://src/brewery/brewery.gd" id="1_a"]
[ext_resource type="Resource" path="res://src/resources/run_modifiers/tavallinen_keikka.tres" id="6_iwry1"]

[resource]
script = ExtResource("1_a")
renown_bottles_counted = 0
run_modifier = ExtResource("6_iwry1")
run_xp = 12
"""


func suite_name() -> String:
	return "legacy_save_text"


func test_an_old_save_needs_cleanup_and_a_new_one_does_not() -> void:
	assert_true(LegacySaveTextScript.needs_cleanup(OLD_SAVE))
	assert_false(LegacySaveTextScript.needs_cleanup(LegacySaveTextScript.cleaned(OLD_SAVE)))


func test_cleanup_drops_only_the_card_link_and_its_property() -> void:
	var text : String = LegacySaveTextScript.cleaned(OLD_SAVE)
	assert_false(text.contains("run_modifier"))
	assert_contains(text, "res://src/brewery/brewery.gd")
	assert_contains(text, "renown_bottles_counted = 0")
	assert_contains(text, "run_xp = 12")
	assert_eq(text.split("\n").size(), OLD_SAVE.split("\n").size() - 2)
