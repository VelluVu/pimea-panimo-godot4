@tool
extends EditorScript

## Manual test runner for res://tests/test_*.gd suites.
##
## How to use in the Godot editor:
##   1. Open this file (run_tests.gd) in the Script editor.
##   2. File > Run (or the shortcut shown there, e.g. Ctrl+Shift+X).
##   3. Results print to the Output panel at the bottom of the editor.
##
## Once addons/pp_test_tools is enabled (Project Settings > Plugins), the
## same thing is available from Project > Tools > Run Unit Tests without
## needing to open this file at all — this script is kept as a fallback
## that works even without the plugin enabled.


func _run() -> void:
	PPTestDiscovery.run_and_print()
