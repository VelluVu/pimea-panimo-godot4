class_name ConsoleCommandSet
extends RefCounted

## Base for a group of console commands: registers them and logs through log_line, so the
## console owns only the UI and dispatch.

## Writes one BBCode line to the console log.
var log_line : Callable


func _init(p_log_line : Callable) -> void:
	log_line = p_log_line


## Adds this set's commands. `register_command` has the same signature as
## DevConsole._register(): (name, handler, usage, note, dev_only, listed).
func register(_register_command : Callable) -> void:
	push_error("ConsoleCommandSet.register() must be overridden")


func _log(bbcode_line : String) -> void:
	log_line.call(bbcode_line)
