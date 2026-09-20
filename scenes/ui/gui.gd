class_name GUI
extends Control


const DISCOVERY_TOAST_FORMAT: String = "Uusi oluttyyli löydetty: %s!"
const ACHIEVEMENT_UNLOCKED_TOAST_FORMAT: String = "Saavutus avattu: %s!"
const CUSTOMER_UNLOCKED_TOAST_FORMAT: String = "Uusi asiakas avattu: %s!"
const GOAL_REWARD_TOAST_FORMAT: String = "%s saavutettu: +%d € / +%d maine / +%d XP!"
const GOAL_FAILED_TOAST_FORMAT: String = "%s epäonnistui: %d maine / +%d LVV-riski"
## A special-event goal that triggered but couldn't be filled fails penalty-free, so it
## gets its own toast instead of a confusing "0 maine / +0 LVV-riski".
const GOAL_FAILED_NO_PENALTY_TOAST_FORMAT: String = "%s epäonnistui: ei seurauksia"
const EARLY_CLOSE_TOAST_FORMAT: String = "Ovet suljettu aikaisin: -%.1f €, mainetta -%d, LVV-riski -%d"
const INGREDIENT_LOCKED_TOAST_FORMAT: String = "%s vaatii vähintään %d mainetta."
const INGREDIENT_UNDERFUNDED_TOAST_FORMAT: String = "Ei varaa: %s maksaa %d €, kassassa %.1f €."
const DISCOVERY_TOAST_FLASH_SECONDS: float = 0.15
const DISCOVERY_TOAST_HOLD_SECONDS: float = 2.0
const DISCOVERY_TOAST_FADE_SECONDS: float = 0.6

const GROUP_VISIT_BANNER_FLASH_SECONDS: float = 0.2
const GROUP_VISIT_BANNER_HOLD_SECONDS: float = 4.0
const GROUP_VISIT_BANNER_FADE_SECONDS: float = 0.8

## Held longer than a group visit's one-liner, shorter than FIRST_BREW_HINT: it repeats
## on every day a named event lands.
const DAY_EVENT_BANNER_FLASH_SECONDS: float = 0.25
const DAY_EVENT_BANNER_HOLD_SECONDS: float = 6.0
const DAY_EVENT_BANNER_FADE_SECONDS: float = 1.0

## Same banner language as group visits, held much longer since it is a paragraph
## read once at the start of a run. Purely passive, see _show_first_brew_hint().
const FIRST_BREW_HINT_TEXT: String = "Ovet ovat vielä hetken kiinni. Osta ainekset ja pane ensimmäinen olut rauhassa."
const FIRST_BREW_HINT_FLASH_SECONDS: float = 0.25
const FIRST_BREW_HINT_HOLD_SECONDS: float = 12.0
const FIRST_BREW_HINT_FADE_SECONDS: float = 1.2

@onready var discovery_toast : Label = $DiscoveryToast
@onready var group_visit_banner : Label = $GroupVisitBanner
@onready var first_brew_hint_banner : Label = $FirstBrewHintBanner
@onready var day_event_banner : Label = $DayEventBanner
@onready var close_day_button : Button = $TopPanel_Resources/CloseDayButton
@onready var close_day_confirm_window : CloseDayConfirmWindow = $CloseDayConfirmWindow
@onready var dialog_view : Control = $DialogView
@onready var top_panel_background : Panel = $TopPanelBackground
@onready var top_panel_resources : Control = $TopPanel_Resources
@onready var options_button : Button = $OptionsButton
@onready var dev_console : DevConsole = $DevConsole
@onready var options_window : OptionsWindow = $OptionsWindow
@onready var run_effects_window : RunEffectsWindow = $RunEffectsWindow
@onready var sale_receipt_log_window : SaleReceiptLogWindow = $SaleReceiptLogWindow
## One presenter per passive Label, built in _ready() once the labels exist.
var _discovery_toast : BannerPresenter
var _group_visit_banner : BannerPresenter
var _first_brew_hint : BannerPresenter
var _day_event_banner : BannerPresenter
var _reputation_tracker : ReputationUnlockTracker
var _views : GuiViewSwitcher

@onready var shop_view : ShopView = $Left_ShopView
@onready var brewery_view : BrewingView = $Left_BrewingView
@onready var brew_preparation_panel : BrewPreparationPanel = $BrewPreparationPanel
@onready var warehouse_view : RightWarehouseView = $Right_WarehouseView
@onready var brewery_entrance_panel : Control = $BreweryEntrancePanel
@onready var shop_entrance_panel : ShopEntrancePanel = $ShopEntrancePanel
@onready var recipe_library_window : Control = $RecipeLibraryWindow
@onready var lvv_raid_window : Control = $LvvRaidWindow
@onready var daily_goals_panel : DailyGoalsPanel = $DailyGoalsPanel
@onready var day_recap_window : DayRecapWindow = $DayRecapWindow

## Bumped on every announcement so a banner still waiting out the recap
## window is dropped if a newer day's announcement arrives first.
var _day_event_announce_serial : int = 0


func _ready() -> void:
	_setup_banner_presenters()
	_views = GuiViewSwitcher.new(shop_view, brewery_view, brew_preparation_panel, shop_entrance_panel, brewery_entrance_panel)
	_assert_default_visibility()
	# Slot the goals panel and the passive banners just below the first modal so open
	# windows cover them instead of colliding with their text.
	move_child(daily_goals_panel, lvv_raid_window.get_index())
	for banner : Label in [group_visit_banner, first_brew_hint_banner, day_event_banner]:
		move_child(banner, lvv_raid_window.get_index())
	await get_tree().process_frame
	_views.show_bar()
	GUISignals.brewery_view_requested.connect(_on_brewery_button_pressed)
	lvv_raid_window.hide()
	recipe_library_window.hide()
	close_day_button.pressed.connect(_on_close_day_button_pressed)
	BrewerySignals.style_discovered.connect(_on_style_discovered)
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)
	CustomerRegistry.customer_unlocked.connect(_on_customer_unlocked)
	DailyGoalManager.daily_goal_resolved.connect(_on_daily_goal_resolved)
	BrewerySignals.early_day_close_applied.connect(_on_early_day_close_applied)
	BrewerySignals.ingredient_purchase_locked.connect(_on_ingredient_purchase_locked)
	BrewerySignals.ingredient_purchase_underfunded.connect(_on_ingredient_purchase_underfunded)
	BrewerySignals.group_visit_announced.connect(_on_group_visit_announced)
	BrewerySignals.day_event_announced.connect(_on_day_event_announced)
	var brewery := BrewEngine.current_brewery
	_reputation_tracker = ReputationUnlockTracker.new(brewery.reputation if brewery != null else 0)
	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)

	if TimeManager.day_timer.is_stopped():
		BrewerySignals.brewery_state_changed.connect(_on_first_brew_hint_state_changed)
		_show_first_brew_hint()


func _setup_banner_presenters() -> void:
	_discovery_toast = BannerPresenter.new(discovery_toast, DISCOVERY_TOAST_FLASH_SECONDS, DISCOVERY_TOAST_HOLD_SECONDS, DISCOVERY_TOAST_FADE_SECONDS, true, false)
	_group_visit_banner = BannerPresenter.new(group_visit_banner, GROUP_VISIT_BANNER_FLASH_SECONDS, GROUP_VISIT_BANNER_HOLD_SECONDS, GROUP_VISIT_BANNER_FADE_SECONDS)
	# Plain alpha fade-in, not the overexposed flash: it's the day's forecast,
	# not an in-the-moment arrival.
	_day_event_banner = BannerPresenter.new(day_event_banner, DAY_EVENT_BANNER_FLASH_SECONDS, DAY_EVENT_BANNER_HOLD_SECONDS, DAY_EVENT_BANNER_FADE_SECONDS, false)
	# Natural end and early dismissal both hide it and hand off to the goals panel.
	_first_brew_hint = BannerPresenter.new(first_brew_hint_banner, FIRST_BREW_HINT_FLASH_SECONDS, FIRST_BREW_HINT_HOLD_SECONDS, FIRST_BREW_HINT_FADE_SECONDS, true, true, true, daily_goals_panel.draw_attention)


## The Scene dock's eye toggle is saved into the .tscn, so never trust the saved
## visibility of anything that should always start on: assert it here.
func _assert_default_visibility() -> void:
	dialog_view.show()
	top_panel_background.show()
	top_panel_resources.show()
	shop_entrance_panel.show()
	options_button.show()
	dev_console.show()
	discovery_toast.show()
	group_visit_banner.show()
	first_brew_hint_banner.show()
	day_event_banner.show()
	daily_goals_panel.show()


## Global shortcuts: Esc (close whatever is open, else open Options) and the
## p/k/i/t/u view keys. _unhandled_input() so a focused Control (the console's
## LineEdit) consumes typing first. While Options is open the tree is paused and
## this is never called; see options_window.gd's _input() for Esc there.
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	if event.keycode == KEY_ESCAPE:
		_handle_escape_pressed()
		get_viewport().set_input_as_handled()
		return

	if dev_console.is_console_active():
		return

	match event.keycode:
		KEY_P:
			_views.toggle_brewery()
		KEY_K:
			_views.toggle_shop()
		KEY_I:
			_toggle_warehouse_view()
		KEY_T:
			_toggle_run_effects_window()
		KEY_U:
			_toggle_receipt_log_window()
		_:
			return

	get_viewport().set_input_as_handled()


## Closes every open view and popup in one press; if none was open, opens Options.
func _handle_escape_pressed() -> void:
	if not _close_any_open_views():
		GUISignals.options_requested.emit()


func _close_any_open_views() -> bool:
	var closed_something := false

	if _views.is_away_from_bar():
		_views.show_bar()
		closed_something = true
	if recipe_library_window.visible:
		recipe_library_window.hide()
		closed_something = true
	if run_effects_window.visible:
		run_effects_window.hide()
		closed_something = true
	if sale_receipt_log_window.visible:
		sale_receipt_log_window.hide()
		closed_something = true
	if warehouse_view.visible:
		warehouse_view.hide_warehouse_view()
		closed_something = true

	return closed_something


func _toggle_warehouse_view() -> void:
	if warehouse_view.visible:
		warehouse_view.hide_warehouse_view()
	else:
		warehouse_view.show_warehouse_view()


## Routed through the button's signal so the window refreshes its content on open.
func _toggle_run_effects_window() -> void:
	if run_effects_window.visible:
		run_effects_window.hide()
	else:
		GUISignals.run_effects_requested.emit()


func _toggle_receipt_log_window() -> void:
	if sale_receipt_log_window.visible:
		sale_receipt_log_window.hide()
	else:
		GUISignals.receipt_log_requested.emit()


func _on_shop_button_pressed() -> void:
	_views.show_shop()


func _on_back_button_pressed() -> void:
	_views.show_bar()


func _on_brewery_button_pressed() -> void:
	if _views.is_away_from_bar():
		return
	_views.show_brewery()


func _on_options_button_pressed() -> void:
	GUISignals.options_requested.emit()


func _on_close_day_button_pressed() -> void:
	if CustomerManager.has_active_customers():
		close_day_confirm_window.show()
	else:
		GUISignals.close_day_requested.emit()


func _on_brewery_state_changed(brewery : Brewery) -> void:
	for ingredient : IngredientData in _reputation_tracker.update(brewery.reputation):
		_show_toast(StringContainer.INGREDIENT_UNLOCKED_TOAST_FORMAT % ingredient.name)


func _on_style_discovered(style : int) -> void:
	_show_toast(DISCOVERY_TOAST_FORMAT % BeerStyle.get_style_string_from_style(style))


func _on_achievement_unlocked(_achievement_id : String, title : String) -> void:
	_show_toast(ACHIEVEMENT_UNLOCKED_TOAST_FORMAT % title)


func _on_customer_unlocked(title : String) -> void:
	_show_toast(CUSTOMER_UNLOCKED_TOAST_FORMAT % title)


func _on_daily_goal_resolved(goal_name : String, succeeded : bool, money : int, reputation : int, xp : int, risk : int) -> void:
	if succeeded:
		_show_toast(GOAL_REWARD_TOAST_FORMAT % [goal_name, money, reputation, xp])
	elif reputation == 0 and risk == 0:
		_show_toast(GOAL_FAILED_NO_PENALTY_TOAST_FORMAT % goal_name)
	else:
		_show_toast(GOAL_FAILED_TOAST_FORMAT % [goal_name, reputation, risk])


## Explains the money/reputation shift of a forced close. Skipped when all three
## numbers rounded to zero (a very late close).
func _on_early_day_close_applied(money_cost : float, reputation_cost : int, risk_relief : int, _close_count : int) -> void:
	if money_cost <= 0.0 and reputation_cost <= 0 and risk_relief <= 0:
		return
	_show_toast(EARLY_CLOSE_TOAST_FORMAT % [money_cost, reputation_cost, risk_relief])


## The shop already disables locked entries; the toast keeps both purchase failures surfaced.
func _on_ingredient_purchase_locked(ingredient_name : String, required_reputation : int) -> void:
	_show_toast(INGREDIENT_LOCKED_TOAST_FORMAT % [ingredient_name, required_reputation])


## Tells a player who clicked "Osta" without enough money why nothing happened.
func _on_ingredient_purchase_underfunded(ingredient_name : String, price : int, money : float) -> void:
	_show_toast(INGREDIENT_UNDERFUNDED_TOAST_FORMAT % [ingredient_name, price, money])


func _on_group_visit_announced(banner_text : String) -> void:
	_group_visit_banner.present(banner_text)


## The day's forecast banner (see DayEventManager). It waits for the recap window,
## since both react to TimeManager.day_changed and the banner would fade in on top of it.
func _on_day_event_announced(event : DayEventData) -> void:
	_day_event_announce_serial += 1
	var serial : int = _day_event_announce_serial

	await get_tree().process_frame
	if day_recap_window.visible:
		await day_recap_window.hidden
	if serial != _day_event_announce_serial:
		return

	_day_event_banner.present(event.announcement_text)


## Shown at the start of a fresh run while the day clock is still stopped, so the
## missing customers don't read as a bug. Ends by pointing at DailyGoalsPanel.
func _show_first_brew_hint() -> void:
	_first_brew_hint.present(FIRST_BREW_HINT_TEXT)


## Dismisses the hint once the clock starts (first brew done). One-shot, and hands
## off to DailyGoalsPanel like the natural fade-out.
func _on_first_brew_hint_state_changed(_brewery : Brewery) -> void:
	if TimeManager.day_timer.is_stopped():
		return

	BrewerySignals.brewery_state_changed.disconnect(_on_first_brew_hint_state_changed)
	_first_brew_hint.dismiss_early()


func _show_toast(text : String) -> void:
	_discovery_toast.present(text)
