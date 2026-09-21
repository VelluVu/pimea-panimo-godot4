class_name ConsoleCommandRegistry
extends RefCounted

## Dispatch table for DevConsole: registers commands, parses a typed line and
## runs the matching handler. The console keeps only the UI. Registering
## everything through register() keeps dispatch and the help text in sync.

const DEV_MODE_OFF_MESSAGE: String = "[color=orange]Komennot ovat pois käytöstä (DEVELOPER_MODE = false).[/color]"
const UNKNOWN_COMMAND_MESSAGE: String = "[color=orange]Tuntematon komento: %s (kokeile 'help')[/color]"

## Command name -> ConsoleCommand, in registration order (which is also the
## order `help` lists them in).
var _commands: Dictionary = {}
## Kept so the sets (and their signal connections) live as long as the registry.
var _command_sets: Array[ConsoleCommandSet] = []
var _log: Callable


func _init(p_log: Callable) -> void:
	_log = p_log


func register(command_name: String, handler: Callable, usage: String = "", note: String = "", dev_only: bool = false, listed: bool = true) -> void:
	_commands[command_name] = ConsoleCommand.new(handler, usage if not usage.is_empty() else command_name, note, dev_only, listed)


func add_command_set(command_set: ConsoleCommandSet) -> void:
	_command_sets.append(command_set)
	command_set.register(register)


## Instantiates and adds a set from its script path if the file exists. Used
## for sets that are gitignored and absent from public clones.
func add_optional_command_set(path: String) -> void:
	if ResourceLoader.exists(path):
		add_command_set((load(path) as GDScript).new(_log))


## Parses one typed line and runs its command, logging unknown or gated ones.
func execute(text: String) -> void:
	var parts := text.split(" ", false)
	var command_name := parts[0].to_lower()
	var command: ConsoleCommand = _commands.get(command_name)
	if command == null:
		_log.call(UNKNOWN_COMMAND_MESSAGE % command_name)
		return

	if command.dev_only and not BrewEngine.is_developer_mode():
		_log.call(DEV_MODE_OFF_MESSAGE)
		return

	command.handler.call(parts.slice(1))


func print_help() -> void:
	_log.call("Komennot: %s" % ", ".join(_help_entries(false)))
	if BrewEngine.is_developer_mode():
		_log.call("[color=orange]Kehittäjäkomennot: %s[/color]" % ", ".join(_help_entries(true)))


## Help lines for every listed command of one kind, in registration order.
func _help_entries(dev_only: bool) -> PackedStringArray:
	var entries := PackedStringArray()
	for command: ConsoleCommand in _commands.values():
		if command.listed and command.dev_only == dev_only:
			entries.append(command.help_text())
	return entries
