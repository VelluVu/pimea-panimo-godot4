@tool
extends McpTestSuite

## Unit tests for ShortcutHint: the key joined to a spot's name.

const ShortcutHintScript := preload("res://src/ui/shortcut_hint.gd")


func suite_name() -> String:
	return "shortcut_hint"


func test_key_follows_the_name_in_brackets() -> void:
	assert_eq(ShortcutHintScript.text("Panimo", "P"), "Panimo (P)")


func test_an_unbound_action_leaves_the_name_alone() -> void:
	assert_eq(ShortcutHintScript.text("Panimo", ""), "Panimo")
