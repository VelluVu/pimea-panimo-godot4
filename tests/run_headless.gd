extends SceneTree

## Runs every res://tests/ suite outside the editor and exits 1 on a failure:
##   godot --headless --path . -s res://tests/run_headless.gd -- [--suite=name] [--test=part]
## In the editor, resources with non-tool scripts load as placeholders and autoloads and
## static vars do not run, so tests that call into loaded .tres data can only pass here.
## dev/tools/run_tests.py wraps this with a throwaway APPDATA.


func _initialize() -> void:
	await process_frame
	_use_finnish_source_text()
	var args: Dictionary = _user_args()
	var results: Dictionary = PPTestDiscovery.run_and_print(args.get("suite", ""), args.get("test", ""))
	var failed: bool = results.is_empty() or int(results.get("failed", 0)) > 0
	quit(1 if failed else 0)


## Tests expect the Finnish texts, which are the translation keys; a non-Finnish system
## locale would otherwise translate them to English.
func _use_finnish_source_text() -> void:
	var english: Translation = TranslationServer.get_translation_object("en")
	while english != null and english.locale.begins_with("en"):
		TranslationServer.remove_translation(english)
		english = TranslationServer.get_translation_object("en")
	TranslationServer.set_locale("fi")


func _user_args() -> Dictionary:
	var args: Dictionary = {}
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--") and arg.contains("="):
			args[arg.get_slice("=", 0).trim_prefix("--")] = arg.get_slice("=", 1)
	return args
