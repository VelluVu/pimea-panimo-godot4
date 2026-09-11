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
const MAX_SIZE: Vector2 = Vector2(440, 300)
const COLLAPSED_BODY_HEIGHT: float = 0.0

const FOCUS_STYLE_BORDER_COLOR: Color = Color(0.85, 0.65, 0.25)

@onready var resize_handle: Control = $ResizeHandle
@onready var toggle_button: Button = $MarginContainer/MainVBox/HeaderHBox/ToggleButton
@onready var title_label: Label = $MarginContainer/MainVBox/HeaderHBox/TitleLabel
@onready var body_vbox: VBoxContainer = $MarginContainer/MainVBox/BodyVBox
@onready var log_scroll: ScrollContainer = $MarginContainer/MainVBox/BodyVBox/LogScroll
@onready var log_label: RichTextLabel = $MarginContainer/MainVBox/BodyVBox/LogScroll/LogLabel
@onready var input_line_edit: LineEdit = $MarginContainer/MainVBox/BodyVBox/InputLineEdit

var _is_collapsed: bool = false
var _expanded_size: Vector2

var _is_resizing: bool = false
var _resize_start_mouse: Vector2
var _resize_start_offset_left: float
var _resize_start_offset_top: float

var _command_history: PackedStringArray = []
var _player_commands: Dictionary = {}
var _dev_commands: Dictionary = {}


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

func _on_command_submitted(raw_text: String) -> void:
	var text := raw_text.strip_edges()
	input_line_edit.clear()
	if text.is_empty():
		return

	_log("[color=gray]> %s[/color]" % text)

	var parts := text.split(" ", false)
	var command_name := parts[0].to_lower()
	var args := parts.slice(1)

	if _player_commands.has(command_name):
		_player_commands[command_name].call(args)
		return

	if _dev_commands.has(command_name):
		if not BrewEngine.is_developer_mode():
			_log(DEV_MODE_OFF_MESSAGE)
			return
		_dev_commands[command_name].call(args)
		return

	_log(UNKNOWN_COMMAND_MESSAGE % command_name)


func _register_commands() -> void:
	_player_commands = {
		"help": _cmd_help,
		"clear": _cmd_clear,
		"osta": _cmd_osta,
		"myy": _cmd_myy,
		"pöytään": _cmd_poytaan,
		"poista": _cmd_poista_poydalta,
		"tyhjennä": _cmd_tyhjenna,
		"tallenna": _cmd_tallenna,
		"pane": _cmd_pane,
		"keitä": _cmd_keita,
		"iddqd": _cmd_iddqd,
	}

	_dev_commands = {
		"brew": _cmd_brew,
		"customer": _cmd_customer,
		"group": _cmd_group,
		"special": _cmd_special,
		"raid": _cmd_raid,
		"money": _cmd_money,
		"rep": _cmd_rep,
		"risk": _cmd_risk,
		"day": _cmd_day,
	}


func _cmd_help(_args: PackedStringArray) -> void:
	_log("Komennot: osta <ainesosa> <määrä>, myy <ainesosa> <määrä>, pöytään <ainesosa> <määrä>, poista <ainesosa> <määrä>, tyhjennä, tallenna, pane, keitä <resepti>, clear")
	if BrewEngine.is_developer_mode():
		_log("[color=orange]Kehittäjäkomennot: brew <tyyli>, customer [nimi], group [nimi], special, raid, money <n>, rep <n>, risk <n>, day[/color]")


func _cmd_clear(_args: PackedStringArray) -> void:
	log_label.clear()
	_command_history.clear()


# ----- player commands: text shortcuts for actions the UI already allows,
# wrapping the exact GUISignals a button click would fire. No economy or
# unlock rule is ever bypassed — this only skips clicking through menus.

func _cmd_osta(args: PackedStringArray) -> void:
	var parsed := _parse_ingredient_amount(args)
	if parsed.is_empty():
		return
	GUISignals.buy_ingredient.emit(parsed.id, parsed.amount)
	_log("Ostettu: %s x%d" % [parsed.ingredient.name, parsed.amount])


func _cmd_myy(args: PackedStringArray) -> void:
	var parsed := _parse_ingredient_amount(args)
	if parsed.is_empty():
		return
	GUISignals.sell_ingredient.emit(parsed.id, parsed.amount)
	_log("Myyty: %s x%d" % [parsed.ingredient.name, parsed.amount])


func _cmd_poytaan(args: PackedStringArray) -> void:
	var parsed := _parse_ingredient_amount(args)
	if parsed.is_empty():
		return
	GUISignals.add_ingredient_to_brew_preparation.emit(parsed.id, parsed.amount)
	_log("Pöydälle lisätty: %s x%d" % [parsed.ingredient.name, parsed.amount])


func _cmd_poista_poydalta(args: PackedStringArray) -> void:
	var parsed := _parse_ingredient_amount(args)
	if parsed.is_empty():
		return
	GUISignals.remove_ingredients_from_brew_preparation.emit(parsed.id, parsed.amount)
	_log("Poistettu pöydältä: %s x%d" % [parsed.ingredient.name, parsed.amount])


func _cmd_tyhjenna(_args: PackedStringArray) -> void:
	GUISignals.clear_brew_preparation_requested.emit()
	_log("Valmistelu tyhjennetty, ainekset palautettu varastoon.")


func _cmd_tallenna(_args: PackedStringArray) -> void:
	GUISignals.save_recipe_requested.emit()


func _cmd_pane(_args: PackedStringArray) -> void:
	GUISignals.start_brewing.emit()


func _cmd_keita(args: PackedStringArray) -> void:
	var brewery := BrewEngine.current_brewery
	if brewery == null:
		_log("Ei aktiivista panimoa.")
		return

	if args.is_empty():
		_log("Käyttö: keitä <resepti>. Tallennetut: %s" % _saved_recipe_names(brewery))
		return

	var wanted := " ".join(Array(args)).to_lower()
	var matched : BrewRecipe = null
	for recipe : BrewRecipe in brewery.saved_recipes:
		if recipe.recipe_name.to_lower().contains(wanted):
			matched = recipe
			break

	if matched == null:
		_log("Reseptiä ei löytynyt: %s. Tallennetut: %s" % [" ".join(Array(args)), _saved_recipe_names(brewery)])
		return

	GUISignals.load_recipe_requested.emit(matched)
	GUISignals.start_brewing.emit()
	_log("Keitetään: %s" % matched.recipe_name)


## Secret cheat code (classic Doom god-mode toggle) that flips developer
## mode on/off right from the console. Deliberately a player command, not a
## dev command — it must work even while developer mode is off, since
## that's the whole point of it — and deliberately left out of _cmd_help,
## since a cheat code that's listed in the help text isn't much of one.
func _cmd_iddqd(_args: PackedStringArray) -> void:
	var enabled = BrewEngine.toggle_developer_mode()
	if enabled:
		_log("[color=lightgreen]Kehittäjätila käytössä.[/color]")
	else:
		_log("[color=orange]Kehittäjätila pois käytöstä.[/color]")


func _saved_recipe_names(brewery : Brewery) -> String:
	var names : Array[String] = []
	for recipe : BrewRecipe in brewery.saved_recipes:
		names.append(recipe.recipe_name)
	return ", ".join(names) if not names.is_empty() else "(ei tallennettuja reseptejä)"


## Takes the trailing token as the amount and everything before it (joined)
## as an ingredient name search — matched by prefix first, then substring,
## against IngredientDatabase, so "osta pilsner 5" or "osta citra humala 20"
## both work without needing the ingredient's exact full name.
func _parse_ingredient_amount(args: PackedStringArray) -> Dictionary:
	if args.size() < 2 or not args[args.size() - 1].is_valid_int():
		_log("Käyttö: <komento> <ainesosa> <määrä>")
		return {}

	var amount : int = args[args.size() - 1].to_int()
	if amount <= 0:
		_log("Määrän täytyy olla suurempi kuin 0.")
		return {}

	var query := " ".join(Array(args.slice(0, args.size() - 1))).to_lower()
	var ingredient : IngredientData = _find_ingredient_by_name(query)
	if ingredient == null:
		_log("Ainesosaa ei löytynyt: %s" % query)
		return {}

	return {"id": ingredient.id, "amount": amount, "ingredient": ingredient}


func _find_ingredient_by_name(query : String) -> IngredientData:
	for id in IngredientDatabase.sorted_ids:
		var data : IngredientData = IngredientDatabase.database[id]
		if data.name.to_lower().begins_with(query):
			return data

	for id in IngredientDatabase.sorted_ids:
		var data : IngredientData = IngredientDatabase.database[id]
		if data.name.to_lower().contains(query):
			return data

	return null


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


func _cmd_group(args: PackedStringArray) -> void:
	var forced_event: GroupVisitEventData = null
	if not args.is_empty():
		var wanted := args[0].to_lower()
		for event_data: GroupVisitEventData in CustomerRegistry.group_events_pool:
			if event_data.resource_path.get_file().to_lower().begins_with(wanted):
				forced_event = event_data
				break
		if forced_event == null:
			_log("Ryhmätapahtumaa ei löytynyt: %s" % args[0])
			return
	CustomerManager.spawn_group_event(forced_event)
	_log("Ryhmä kutsuttu.")


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
