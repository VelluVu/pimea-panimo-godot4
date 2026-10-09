class_name ConsoleWiring
extends Node

## THE FILE TO EDIT WHEN THIS SYSTEM MOVES TO ANOTHER PROJECT. It is the only place in
## this folder that knows the project: the command sets, the developer-mode check, the
## input actions, the signals that feed the log, and all the wording. DevConsole adds this as
## a child, so the connections go away with it.

## Cheat sets are gitignored and absent from public clones, so they load by path if present.
## Only these work without a run, so the main menu's console gets just them.
const MENU_CHEAT_SET_PATHS: Array[String] = [
	"res://src/console/dev_mode_commands.gd",
]
const GAME_CHEAT_SET_PATHS: Array[String] = [
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
const STYLE_DISCOVERED_FORMAT: String = "[color=lightgreen]Uusi oluttyyli löydetty: %s[/color]"
const RAID_FORMAT: String = "[color=red]LVV-RATSIA! Takavarikoitu %d annosta, sakko %.1f €, mainetta -%d[/color]"
const RECIPE_SAVED_FORMAT: String = "Resepti tallennettu: %s"
const BOTTLED_FORMAT: String = "Tynnyröinti (%s): %d annosta hukkui, markkinointi -%.1f €"
const BILLS_FORMAT: String = "[color=orange]Laskut: sähkö -%d €, vesi -%d € (yhteensä -%d €)[/color]"
const EARLY_CLOSE_FORMAT: String = "[color=orange]Ovet suljettu aikaisin (%d. kerta): -%.1f €, mainetta -%d, LVV-riski -%d[/color]"
const SPECIAL_EVENT_FORMAT: String = "[color=yellow]Erikoistapahtuma: %s[/color]"
const DAY_CHANGED_FORMAT: String = "Päivä vaihtui: %d"

## Event lines: everything toasts and popups show, so a missed one can be read back.
## The player hides and shows them with `loki`; the choice is kept in the settings.
const EVENT_CATEGORY: StringName = &"event"
## Customers' lines, shown only on their own tab so the log is not drowned in chatter.
const DIALOGUE_CATEGORY: StringName = &"dialogue"
const LOG_TAB_TEXT: String = "Loki"
const DIALOGUE_TAB_TEXT: String = "Puheet"
const EVENTS_HIDDEN_OPTION_KEY: String = "console_events_hidden"
const LOKI_USAGE_TEXT: String = "loki näytä|piilota"
const EVENTS_SHOWN_MESSAGE: String = "Tapahtumaloki näkyvissä."
const EVENTS_HIDDEN_MESSAGE: String = "Tapahtumaloki piilotettu. Takaisin: loki näytä"
const LOKI_HIDE_ARG: String = "piilota"
const UNNAMED_CUSTOMER_TEXT: String = "Asiakas"
const FRIEND_FORMAT: String = "[color=lightgreen]%s suositteli kellaria kaverilleen.[/color]"
const BAD_REVIEW_TEXT: String = "[color=orange]Huono arvio kiertää: asiakkaita tulee hetken harvemmin.[/color]"
const REGULAR_GAINED_FORMAT: String = "[color=gold]%s on nyt kanta-asiakas.[/color]"
const REGULAR_LOST_FORMAT: String = "%s ei ole enää kanta-asiakas."
const STORED_FORMAT: String = "Varastoon: %s +%d annosta"
const INGREDIENTS_UNLOCKED_FORMAT: String = "[color=lightgreen]Uusia raaka-aineita: %s[/color]"
const CUSTOMER_UNLOCKED_FORMAT: String = "[color=lightgreen]Uusi asiakas avattu: %s[/color]"
const ACHIEVEMENT_FORMAT: String = "[color=gold]Saavutus avattu: %s[/color]"
const TIER_ROSE_FORMAT: String = "[color=lightgreen]Maine nousi: %s[/color]"
const TIER_FELL_FORMAT: String = "[color=orange]Maine laski: %s[/color]"
const DECAY_FORMAT: String = "Maine hiipui yöllä: -%d (%s)"
const LEVEL_UP_FORMAT: String = "[color=gold]Taso %d saavutettu![/color]"
const BULK_SOLD_FORMAT: String = "Tukkumyynti: %s, %d annosta, +%.1f €"
const SHIPPED_FORMAT: String = "Vienti: %s baariin %s, %d annosta, +%.1f €, LVV-riski %+d"
const UPGRADE_FORMAT: String = "Kellariparannus: %s (taso %d)"
const BAR_FIGHT_FORMAT: String = "[color=orange]Baaritappelu! %d annosta rikki.[/color]"

var _console: DevConsole
var _unlock_tracker: ReputationUnlockTracker
## One sale's numbers, gathered from the signals SaleProcessor sends during it and
## written as one line when the customer is served.
var _sale_xp: int = 0
var _sale_tip: float = 0.0
var _sale_tip_tier: PopupTierRules.Tier = PopupTierRules.Tier.NORMAL
var _sale_entry: SaleReceiptEntry = null
var _sale_reputation: int = 0
## Lines a sale causes (a recommendation, a regular) wait for the sale's own line.
var _sale_notes: PackedStringArray = []


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
	var in_game: bool = not _console.owner is MainMenu
	if in_game:
		registry.add_command_set(PlayerCommands.new(_console.log_line))
		registry.register("loki", _cmd_loki, LOKI_USAGE_TEXT)
	for path: String in MENU_CHEAT_SET_PATHS:
		registry.add_optional_command_set(path)
	if in_game:
		for path: String in GAME_CHEAT_SET_PATHS:
			registry.add_optional_command_set(path)

	_connect_log_sources()
	_console.set_category_hidden(EVENT_CATEGORY, SettingsManager.get_option(EVENTS_HIDDEN_OPTION_KEY, false))
	if in_game:
		_console.add_view(tr(LOG_TAB_TEXT), [&"", EVENT_CATEGORY] as Array[StringName])
		_console.add_view(tr(DIALOGUE_TAB_TEXT), [DIALOGUE_CATEGORY] as Array[StringName])
	_console.log_line(tr(READY_MESSAGE))


func _connect_log_sources() -> void:
	BrewerySignals.style_discovered.connect(_on_style_discovered)
	BrewerySignals.lvv_raid_triggered.connect(_on_lvv_raid_triggered)
	BrewerySignals.recipe_saved.connect(_on_recipe_saved)
	BrewerySignals.batch_bottled.connect(_on_batch_bottled)
	BrewerySignals.daily_bills_paid.connect(_on_daily_bills_paid)
	BrewerySignals.early_day_close_applied.connect(_on_early_day_close_applied)
	SpecialEventManager.special_event_triggered.connect(_on_special_event_triggered)
	TimeManager.day_changed.connect(_on_day_changed)
	BrewerySignals.dialogue_pushed.connect(func(text: String, _special: bool, _slot: int, _pos: Vector2, _time: float, _fade: float) -> void:
		_console.log_line(text, DIALOGUE_CATEGORY))

	BrewerySignals.sale_xp_gained.connect(func(amount: int) -> void: _sale_xp = amount)
	BrewerySignals.sale_tip_gained.connect(func(amount: float) -> void: _sale_tip = amount)
	BrewerySignals.sale_popup_tiers_rated.connect(func(tip_tier: PopupTierRules.Tier, _quality: float) -> void: _sale_tip_tier = tip_tier)
	BrewerySignals.beer_sale_breakdown.connect(func(entry: SaleReceiptEntry) -> void: _sale_entry = entry)
	BrewerySignals.sale_reputation_gained.connect(_on_sale_reputation_gained)
	BrewerySignals.customer_served.connect(_on_customer_served)
	BrewerySignals.friend_recommended.connect(func(data: CustomerData) -> void:
		_log_sale_note(tr(FRIEND_FORMAT) % tr(data.title)))
	BrewerySignals.bad_review_spread.connect(func() -> void: _log_sale_note(tr(BAD_REVIEW_TEXT)))
	BrewerySignals.regular_status_changed.connect(func(title: String, is_regular: bool) -> void:
		_log_sale_note(tr(REGULAR_GAINED_FORMAT if is_regular else REGULAR_LOST_FORMAT) % tr(title)))
	BrewerySignals.batch_stored.connect(func(style_name: String, bottles: int) -> void:
		_log_event(tr(STORED_FORMAT) % [tr(style_name), bottles]))
	BrewerySignals.batch_bulk_sold.connect(func(style_name: String, bottles: int, payout: float) -> void:
		_log_event(tr(BULK_SOLD_FORMAT) % [tr(style_name), bottles, payout]))
	BrewerySignals.keg_shipped_to_bar.connect(func(style_name: String, bar_name: String, bottles: int, payout: float, risk_added: int) -> void:
		_log_event(tr(SHIPPED_FORMAT) % [tr(style_name), tr(bar_name), bottles, payout, risk_added]))
	BrewerySignals.cellar_upgrade_purchased.connect(func(upgrade: CellarUpgradeData, level: int) -> void:
		_log_event(tr(UPGRADE_FORMAT) % [tr(upgrade.perk_name), level]))
	BrewerySignals.bar_fight_started.connect(func(broken_bottles: int) -> void:
		_log_sale_note(tr(BAR_FIGHT_FORMAT) % broken_bottles))
	BrewerySignals.brew_spiced.connect(func(style_name: String, spice_bonus: float) -> void:
		_log_event(ToastText.spiced_brew(style_name, spice_bonus)))
	BrewerySignals.level_up_reached.connect(func(level: int) -> void: _log_event(tr(LEVEL_UP_FORMAT) % level))
	BrewerySignals.reputation_tier_changed.connect(func(tier: ReputationTier, rose: bool) -> void:
		_log_event(tr(TIER_ROSE_FORMAT if rose else TIER_FELL_FORMAT) % tr(tier.tier_name)))
	BrewerySignals.reputation_decayed.connect(func(amount: int, tier: ReputationTier) -> void:
		_log_event(tr(DECAY_FORMAT) % [amount, tr(tier.tier_name)]))
	BrewerySignals.group_visit_announced.connect(func(banner_text: String) -> void: _log_event(tr(banner_text)))
	BrewerySignals.day_event_announced.connect(func(event: DayEventData) -> void: _log_event(tr(event.announcement_text)))
	DailyGoalManager.daily_goal_resolved.connect(func(goal_name: String, succeeded: bool, money: int, reputation: int, xp: int, risk: int) -> void:
		_log_event(ToastText.goal_resolved(goal_name, succeeded, money, reputation, xp, risk)))
	AchievementManager.achievement_unlocked.connect(func(_id: String, title: String) -> void:
		_log_event(tr(ACHIEVEMENT_FORMAT) % tr(title)))
	CustomerRegistry.customer_unlocked.connect(func(title: String) -> void:
		_log_event(tr(CUSTOMER_UNLOCKED_FORMAT) % tr(title)))
	_reset_unlock_tracker(BrewEngine.current_brewery)
	BrewEngine.brewery_changed.connect(_reset_unlock_tracker)
	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)


func _log_event(bbcode_line: String) -> void:
	if not bbcode_line.is_empty():
		_console.log_line(bbcode_line, EVENT_CATEGORY)


## During a sale the line waits for the sale's own line; otherwise it is written now.
func _log_sale_note(bbcode_line: String) -> void:
	if _sale_entry != null:
		_sale_notes.append(bbcode_line)
	else:
		_log_event(bbcode_line)


## `loki` alone flips the event lines; `loki näytä` / `loki piilota` set them.
func _cmd_loki(args: PackedStringArray) -> void:
	var hide_events: bool = not _console.is_category_hidden(EVENT_CATEGORY)
	if not args.is_empty():
		hide_events = args[0].to_lower() == LOKI_HIDE_ARG
	_console.set_category_hidden(EVENT_CATEGORY, hide_events)
	SettingsManager.set_option(EVENTS_HIDDEN_OPTION_KEY, hide_events)
	_console.log_line(tr(EVENTS_HIDDEN_MESSAGE if hide_events else EVENTS_SHOWN_MESSAGE))


## A sale ends with customer_served, so this only writes a line for a customer who left
## without buying anything.
func _on_sale_reputation_gained(amount: int) -> void:
	_sale_reputation = amount
	if _sale_entry == null and amount != 0:
		_log_event(ConsoleEventText.turned_away(tr(UNNAMED_CUSTOMER_TEXT), amount))
		_reset_sale()


func _on_customer_served(data: CustomerData) -> void:
	if _sale_entry != null:
		_log_event(ConsoleEventText.sale(data.title, _sale_entry.bottles_sold, _sale_entry.breakdown.style_name,
			_sale_entry.gross_income, _sale_tip, _sale_tip_tier, _sale_reputation, _sale_xp))
	for note: String in _sale_notes:
		_log_event(note)
	_reset_sale()


func _reset_sale() -> void:
	_sale_xp = 0
	_sale_tip = 0.0
	_sale_tip_tier = PopupTierRules.Tier.NORMAL
	_sale_entry = null
	_sale_reputation = 0
	_sale_notes.clear()


func _reset_unlock_tracker(brewery: Brewery) -> void:
	_unlock_tracker = ReputationUnlockTracker.new(brewery.reputation if brewery != null else 0)


func _on_brewery_state_changed(brewery: Brewery) -> void:
	var names: Array[String] = []
	for ingredient: IngredientData in _unlock_tracker.update(brewery.reputation):
		names.append(ingredient.name)
	if not names.is_empty():
		_log_event(ConsoleEventText.named_list(INGREDIENTS_UNLOCKED_FORMAT, names))


func _on_style_discovered(style: int) -> void:
	_log_event(tr(STYLE_DISCOVERED_FORMAT) % BeerStyle.get_style_string_from_style(style))


func _on_lvv_raid_triggered(confiscated_bottles: int, fine_amount: float, reputation_lost: int) -> void:
	_log_event(tr(RAID_FORMAT) % [confiscated_bottles, fine_amount, reputation_lost])


func _on_recipe_saved(recipe_name: String) -> void:
	_log_event(tr(RECIPE_SAVED_FORMAT) % recipe_name)


func _on_batch_bottled(bottles_lost: int, label_cost: float, style_name: String) -> void:
	if bottles_lost <= 0 and label_cost <= 0.0:
		return
	_log_event(tr(BOTTLED_FORMAT) % [tr(style_name), bottles_lost, label_cost])


func _on_daily_bills_paid(electricity: int, water: int, total: int) -> void:
	_log_event(tr(BILLS_FORMAT) % [electricity, water, total])


func _on_early_day_close_applied(money_cost: float, reputation_cost: int, risk_relief: int, close_count: int) -> void:
	if money_cost <= 0.0 and reputation_cost <= 0 and risk_relief <= 0:
		return
	_log_event(tr(EARLY_CLOSE_FORMAT) % [close_count, money_cost, reputation_cost, risk_relief])


func _on_special_event_triggered(event_data: SpecialEventData) -> void:
	_log_event(tr(SPECIAL_EVENT_FORMAT) % tr(event_data.event_caller_name))


func _on_day_changed(new_day: int) -> void:
	_console.log_line(tr(DAY_CHANGED_FORMAT) % new_day)
