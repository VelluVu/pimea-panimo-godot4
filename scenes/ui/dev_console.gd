class_name DevConsole
extends Panel

## Bottom-right dev/user console: shows a running log of recent game events
## (built from the existing signal bus, not raw prints) and a command line
## with two tiers of commands:
##  - player commands (osta, myy, keitä, ...) are always available — thin
##    text shortcuts for actions the UI already allows, wrapping the exact
##    same GUISignals a button click would fire. No economy/unlock rule is
##    ever bypassed; this only skips clicking through menus.
##  - dev/cheat commands (brew, money, raid, ...) stay gated behind
##    BrewEngine.is_developer_mode(), matching the old FeatureTesterPanel's
##    gating. Toggled at runtime by the secret "iddqd" command (a player
##    command, so it works even while developer mode is off).
## The log itself is always visible regardless of either tier.

const TITLE_TEXT: String = "Konsoli"
const COLLAPSE_ICON: String = "▼"
const EXPAND_ICON: String = "▲"
const DEV_MODE_OFF_MESSAGE: String = "[color=orange]Komennot ovat pois käytöstä (DEVELOPER_MODE = false).[/color]"
const UNKNOWN_COMMAND_MESSAGE: String = "[color=orange]Tuntematon komento: %s (kokeile 'help')[/color]"
const MAX_LOG_LINES: int = 200

const MIN_SIZE: Vector2 = Vector2(180, 90)
## Height capped well under what it takes to reach Right_WarehouseView's
## bottom edge (anchored bottom-right same as this panel, its rect ends
## ~228px above the screen bottom) — a console resized taller than that
## used to sit on top of and swallow clicks meant for the warehouse view's
## Tynnyrit tab underneath it, since Panel's default mouse_filter is STOP
## and this node draws later in GUI's child order.
const MAX_SIZE: Vector2 = Vector2(440, 200)
const COLLAPSED_BODY_HEIGHT: float = 0.0

const FOCUS_STYLE_BORDER_COLOR: Color = Color(0.85, 0.65, 0.25)

@onready var resize_handle: Control = $ResizeHandle
@onready var toggle_button: Button = $MarginContainer/MainVBox/HeaderHBox/ToggleButton
@onready var title_label: Label = $MarginContainer/MainVBox/HeaderHBox/TitleLabel
@onready var body_vbox: VBoxContainer = $MarginContainer/MainVBox/BodyVBox
@onready var log_scroll: ScrollContainer = $MarginContainer/MainVBox/BodyVBox/LogScroll
@onready var log_label: RichTextLabel = $MarginContainer/MainVBox/BodyVBox/LogScroll/LogLabel
@onready var input_line_edit: LineEdit = $MarginContainer/MainVBox/BodyVBox/InputLineEdit

var _is_collapsed: bool = true
var _expanded_size: Vector2

var _is_resizing: bool = false
var _resize_start_mouse: Vector2
var _resize_start_offset_left: float
var _resize_start_offset_top: float

var _command_history: PackedStringArray = []
## Command name -> ConsoleCommand, in registration order (which is also the
## order `help` lists them in).
var _commands: Dictionary = {}
## Kept so the sets (and their signal connections) live as long as the console.
var _command_sets: Array[ConsoleCommandSet] = []


## One console command: its handler, what `help` prints for it, and whether it
## needs developer mode. Registering everything through _register() keeps the
## dispatch table and the help text from drifting apart.
class ConsoleCommand:
	var handler: Callable
	var usage: String
	var note: String
	var dev_only: bool
	## Unlisted commands still work but don't appear in `help` (help itself, iddqd).
	var listed: bool

	func _init(p_handler: Callable, p_usage: String, p_note: String, p_dev_only: bool, p_listed: bool) -> void:
		handler = p_handler
		usage = p_usage
		note = p_note
		dev_only = p_dev_only
		listed = p_listed

	func help_text() -> String:
		return usage if note.is_empty() else "%s (%s)" % [usage, note]


func _ready() -> void:
	title_label.text = TITLE_TEXT
	_expanded_size = size

	toggle_button.pressed.connect(_on_toggle_pressed)
	input_line_edit.text_submitted.connect(_on_command_submitted)
	input_line_edit.focus_entered.connect(_on_input_focus_entered)
	input_line_edit.focus_exited.connect(_on_input_focus_exited)

	resize_handle.gui_input.connect(_on_resize_handle_gui_input)

	_register_commands()
	_connect_log_sources()
	_apply_focus_style(false)
	_apply_collapsed_state()

	_log("Konsoli valmis. Kirjoita 'help' nähdäksesi komennot.")


# ----- "c" hotkey to open/focus, Esc to close -----

## Deliberately _input(), not _unhandled_input(): the latter only fires for
## events nothing already consumed as GUI input, which made this depend on
## Godot's internal focus/consumption bookkeeping around the moment
## input_line_edit loses focus (e.g. via its own submit-then-release-focus
## behavior on Enter) — fragile, and the actual bug this replaces: "c"
## stopped reopening the console after a command was submitted once.
## Checking has_focus() explicitly here instead means the input field's
## current focus state is re-read fresh on every keypress, not inferred
## from event-propagation history. While it already has focus, just return
## without consuming the event so the "c" still types normally (letting
## commands like "clear" or "customer" work); otherwise open/focus it and
## consume the event. No InputMap action needed for either hardcoded key.
##
## Esc closes the console before GUI.gd's own global Esc handler ever sees
## it — since _input() fires ahead of _unhandled_input() project-wide, and
## set_input_as_handled() here stops it from propagating any further, the
## console always gets first claim on Esc while it's open, without gui.gd
## needing to know anything about this node's internal state.
func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	if event.keycode == KEY_C:
		if input_line_edit.has_focus():
			return
		_open_and_focus_input()
		get_viewport().set_input_as_handled()
		return

	if event.keycode == KEY_ESCAPE and is_console_active():
		input_line_edit.release_focus()
		if not _is_collapsed:
			_on_toggle_pressed()
		get_viewport().set_input_as_handled()


## Whether Esc should treat the console as "the thing currently open" — also
## read by gui.gd's own global Esc/view-shortcut handler so it can back off
## instead of racing this node's _input() (see gui.gd's _unhandled_input()).
func is_console_active() -> bool:
	return not _is_collapsed or input_line_edit.has_focus()


func _open_and_focus_input() -> void:
	if _is_collapsed:
		_on_toggle_pressed()
	input_line_edit.grab_focus()


# ----- collapse / expand -----

func _on_toggle_pressed() -> void:
	_is_collapsed = not _is_collapsed
	_apply_collapsed_state()


func _apply_collapsed_state() -> void:
	if _is_collapsed:
		_expanded_size = size
		body_vbox.hide()
		toggle_button.text = EXPAND_ICON
		offset_top = offset_bottom - _header_height()
	else:
		body_vbox.show()
		toggle_button.text = COLLAPSE_ICON
		offset_top = offset_bottom - _expanded_size.y


func _header_height() -> float:
	return $MarginContainer/MainVBox/HeaderHBox.size.y + 10.0


# ----- drag-resize from the top-left corner, bottom-right stays anchored -----

func _on_resize_handle_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_is_resizing = true
			_resize_start_mouse = get_global_mouse_position()
			_resize_start_offset_left = offset_left
			_resize_start_offset_top = offset_top
		else:
			_is_resizing = false
	elif event is InputEventMouseMotion and _is_resizing:
		var delta := get_global_mouse_position() - _resize_start_mouse
		var new_width: float = clampf(-(_resize_start_offset_left + delta.x) + offset_right, MIN_SIZE.x, MAX_SIZE.x)
		var new_height: float = clampf(-(_resize_start_offset_top + delta.y) + offset_bottom, MIN_SIZE.y, MAX_SIZE.y)
		offset_left = offset_right - new_width
		if not _is_collapsed:
			offset_top = offset_bottom - new_height
			_expanded_size = Vector2(new_width, new_height)
		else:
			_expanded_size.x = new_width


# ----- input focus indication -----

func _on_input_focus_entered() -> void:
	_apply_focus_style(true)


func _on_input_focus_exited() -> void:
	_apply_focus_style(false)


func _apply_focus_style(is_focused: bool) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.05, 0.05, 0.05, 0.9)
	box.set_border_width_all(2 if is_focused else 1)
	box.border_color = FOCUS_STYLE_BORDER_COLOR if is_focused else Color(0.3, 0.3, 0.3)
	box.set_corner_radius_all(3)
	input_line_edit.add_theme_stylebox_override("normal", box)
	input_line_edit.add_theme_stylebox_override("focus", box)


# ----- log, fed by the existing signal bus instead of raw prints -----

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
	_log("[color=lightgreen]Uusi oluttyyli löydetty: %s[/color]" % BeerStyle.get_style_string_from_style(style))


func _on_lvv_raid_triggered(confiscated_bottles: int, fine_amount: float, reputation_lost: int) -> void:
	_log("[color=red]LVV-RATSIA! Takavarikoitu %d annosta, sakko %.1f €, mainetta -%d[/color]" % [confiscated_bottles, fine_amount, reputation_lost])


func _on_recipe_saved(recipe_name: String) -> void:
	_log("Resepti tallennettu: %s" % recipe_name)


func _on_batch_bottled(bottles_lost: int, label_cost: float, style_name: String) -> void:
	if bottles_lost <= 0 and label_cost <= 0.0:
		return
	_log("Tynnyröinti (%s): %d annosta hukkui, markkinointi -%.1f €" % [style_name, bottles_lost, label_cost])


func _on_daily_bills_paid(electricity: int, water: int, total: int) -> void:
	_log("[color=orange]Laskut: sähkö -%d €, vesi -%d € (yhteensä -%d €)[/color]" % [electricity, water, total])


func _on_early_day_close_applied(money_cost: float, reputation_cost: int, risk_relief: int, close_count: int) -> void:
	if money_cost <= 0.0 and reputation_cost <= 0 and risk_relief <= 0:
		return
	_log("[color=orange]Ovet suljettu aikaisin (%d. kerta): -%.1f €, mainetta -%d, LVV-riski -%d[/color]" % [close_count, money_cost, reputation_cost, risk_relief])








func _on_special_event_triggered(event_data: SpecialEventData) -> void:
	_log("[color=yellow]Erikoistapahtuma: %s[/color]" % event_data.event_caller_name)


func _on_day_changed(new_day: int) -> void:
	_log("Päivä vaihtui: %d" % new_day)


func _log(bbcode_line: String) -> void:
	log_label.append_text(bbcode_line + "\n")
	_command_history.append(bbcode_line)
	if _command_history.size() > MAX_LOG_LINES:
		_command_history.remove_at(0)
		log_label.clear()
		log_label.append_text("\n".join(_command_history) + "\n")
	_scroll_log_to_bottom()


## fit_content on LogLabel makes it grow to full content height with no
## scrollbar of its own — LogScroll (the outer ScrollContainer) is what
## actually scrolls. Its scrollbar max only reflects the new content size
## after layout recalculates next frame, so this waits a frame before
## snapping down — jumping to bottom on every new line (terminal-style),
## while still leaving the user free to scroll up and read older lines
## in between.
func _scroll_log_to_bottom() -> void:
	await get_tree().process_frame
	log_scroll.scroll_vertical = int(log_scroll.get_v_scroll_bar().max_value)


# ----- command / macro dispatch -----

## LineEdit releases its own focus internally as part of submitting on
## Enter, which used to leave the player having to manually click the field
## again before typing a next command — grab_focus() right back so the
## input stays ready to type into immediately after every submit.
func _on_command_submitted(raw_text: String) -> void:
	var text := raw_text.strip_edges()
	input_line_edit.clear()
	input_line_edit.grab_focus()
	if text.is_empty():
		return

	_log("[color=gray]> %s[/color]" % text)

	var parts := text.split(" ", false)
	var command_name := parts[0].to_lower()
	var args := parts.slice(1)

	var command: ConsoleCommand = _commands.get(command_name)
	if command == null:
		_log(UNKNOWN_COMMAND_MESSAGE % command_name)
		return

	if command.dev_only and not BrewEngine.is_developer_mode():
		_log(DEV_MODE_OFF_MESSAGE)
		return

	command.handler.call(args)


func _register(command_name: String, handler: Callable, usage: String = "", note: String = "", dev_only: bool = false, listed: bool = true) -> void:
	_commands[command_name] = ConsoleCommand.new(handler, usage if not usage.is_empty() else command_name, note, dev_only, listed)


func _register_commands() -> void:
	_commands.clear()
	_command_sets.clear()

	# Registration order is the order `help` lists commands in: player
	# commands first, then the console's own, then developer commands.
	_add_command_set(PlayerCommands.new(_log))
	_register("clear", _cmd_clear)
	_register("help", _cmd_help, "", "", false, false)
	_register("iddqd", _cmd_iddqd, "", "", false, false)
	_add_command_set(BatchCheatCommands.new(_log))
	_add_command_set(WorldCheatCommands.new(_log))


func _add_command_set(command_set: ConsoleCommandSet) -> void:
	_command_sets.append(command_set)
	command_set.register(_register)


func _cmd_help(_args: PackedStringArray) -> void:
	_log("Komennot: %s" % ", ".join(_help_entries(false)))
	if BrewEngine.is_developer_mode():
		_log("[color=orange]Kehittäjäkomennot: %s[/color]" % ", ".join(_help_entries(true)))


## Help lines for every listed command of one kind, in registration order.
func _help_entries(dev_only: bool) -> PackedStringArray:
	var entries := PackedStringArray()
	for command: ConsoleCommand in _commands.values():
		if command.listed and command.dev_only == dev_only:
			entries.append(command.help_text())
	return entries


func _cmd_clear(_args: PackedStringArray) -> void:
	log_label.clear()
	_command_history.clear()


# ----- player commands: text shortcuts for actions the UI already allows,
# wrapping the exact GUISignals a button click would fire. No economy or
# unlock rule is ever bypassed — this only skips clicking through menus.

















## Turning dev mode on skips the beginner tutorial and starts the day clock.
## Turning it off leaves both alone: un-completing the tutorial or stopping a
## running clock would be destructive.
func _skip_tutorial_and_start_clock() -> void:
	var brewery := BrewEngine.current_brewery
	if brewery == null:
		return
	brewery.skip_tutorial()
	TimeManager.start_clock_immediately()
	BrewerySignals.brewery_state_changed.emit(brewery)


## Secret cheat code (classic Doom god-mode toggle) that flips developer
## mode on/off right from the console. Deliberately a player command, not a
## dev command — it must work even while developer mode is off, since
## that's the whole point of it — and deliberately left out of _cmd_help,
## since a cheat code that's listed in the help text isn't much of one.
func _cmd_iddqd(_args: PackedStringArray) -> void:
	var enabled = BrewEngine.toggle_developer_mode()
	if enabled:
		_skip_tutorial_and_start_clock()
		_log("[color=lightgreen]Kehittäjätila käytössä.[/color]")
	else:
		_log("[color=orange]Kehittäjätila pois käytöstä.[/color]")
















































