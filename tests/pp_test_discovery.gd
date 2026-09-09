class_name PPTestDiscovery
extends RefCounted

## Shared res://tests/test_*.gd suite discovery and result printing, used by
## both the "Project > Tools > Run Unit Tests" menu item
## (addons/pp_test_tools/plugin.gd) and the standalone run_tests.gd
## EditorScript, so the two entry points can't drift out of sync.


static func discover_suites() -> Array:
	var suites: Array = []
	var dir := DirAccess.open("res://tests")
	if dir == null:
		return suites

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if file_name.begins_with("test_") and file_name.ends_with(".gd"):
			var script := load("res://tests/" + file_name)
			if script != null and script.can_instantiate():
				var instance = script.new()
				if instance is McpTestSuite:
					suites.append(instance)
				else:
					print("[tests] Skipping %s (not a McpTestSuite subclass)" % file_name)
			else:
				print("[tests] Failed to load %s" % file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	suites.sort_custom(func(a, b) -> bool: return a.suite_name() < b.suite_name())
	return suites


static func print_results(results: Dictionary) -> void:
	print("[tests] %d passed, %d failed, %d skipped (of %d total)" % [
		results.get("passed", 0),
		results.get("failed", 0),
		results.get("skipped", 0),
		results.get("total", 0),
	])
	for entry in results.get("results", []):
		if not entry.get("passed", true):
			print("  FAIL [%s] %s — %s" % [entry.get("suite", "?"), entry.get("test", "?"), entry.get("message", "")])
		elif entry.get("skipped", false):
			print("  SKIP [%s] %s — %s" % [entry.get("suite", "?"), entry.get("test", "?"), entry.get("message", "")])


static func run_and_print() -> void:
	var suites := discover_suites()
	if suites.is_empty():
		print("[tests] No test_*.gd suites found in res://tests")
		return
	var runner := McpTestRunner.new()
	var results: Dictionary = runner.run_suites(suites, "", "", {}, true)
	print_results(results)
