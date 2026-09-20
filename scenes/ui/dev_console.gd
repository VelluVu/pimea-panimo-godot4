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
const TRADE_FAILED_MESSAGE: String = "[color=orange]%s epäonnistui: %s[/color]"
const PURCHASE_LOCKED_REASON: String = "%s vaatii mainetta %d"
const PURCHASE_UNDERFUNDED_REASON: String = "%s maksaa %d €, rahaa %.1f €"
const SALE_FAILED_REASON: String = "%s: pyydetty %d, varastossa %d"
const RECIPE_NOT_SAVED_MESSAGE: String = "Reseptiä ei tallennettu (pöytä tyhjä tai oluttyyli ei vielä tuttu)"
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

## Set by the BrewerySignals failure handlers below while an osta/myy command
## is in flight; the command clears it before emitting and reads it after,
## since GUISignals.buy_ingredient/sell_ingredient are fire-and-forget.
var _trade_failure_reason: String = ""
var _command_history: PackedStringArray = []
## Command name -> ConsoleCommand, in registration order (which is also the
## order `help` lists them in).
var _commands: Dictionary = {}


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
	BrewerySignals.ingredient_purchase_locked.connect(_on_purchase_locked)
	BrewerySignals.ingredient_purchase_underfunded.connect(_on_purchase_underfunded)
	BrewerySignals.ingredient_sale_failed.connect(_on_sale_failed)
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


func _on_purchase_locked(ingredient_name: String, required_reputation: int) -> void:
	_trade_failure_reason = PURCHASE_LOCKED_REASON % [ingredient_name, required_reputation]


func _on_purchase_underfunded(ingredient_name: String, price: int, money: float) -> void:
	_trade_failure_reason = PURCHASE_UNDERFUNDED_REASON % [ingredient_name, price, money]


func _on_sale_failed(ingredient_name: String, requested: int, in_stock: int) -> void:
	_trade_failure_reason = SALE_FAILED_REASON % [ingredient_name, requested, in_stock]


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
	# Player commands, in the order `help` lists them.
	_register("osta", _cmd_osta, "osta <ainesosa> <määrä>")
	_register("myy", _cmd_myy, "myy <ainesosa> <määrä>")
	_register("pöytään", _cmd_poytaan, "pöytään <ainesosa> <määrä>")
	_register("poista", _cmd_poista_poydalta, "poista <ainesosa> <määrä>")
	_register("tyhjennä", _cmd_tyhjenna)
	_register("tallenna", _cmd_tallenna)
	_register("pane", _cmd_pane)
	_register("keitä", _cmd_keita, "keitä <resepti>")
	_register("clear", _cmd_clear)
	_register("help", _cmd_help, "", "", false, false)
	_register("iddqd", _cmd_iddqd, "", "", false, false)

	# Developer commands (need developer mode).
	_register("brew", _cmd_brew, "brew <tyyli>", "", true)
	_register("sell", _cmd_sell, "sell [määrä] <tyyli>", "myy oikeasti, luo annoksia tarvittaessa", true)
	_register("dump", _cmd_dump, "dump <tyyli>", "halpamyy erä", true)
	_register("vie", _cmd_vie, "vie <tyyli> <baari>", "vie erä baariin, luo tarvittaessa", true)
	_register("customer", _cmd_customer, "customer [nimi]", "", true)
	_register("group", _cmd_group, "group [nimi]", "", true)
	_register("special", _cmd_special, "", "", true)
	_register("raid", _cmd_raid, "", "", true)
	_register("money", _cmd_money, "money <n>", "", true)
	_register("rep", _cmd_rep, "rep <n>", "", true)
	_register("risk", _cmd_risk, "risk <n>", "", true)
	_register("day", _cmd_day, "", "", true)
	_register("cat", _cmd_cat, "", "", true)


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

func _cmd_osta(args: PackedStringArray) -> void:
	var parsed := _parse_ingredient_amount(args)
	if parsed.is_empty():
		return
	_trade_failure_reason = ""
	GUISignals.buy_ingredient.emit(parsed.id, parsed.amount)
	if _trade_failure_reason.is_empty():
		_log("Ostettu: %s x%d" % [parsed.ingredient.name, parsed.amount])
	else:
		_log(TRADE_FAILED_MESSAGE % ["Ostaminen", _trade_failure_reason])


func _cmd_myy(args: PackedStringArray) -> void:
	var parsed := _parse_ingredient_amount(args)
	if parsed.is_empty():
		return
	_trade_failure_reason = ""
	GUISignals.sell_ingredient.emit(parsed.id, parsed.amount)
	if _trade_failure_reason.is_empty():
		_log("Myyty: %s x%d" % [parsed.ingredient.name, parsed.amount])
	else:
		_log(TRADE_FAILED_MESSAGE % ["Myyminen", _trade_failure_reason])


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
	var brewery := BrewEngine.current_brewery
	if brewery == null:
		_log("Ei aktiivista panimoa.")
		return

	var recipes_before : int = brewery.saved_recipes.size()
	GUISignals.save_recipe_requested.emit()

	# Success is already logged by _on_recipe_saved() via BrewerySignals.recipe_saved.
	if brewery.saved_recipes.size() == recipes_before:
		_log(RECIPE_NOT_SAVED_MESSAGE)


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

	var batches_before : int = brewery.inventory.brew_batches.size()
	GUISignals.load_recipe_requested.emit(matched)
	GUISignals.start_brewing.emit()

	if brewery.inventory.brew_batches.size() > batches_before:
		_log("Keitetään: %s" % matched.recipe_name)
	else:
		_log("Keittäminen epäonnistui: %s (ei tarpeeksi ainesosia varastossa?)" % matched.recipe_name)


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
		_log("Käyttö: brew <tyyli>, esim. 'brew ipa'. Saatavilla: %s" % _available_style_names(brewery))
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
	new_batch.amount_bottles = 45
	new_batch.original_quality = matched_style.original_quality
	new_batch.current_quality = matched_style.original_quality
	new_batch.final_ebc = int((matched_style.min_ebc + matched_style.max_ebc) / 2.0)
	new_batch.final_ibu = int((matched_style.min_ibu + matched_style.max_ibu) / 2.0)

	brewery.inventory.brew_batches.append(new_batch)
	brewery.discover_style(matched_style.style)
	BrewerySignals.brewery_state_changed.emit(brewery)
	_log("Keitetty testierä: %s (45 annosta)." % matched_style.style_name)


func _available_style_names(brewery: Brewery) -> String:
	var names: Array[String] = []
	for beer_style: BeerStyle in brewery.resolver.active_styles:
		names.append(BeerStyle.Style.keys()[beer_style.style].to_lower())
	return ", ".join(names)


## Forces a real sale through the actual game path — "sell 1 ipa", "sell 3
## imperial stout" — instead of a hypothetical preview. Tops up (or
## conjures, if none exists yet) enough real inventory of the requested
## style, then calls CustomerManager.process_auto_sale() with a throwaway
## CustomerData whose preference is rigged to want exactly that style, so
## the sale runs through the same code a real customer's visit would: real
## money/reputation/risk changes, real inventory decrement, and the real
## breakdown popup (BrewerySignals.beer_sale_breakdown). Logs the listed
## price plus a myynti/tippi/tuotantokulut/käteinen breakdown, listening in
## on BrewerySignals.batch_bottled and .beer_sale_breakdown (the same
## signals driving the real UI) rather than recomputing any of the numbers
## itself, so this can never drift from what actually happened.
func _cmd_sell(args: PackedStringArray) -> void:
	var brewery := BrewEngine.current_brewery
	if brewery == null:
		_log("Ei aktiivista panimoa.")
		return

	if args.is_empty():
		_log("Käyttö: sell [määrä] <tyyli>, esim. 'sell 1 ipa'. Saatavilla: %s" % _available_style_names(brewery))
		return

	var quantity : int = 1
	var style_args := args
	if args[0].is_valid_int():
		quantity = maxi(1, args[0].to_int())
		style_args = args.slice(1)

	if style_args.is_empty():
		_log("Käyttö: sell [määrä] <tyyli>.")
		return

	var wanted := " ".join(Array(style_args)).to_upper().replace(" ", "_")
	var matched_style: BeerStyle = null
	for beer_style: BeerStyle in brewery.resolver.active_styles:
		if BeerStyle.Style.keys()[beer_style.style] == wanted:
			matched_style = beer_style
			break

	if matched_style == null:
		_log("Tyyliä ei löytynyt: %s. Saatavilla: %s" % [" ".join(Array(style_args)), _available_style_names(brewery)])
		return

	# Dictionaries are reference types, so mutating keys in place (rather
	# than reassigning the captured variable itself, which a GDScript
	# lambda captures by value and can't rebind in the outer scope) lets
	# these lambdas report back to this function.
	var production_fee : Dictionary = {"total": 0.0}
	var track_production_fee := func(_bottles_lost: int, label_cost: float, _style_name: String) -> void:
		production_fee.total += label_cost
	BrewerySignals.batch_bottled.connect(track_production_fee)
	_ensure_batch_stock(brewery, matched_style, quantity)
	BrewerySignals.batch_bottled.disconnect(track_production_fee)

	var sale_result : Dictionary = {}
	var capture_sale := func(receipt_entry: SaleReceiptEntry) -> void:
		sale_result.entry = receipt_entry
		sale_result.gross = receipt_entry.gross_income
		sale_result.net = receipt_entry.net_income
	BrewerySignals.beer_sale_breakdown.connect(capture_sale)

	var customer := CustomerData.new()
	customer.primary_style = matched_style.style
	customer.min_bottles_per_visit = quantity
	customer.max_bottles_per_visit = quantity
	var response : String = CustomerManager.process_auto_sale(customer)

	BrewerySignals.beer_sale_breakdown.disconnect(capture_sale)

	if sale_result.is_empty():
		_log("Myynti epäonnistui: %s (ei tarpeeksi varastoa?)" % matched_style.style_name)
		return

	var breakdown : SaleBreakdown = sale_result.entry.breakdown
	var final_cash : float = sale_result.net - production_fee.total

	_log("[b]%s x%d[/b] (%.1f%% ABV), listahinta %.2f €/annos" % [matched_style.style_name, quantity, breakdown.abv, breakdown.price_per_bottle])
	_log("  Raaka-ainekulut: %.2f €/annos | Kate: %.2f €/annos" % [breakdown.raw_cost_per_bottle, breakdown.profit_per_bottle])
	_log("  Myynti: +%.1f €" % sale_result.gross)
	_log("  Tippi: +%.1f €" % sale_result.entry.tip_income)
	_log("  Tuotantokulut: -%.1f €" % production_fee.total)
	_log("  = Käteinen: %+.1f €" % final_cash)
	_log("\"%s\"" % response)


## Tops up beer_style's stock to at least `quantity` bottles by conjuring
## standard-yield test batches (same approach as _cmd_brew) as needed — so
## "sell 50 ipa" with an empty warehouse "brews" as many as it takes.
## Charges the same bottle-loss/label-cost production fees a real brew
## would (via Brewery.apply_bottling_costs) instead of handing out bottles
## for free, so testing sales via this shortcut doesn't skip the very
## production costs it's meant to help verify.
func _ensure_batch_stock(brewery: Brewery, beer_style: BeerStyle, quantity: int) -> void:
	while _total_stock_for_style(brewery, beer_style) < quantity:
		_conjure_batch(brewery, beer_style)


func _total_stock_for_style(brewery: Brewery, beer_style: BeerStyle) -> int:
	var total : int = 0
	for batch : BrewBatch in brewery.inventory.brew_batches:
		if batch.beer_style.style == beer_style.style:
			total += batch.amount_bottles
	return total


func _conjure_batch(brewery: Brewery, beer_style: BeerStyle) -> void:
	var raw_yield : int = BrewResult.new().bottle_yield
	var bottling : Dictionary = brewery.apply_bottling_costs(raw_yield)

	var new_batch := BrewBatch.new()
	new_batch.beer_style = beer_style
	new_batch.amount_bottles = bottling.effective_yield
	new_batch.original_quality = beer_style.original_quality
	new_batch.current_quality = beer_style.original_quality
	new_batch.final_ebc = int((beer_style.min_ebc + beer_style.max_ebc) / 2.0)
	new_batch.final_ibu = int((beer_style.min_ibu + beer_style.max_ibu) / 2.0)

	brewery.inventory.brew_batches.append(new_batch)
	brewery.discover_style(beer_style.style)
	BrewerySignals.batch_bottled.emit(bottling.bottles_lost, bottling.label_cost, beer_style.style_name)


## Forces a real Brewery.bulk_sell_batch through the actual GUISignals
## path — "dump ipa" — conjuring a batch first if none exists, same as
## "sell" does, since this command exists specifically to let QA exercise
## the warehouse bulk-sell action without brewing for real first. Listens
## for BrewerySignals.batch_bulk_sold (mutate-in-place on the captured
## dict, not reassign it — a GDScript lambda captures its outer variables
## by value, so reassigning "sold" itself inside the lambda would never be
## seen out here, only mutating a key on the same dict object works) the
## same way _cmd_sell listens for beer_sale_breakdown.
func _cmd_dump(args: PackedStringArray) -> void:
	var brewery := BrewEngine.current_brewery
	if brewery == null:
		_log("Ei aktiivista panimoa.")
		return

	if args.is_empty():
		_log("Käyttö: dump <tyyli>, esim. 'dump ipa'. Saatavilla: %s" % _available_style_names(brewery))
		return

	var matched_style := _match_style(brewery, args)
	if matched_style == null:
		_log("Tyyliä ei löytynyt: %s. Saatavilla: %s" % [" ".join(Array(args)), _available_style_names(brewery)])
		return

	_ensure_batch_stock(brewery, matched_style, 1)
	var batch := _find_batch_for_style(brewery, matched_style)
	if batch == null:
		_log("Erää ei löytynyt tyylille: %s" % matched_style.style_name)
		return

	var sold : Dictionary = {}
	var capture := func(style_name: String, bottles: int, payout: float) -> void:
		sold["style_name"] = style_name
		sold["bottles"] = bottles
		sold["payout"] = payout
	BrewerySignals.batch_bulk_sold.connect(capture)
	GUISignals.bulk_sell_batch_requested.emit(batch)
	BrewerySignals.batch_bulk_sold.disconnect(capture)

	if sold.is_empty():
		_log("Halpamyynti epäonnistui.")
		return

	_log("Halpamyynti: %s x%d  +%.1f €" % [sold.style_name, sold.bottles, sold.payout])


## Forces a real Brewery.ship_batch_to_bar through the actual GUISignals
## path — "vie ipa kuppila" — same conjure-if-needed approach as "dump"
## above. The bar is matched against the LAST token only (substring, like
## _find_ingredient_by_name) so the preceding tokens can be a multi-word
## style name without ambiguity — mirrors how "sell" already lets a
## leading quantity or a multi-word style share one argument list.
func _cmd_vie(args: PackedStringArray) -> void:
	var brewery := BrewEngine.current_brewery
	if brewery == null:
		_log("Ei aktiivista panimoa.")
		return

	if args.size() < 2:
		_log("Käyttö: vie <tyyli> <baari>, esim. 'vie ipa kuppila'. Baarit: %s" % _available_bar_names())
		return

	var bar := _find_bar_contact_by_name(args[args.size() - 1])
	if bar == null:
		_log("Baaria ei löytynyt: %s. Baarit: %s" % [args[args.size() - 1], _available_bar_names()])
		return

	var style_args := args.slice(0, args.size() - 1)
	var matched_style := _match_style(brewery, style_args)
	if matched_style == null:
		_log("Tyyliä ei löytynyt: %s. Saatavilla: %s" % [" ".join(Array(style_args)), _available_style_names(brewery)])
		return

	if brewery.reputation < bar.required_reputation:
		_log("Maine ei riitä baariin %s (vaatii %d, on %d)." % [bar.bar_name, bar.required_reputation, brewery.reputation])
		return

	_ensure_batch_stock(brewery, matched_style, 1)
	var batch := _find_batch_for_style(brewery, matched_style)
	if batch == null:
		_log("Erää ei löytynyt tyylille: %s" % matched_style.style_name)
		return

	var shipped : Dictionary = {}
	var capture := func(style_name: String, bar_name: String, bottles: int, payout: float, risk_added: int) -> void:
		shipped["style_name"] = style_name
		shipped["bar_name"] = bar_name
		shipped["bottles"] = bottles
		shipped["payout"] = payout
		shipped["risk_added"] = risk_added
	BrewerySignals.keg_shipped_to_bar.connect(capture)
	GUISignals.ship_batch_to_bar_requested.emit(batch, bar)
	BrewerySignals.keg_shipped_to_bar.disconnect(capture)

	if shipped.is_empty():
		_log("Vienti epäonnistui.")
		return

	_log("Vienti: %s x%d -> %s  +%.1f € (LVV-riski +%d)" % [shipped.style_name, shipped.bottles, shipped.bar_name, shipped.payout, shipped.risk_added])


func _match_style(brewery: Brewery, style_args: PackedStringArray) -> BeerStyle:
	var wanted := " ".join(Array(style_args)).to_upper().replace(" ", "_")
	for beer_style: BeerStyle in brewery.resolver.active_styles:
		if BeerStyle.Style.keys()[beer_style.style] == wanted:
			return beer_style
	return null


func _find_batch_for_style(brewery: Brewery, beer_style: BeerStyle) -> BrewBatch:
	for batch: BrewBatch in brewery.inventory.brew_batches:
		if batch.beer_style.style == beer_style.style:
			return batch
	return null


func _find_bar_contact_by_name(query: String) -> BarContact:
	var wanted := query.to_lower()
	for bar: BarContact in CustomerRegistry.bar_contact_pool:
		if bar.bar_name.to_lower().contains(wanted):
			return bar
	return null


func _available_bar_names() -> String:
	var names: Array[String] = []
	for bar: BarContact in CustomerRegistry.bar_contact_pool:
		names.append(bar.bar_name)
	return ", ".join(names) if not names.is_empty() else "(ei baareja)"


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
	brewery.add_risk(brewery.get_effective_raid_threshold())


func _cmd_cat(_args: PackedStringArray) -> void:
	var spawner := get_tree().get_first_node_in_group(ImmersionEventSpawner.IMMERSION_EVENT_SPAWNER_GROUP) as ImmersionEventSpawner
	if spawner == null:
		_log("Kissa-hiiri-tapahtumaa ei löytynyt.")
		return
	spawner.force_trigger()
	_log("Kissa jahtaa hiirtä.")


func _cmd_money(args: PackedStringArray) -> void:
	var brewery := BrewEngine.current_brewery
	if brewery == null or args.is_empty() or not args[0].is_valid_float():
		_log("Käyttö: money <määrä>")
		return
	brewery.money = args[0].to_float()
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
