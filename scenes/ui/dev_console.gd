class_name DevConsole
extends Panel

## Bottom-right console: a running event log (fed by the signal bus) and a command
## line with two tiers. Player commands are always available and only wrap actions
## the UI already allows. Dev commands stay gated behind
## BrewEngine.is_developer_mode(), toggled by a secret command in a gitignored set.

const CHEAT_SET_PATHS: Array[String] = [
	"res://src/console/dev_mode_commands.gd",
	"res://src/console/batch_cheat_commands.gd",
	"res://src/console/world_cheat_commands.gd",
]
const TITLE_TEXT: String = "Konsoli"
const COLLAPSE_ICON: String = "▼"
const EXPAND_ICON: String = "▲"
const MAX_LOG_LINES: int = 200

const MIN_SIZE: Vector2 = Vector2(180, 90)
## Height capped so the console can't cover Right_WarehouseView's Tynnyrit tab
## (same bottom-right anchor, and this Panel's mouse_filter is STOP).
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
var _registry: ConsoleCommandRegistry


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

## Deliberately _input(), not _unhandled_input(): it re-reads input_line_edit's focus
## on every keypress. "c" opens/focuses the console, or types normally while the field
## already has focus. Esc closes it before gui.gd's global Esc handler sees the event.
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


## True while the console is open or focused; gui.gd's Esc handler backs off then.
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


## LogScroll does the scrolling (LogLabel just fits its content). Its max_value only
## updates after layout, so wait a frame before snapping to the bottom.
func _scroll_log_to_bottom() -> void:
	await get_tree().process_frame
	log_scroll.scroll_vertical = int(log_scroll.get_v_scroll_bar().max_value)


# ----- command dispatch, handled by ConsoleCommandRegistry -----

## LineEdit drops focus on Enter, so grab it back to keep the input ready.
func _on_command_submitted(raw_text: String) -> void:
	var text := raw_text.strip_edges()
	input_line_edit.clear()
	input_line_edit.grab_focus()
	if text.is_empty():
		return

	_log("[color=gray]> %s[/color]" % text)
	_registry.execute(text)


func _register_commands() -> void:
	_registry = ConsoleCommandRegistry.new(_log)
	# Registration order is the order `help` lists commands in: player
	# commands first, then the console's own, then developer commands.
	_registry.add_command_set(PlayerCommands.new(_log))
	_registry.register("clear", _cmd_clear)
	_registry.register("help", _registry.print_help, "", "", false, false)
	# Cheat sets are gitignored and absent from public clones, so load them by path.
	for path: String in CHEAT_SET_PATHS:
		_registry.add_optional_command_set(path)


func _cmd_clear(_args: PackedStringArray) -> void:
	log_label.clear()
	_command_history.clear()
