class_name ConsoleCommand
extends RefCounted

## One console command: its handler, what `help` prints for it, and whether it needs
## developer mode.

var handler : Callable
var usage : String
var note : String
var dev_only : bool
## Unlisted commands still work but don't appear in `help`.
var listed : bool


func _init(p_handler : Callable, p_usage : String, p_note : String, p_dev_only : bool, p_listed : bool) -> void:
	handler = p_handler
	usage = p_usage
	note = p_note
	dev_only = p_dev_only
	listed = p_listed


func help_text() -> String:
	return usage if note.is_empty() else "%s (%s)" % [usage, note]
