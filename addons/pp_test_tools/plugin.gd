@tool
extends EditorPlugin

## Adds "Project > Tools > Run Unit Tests", running every res://tests/
## test_*.gd suite (see tests/test_discovery.gd) and printing a pass/fail
## summary to the Output panel. Enable via Project Settings > Plugins.

const MENU_ITEM_NAME := "Run Unit Tests"


func _enter_tree() -> void:
	add_tool_menu_item(MENU_ITEM_NAME, _on_run_unit_tests)


func _exit_tree() -> void:
	remove_tool_menu_item(MENU_ITEM_NAME)


func _on_run_unit_tests() -> void:
	PPTestDiscovery.run_and_print()
