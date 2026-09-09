class_name DevConsole
extends Panel

## Bottom-right dev/user console: shows a running log of recent game events
## (built from the existing signal bus, not raw prints) and a command line
## for quick "macros" that replace the old FeatureTesterPanel debug buttons.
## Commands only execute when BrewEngine.DEVELOPER_MODE is on, matching the
## gating that panel used to have — the log itself stays visible to everyone.

const TITLE_TEXT: String = "Konsoli"
const COLLAPSE_ICON: String = "▼"
const EXPAND_ICON: String = "▲"
const DEV_MODE_OFF_MESSAGE: String = "[color=orange]Komennot ovat pois käytöstä (DEVELOPER_MODE = false).[/color]"
const UNKNOWN_COMMAND_MESSAGE: String = "[color=orange]Tuntematon komento: %s (kokeile 'help')[/color]"
const MAX_LOG_LINES: int = 200

const MIN_SIZE: Vector2 = Vector2(180, 90)
const MAX_SIZE: Vector2 = Vector2(440, 300)
const COLLAPSED_BODY_HEIGHT: float = 0.0

const FOCUS_STYLE_BORDER_COLOR: Color = Color(0.85, 0.65, 0.25)

@onready var resize_handle: Control = $ResizeHandle
@onready var toggle_button: Button = $MarginContainer/MainVBox/HeaderHBox/ToggleButton
@onready var title_label: Label = $MarginContainer/MainVBox/HeaderHBox/TitleLabel
@onready var body_vbox: VBoxContainer = $MarginContainer/MainVBox/BodyVBox
@onready var log_label: RichTextLabel = $MarginContainer/MainVBox/BodyVBox/LogScroll/LogLabel
@onready var input_line_edit: LineEdit = $MarginContainer/MainVBox/BodyVBox/InputLineEdit

var _is_collapsed: bool = false
var _expanded_size: Vector2

var _is_resizing: bool = false
var _resize_start_mouse: Vector2
var _resize_start_offset_left: float
var _resize_start_offset_top: float

var _command_history: PackedStringArray = []
var _commands: Dictionary = {}


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

	_log("Konsoli valmis. Kirjoita 'help' nähdäksesi komennot.")


# ----- collapse / expand -----

func _on_toggle_pressed() -> void:
	_is_collapsed = not _is_collapsed
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
	BrewerySignals.avi_raid_triggered.connect(_on_avi_raid_triggered)
	BrewerySignals.recipe_saved.connect(_on_recipe_saved)
	SpecialEventManager.special_event_triggered.connect(_on_special_event_triggered)
	TimeManager.day_changed.connect(_on_day_changed)


func _on_style_discovered(style: int) -> void:
	_log("[color=lightgreen]Uusi oluttyyli löydetty: %s[/color]" % BeerStyle.get_style_string_from_style(style))


func _on_avi_raid_triggered(confiscated_bottles: int, fine_amount: int, reputation_lost: int) -> void:
	_log("[color=red]AVI-RATSIA! Takavarikoitu %d pulloa, sakko %d €, mainetta -%d[/color]" % [confiscated_bottles, fine_amount, reputation_lost])


func _on_recipe_saved(recipe_name: String) -> void:
	_log("Resepti tallennettu: %s" % recipe_name)


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


# ----- command / macro dispatch -----

func _on_command_submitted(raw_text: String) -> void:
	var text := raw_text.strip_edges()
	input_line_edit.clear()
	if text.is_empty():
		return

	_log("[color=gray]> %s[/color]" % text)

	if not BrewEngine.DEVELOPER_MODE:
		_log(DEV_MODE_OFF_MESSAGE)
		return

	var parts := text.split(" ", false)
	var command_name := parts[0].to_lower()
	var args := parts.slice(1)

	if _commands.has(command_name):
		_commands[command_name].call(args)
	else:
		_log(UNKNOWN_COMMAND_MESSAGE % command_name)


func _register_commands() -> void:
	_commands = {
		"help": _cmd_help,
		"clear": _cmd_clear,
		"brew": _cmd_brew,
		"customer": _cmd_customer,
		"special": _cmd_special,
		"raid": _cmd_raid,
		"money": _cmd_money,
		"rep": _cmd_rep,
		"risk": _cmd_risk,
		"day": _cmd_day,
	}


func _cmd_help(_args: PackedStringArray) -> void:
	_log("Komennot: help, clear, brew <tyyli>, customer [nimi], special, raid, money <n>, rep <n>, risk <n>, day")


func _cmd_clear(_args: PackedStringArray) -> void:
	log_label.clear()
	_command_history.clear()


func _cmd_brew(args: PackedStringArray) -> void:
	var brewery := BrewEngine.current_brewery
	if brewery == null:
		_log("Ei aktiivista panimoa.")
		return

	if args.is_empty():
		_log("Käyttö: brew <tyyli> — esim. 'brew ipa'. Saatavilla: %s" % _available_style_names(brewery))
		return

	var wanted := args[0].to_upper().replace(" ", "_")
	var matched_style: BeerStyle = null
	for beer_style: BeerStyle in brewery.resolver.active_styles:
		if BeerStyle.Style.keys()[beer_style.style] == wanted:
			matched_style = beer_style
			break

	if matched_style == null:
		_log("Tyyliä ei löytynyt: %s. Saatavilla: %s" % [args[0], _available_style_names(brewery)])
		return

	# Skips the ingredient simulation entirely and drops in a good-quality
	# batch directly — this is a dev shortcut for testing sales/events
	# against any style, not a stand-in for real brewing.
	var new_batch := BrewBatch.new()
	new_batch.beer_style = matched_style
	new_batch.amount_bottles = 40
	new_batch.original_quality = matched_style.original_quality
	new_batch.current_quality = matched_style.original_quality
	new_batch.final_ebc = int((matched_style.min_ebc + matched_style.max_ebc) / 2.0)
	new_batch.final_ibu = int((matched_style.min_ibu + matched_style.max_ibu) / 2.0)

	brewery.inventory.brew_batches.append(new_batch)
	brewery.discover_style(matched_style.style)
	BrewerySignals.brewery_state_changed.emit(brewery)
	_log("Keitetty testierä: %s (40 pulloa)." % matched_style.style_name)


func _available_style_names(brewery: Brewery) -> String:
	var names: Array[String] = []
	for beer_style: BeerStyle in brewery.resolver.active_styles:
		names.append(BeerStyle.Style.keys()[beer_style.style].to_lower())
	return ", ".join(names)


func _cmd_customer(args: PackedStringArray) -> void:
	var forced_data: CustomerData = null
	if not args.is_empty():
		var wanted := args[0].to_lower()
		for customer_data: CustomerData in CustomerRegistry.customer_pool:
			if customer_data.resource_path.get_file().to_lower().begins_with(wanted):
				forced_data = customer_data
				break
		if forced_data == null:
			_log("Asiakastyyppiä ei löytynyt: %s" % args[0])
			return
	CustomerManager.spawn_normal_customer(forced_data)
	_log("Asiakas kutsuttu.")


func _cmd_special(_args: PackedStringArray) -> void:
	SpecialEventManager.spawn_special_customer()
	_log("Erikoistapahtuma laukaistu.")


func _cmd_raid(_args: PackedStringArray) -> void:
	var brewery := BrewEngine.current_brewery
	if brewery == null:
		_log("Ei aktiivista panimoa.")
		return
	brewery.add_risk(Brewery.AVI_RAID_THRESHOLD)


func _cmd_money(args: PackedStringArray) -> void:
	var brewery := BrewEngine.current_brewery
	if brewery == null or args.is_empty() or not args[0].is_valid_int():
		_log("Käyttö: money <määrä>")
		return
	brewery.money = args[0].to_int()
	BrewerySignals.brewery_state_changed.emit(brewery)


func _cmd_rep(args: PackedStringArray) -> void:
	var brewery := BrewEngine.current_brewery
	if brewery == null or args.is_empty() or not args[0].is_valid_int():
		_log("Käyttö: rep <määrä>")
		return
	brewery.reputation = args[0].to_int()
	BrewerySignals.brewery_state_changed.emit(brewery)


func _cmd_risk(args: PackedStringArray) -> void:
	var brewery := BrewEngine.current_brewery
	if brewery == null or args.is_empty() or not args[0].is_valid_int():
		_log("Käyttö: risk <määrä>")
		return
	brewery.risk = 0
	brewery.add_risk(args[0].to_int())


func _cmd_day(_args: PackedStringArray) -> void:
	TimeManager.force_advance_day()
