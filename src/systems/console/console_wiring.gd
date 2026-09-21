class_name ConsoleWiring
extends Node

## THE FILE TO EDIT WHEN THIS SYSTEM MOVES TO ANOTHER PROJECT. It is the only place in
## this folder that knows the project: the command sets, the developer-mode check, the
## input actions, the signals that feed the log, and all the wording. DevConsole adds this as
## a child, so the connections go away with it.

## Cheat sets are gitignored and absent from public clones, so they load by path if present.
const CHEAT_SET_PATHS: Array[String] = [
	"res://src/console/dev_mode_commands.gd",
	"res://src/console/batch_cheat_commands.gd",
	"res://src/console/world_cheat_commands.gd",
]

const TITLE_TEXT: String = "Konsoli"
const PLACEHOLDER_TEXT: String = "Kirjoita komento... (help)"
const READY_MESSAGE: String = "Konsoli valmis. Kirjoita 'help' nähdäksesi komennot."
const DEV_MODE_OFF_MESSAGE: String = "[color=orange]Komennot ovat pois käytöstä (DEVELOPER_MODE = false).[/color]"
const UNKNOWN_COMMAND_FORMAT: String = "[color=orange]Tuntematon komento: %s (kokeile 'help')[/color]"
const HELP_FORMAT: String = "Komennot: %s"
const DEV_HELP_FORMAT: String = "[color=orange]Kehittäjäkomennot: %s[/color]"

var _console: DevConsole


func _ready() -> void:
	_console = get_parent() as DevConsole
	_console.title_label.text = TITLE_TEXT
	_console.input_line_edit.placeholder_text = PLACEHOLDER_TEXT
	_console.open_action = InputManager.ACTION_OPEN_CONSOLE
	_console.cancel_action = InputManager.ACTION_CANCEL

	var registry: ConsoleCommandRegistry = _console.registry
	registry.developer_mode_check = BrewEngine.is_developer_mode
	registry.dev_mode_off_message = DEV_MODE_OFF_MESSAGE
	registry.unknown_command_format = UNKNOWN_COMMAND_FORMAT
	registry.help_format = HELP_FORMAT
	registry.dev_help_format = DEV_HELP_FORMAT
	# Registration order is the order `help` lists commands in: player commands first.
	registry.add_command_set(PlayerCommands.new(_console.log_line))
	for path: String in CHEAT_SET_PATHS:
		registry.add_optional_command_set(path)

	_connect_log_sources()
	_console.log_line(READY_MESSAGE)


func _connect_log_sources() -> void:
	BrewerySignals.style_discovered.connect(_on_style_discovered)
	BrewerySignals.lvv_raid_triggered.connect(_on_lvv_raid_triggered)
	BrewerySignals.recipe_saved.connect(_on_recipe_saved)
	BrewerySignals.batch_bottled.connect(_on_batch_bottled)
	BrewerySignals.daily_bills_paid.connect(_on_daily_bills_paid)
	BrewerySignals.early_day_close_applied.connect(_on_early_day_close_applied)
	SpecialEventManager.special_event_triggered.connect(_on_special_event_triggered)
	TimeManager.day_changed.connect(_on_day_changed)


func _on_style_discovered(style: int) -> void:
	_console.log_line("[color=lightgreen]Uusi oluttyyli löydetty: %s[/color]" % BeerStyle.get_style_string_from_style(style))


func _on_lvv_raid_triggered(confiscated_bottles: int, fine_amount: float, reputation_lost: int) -> void:
	_console.log_line("[color=red]LVV-RATSIA! Takavarikoitu %d annosta, sakko %.1f €, mainetta -%d[/color]" % [confiscated_bottles, fine_amount, reputation_lost])


func _on_recipe_saved(recipe_name: String) -> void:
	_console.log_line("Resepti tallennettu: %s" % recipe_name)


func _on_batch_bottled(bottles_lost: int, label_cost: float, style_name: String) -> void:
	if bottles_lost <= 0 and label_cost <= 0.0:
		return
	_console.log_line("Tynnyröinti (%s): %d annosta hukkui, markkinointi -%.1f €" % [style_name, bottles_lost, label_cost])


func _on_daily_bills_paid(electricity: int, water: int, total: int) -> void:
	_console.log_line("[color=orange]Laskut: sähkö -%d €, vesi -%d € (yhteensä -%d €)[/color]" % [electricity, water, total])


func _on_early_day_close_applied(money_cost: float, reputation_cost: int, risk_relief: int, close_count: int) -> void:
	if money_cost <= 0.0 and reputation_cost <= 0 and risk_relief <= 0:
		return
	_console.log_line("[color=orange]Ovet suljettu aikaisin (%d. kerta): -%.1f €, mainetta -%d, LVV-riski -%d[/color]" % [close_count, money_cost, reputation_cost, risk_relief])


func _on_special_event_triggered(event_data: SpecialEventData) -> void:
	_console.log_line("[color=yellow]Erikoistapahtuma: %s[/color]" % event_data.event_caller_name)


func _on_day_changed(new_day: int) -> void:
	_console.log_line("Päivä vaihtui: %d" % new_day)
