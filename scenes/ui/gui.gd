class_name GUI
extends Control


const DISCOVERY_TOAST_FORMAT: String = "Uusi oluttyyli löydetty: %s!"
const ACHIEVEMENT_UNLOCKED_TOAST_FORMAT: String = "Saavutus avattu: %s!"
const CUSTOMER_UNLOCKED_TOAST_FORMAT: String = "Uusi asiakas avattu: %s!"
const GOAL_REWARD_TOAST_FORMAT: String = "%s saavutettu: +%d € / +%d maine / +%d XP!"
const GOAL_FAILED_TOAST_FORMAT: String = "%s epäonnistui: %d maine / +%d LVV-riski"
## A special-event daily goal whose event actually triggered but couldn't be
## filled (nothing was demanded of the brewery that it could refuse) fails
## penalty-free — see DailyGoalManager._resolve_goal()'s apply_penalty
## param — so it gets its own toast instead of GOAL_FAILED_TOAST_FORMAT
## reading "0 maine / +0 LVV-riski", which would look like a formatting bug.
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

## Held longer than a group visit's one-liner (it's the day's forecast, not
## an in-the-moment arrival) but well short of FIRST_BREW_HINT's 12s — this
## repeats every day a named event actually lands, so it shouldn't demand
## the same one-time attention the tutorial hint does.
const DAY_EVENT_BANNER_FLASH_SECONDS: float = 0.25
const DAY_EVENT_BANNER_HOLD_SECONDS: float = 6.0
const DAY_EVENT_BANNER_FADE_SECONDS: float = 1.0

## Same flash/hold/fade banner language as group visits (see
## _on_group_visit_announced()) — held much longer since this has a full
## paragraph to read once, at the very start of a run, instead of a
## one-line notification. No button, no box: purely passive, same as any
## other banner here — see _show_first_brew_hint().
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
## One presenter per passive Label (flash/hold/fade + height fitting live in
## BannerPresenter); built in _ready() once the labels exist in the tree.
var _discovery_toast : BannerPresenter
var _group_visit_banner : BannerPresenter
var _first_brew_hint : BannerPresenter
var _day_event_banner : BannerPresenter
## Tracked purely to detect an ingredient-unlock-worthy reputation increase
## in _on_brewery_state_changed() — separate from any similar cache
## top_panel_resources.gd keeps for its own money/reputation delta popups.
var _last_reputation_seen : int = -1

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
	_assert_default_visibility()
	# The goals panel sits in the scene after the modal windows, so it drew on
	# top of them (e.g. over LvvRaidWindow's right edge). Slot it in just below
	# the first modal so every window covers it instead.
	move_child(daily_goals_panel, lvv_raid_window.get_index())
	# Same for the passive banners: an in-the-moment banner drawing over an
	# open modal (seen over LvvRaidWindow) collides with the modal's own text.
	for banner : Label in [group_visit_banner, first_brew_hint_banner, day_event_banner]:
		move_child(banner, lvv_raid_window.get_index())
	await get_tree().process_frame
	_move_to_bar()
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
	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)

	var brewery := BrewEngine.current_brewery
	_last_reputation_seen = brewery.reputation if brewery != null else 0

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


## The Scene dock's per-node "eye" visibility toggle is a real property
## change, not an editor-only preview — it gets saved into the .tscn, and
## it's routine to hide these while editing the 2D view underneath. Never
## trust the saved default for anything that should always start on:
## assert it here instead, regardless of whatever's on disk. (The views
## _move_to_bar() hides right after this don't need listing — it always
## sets their state explicitly anyway.)
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


func _move_to_shop() -> void:
	brewery_view.hide()
	brew_preparation_panel.hide()
	shop_entrance_panel.deactivate_shop_panel()
	brewery_entrance_panel.hide()
	shop_view.show()
	GUISignals.bar_view_exited.emit()


## shop_entrance_panel stays ACTIVE here (unlike _move_to_shop(), which
## deactivates it) — from the brewery view the player can click straight
## through to the shop. Deliberately NOT symmetric: BreweryHoverArea's own
## input_pickable is already gated to the neutral bar view only (see its
## bar_view_exited/entered handlers), so there's no equivalent "jump
## straight to brewery" click from the shop view — that direction stays
## off to avoid an accidental swap while the player is mid-shopping.
func _move_to_brewery() -> void:
	shop_view.hide()
	shop_entrance_panel.activate_shop_panel()
	brewery_entrance_panel.hide()
	brewery_view.show()
	brew_preparation_panel.show()
	GUISignals.bar_view_exited.emit()


func _move_to_bar() -> void:
	shop_view.hide()
	brewery_view.hide()
	brew_preparation_panel.hide()
	shop_entrance_panel.activate_shop_panel()
	brewery_entrance_panel.show()
	GUISignals.bar_view_entered.emit()


## Global keyboard shortcuts: Esc (close whatever's open, or open Options if
## nothing is) and the p/k/i/t/u view shortcuts below. _unhandled_input(),
## not _input(): a focused Control (the console's LineEdit, a button, ...)
## already consumes ordinary key events via Godot's own GUI layer before
## they'd ever reach here, so typing in the console can't double-fire a
## shortcut without any extra guarding — the explicit is_console_active()
## check below is just belt-and-suspenders. While Options is open the whole
## SceneTree is paused and this node is ordinary PROCESS_MODE_INHERIT, so
## Godot simply never calls this at all — see options_window.gd's own
## _input() for how Esc still reaches Options itself in that state.
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
			_toggle_brewery_view()
		KEY_K:
			_toggle_shop_view()
		KEY_I:
			_toggle_warehouse_view()
		KEY_T:
			_toggle_run_effects_window()
		KEY_U:
			_toggle_receipt_log_window()
		_:
			return

	get_viewport().set_input_as_handled()


## Closes whatever's currently open (the active brewery/shop view and any
## popup window) in a single press; if nothing was open, opens Options
## instead, mirroring a typical pause-menu Esc.
func _handle_escape_pressed() -> void:
	if not _close_any_open_views():
		GUISignals.options_requested.emit()


func _close_any_open_views() -> bool:
	var closed_something := false

	if brewery_view.visible or shop_view.visible:
		_move_to_bar()
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


func _toggle_brewery_view() -> void:
	if brewery_view.visible:
		_move_to_bar()
	else:
		_move_to_brewery()


func _toggle_shop_view() -> void:
	if shop_view.visible:
		_move_to_bar()
	else:
		_move_to_shop()


func _toggle_warehouse_view() -> void:
	if warehouse_view.visible:
		warehouse_view.hide_warehouse_view()
	else:
		warehouse_view.show_warehouse_view()


## Routed through the same signal the button uses (not a direct .show())
## so the window's content actually refreshes on open — see its own
## _on_run_effects_requested().
func _toggle_run_effects_window() -> void:
	if run_effects_window.visible:
		run_effects_window.hide()
	else:
		GUISignals.run_effects_requested.emit()


## Same reasoning as _toggle_run_effects_window() above.
func _toggle_receipt_log_window() -> void:
	if sale_receipt_log_window.visible:
		sale_receipt_log_window.hide()
	else:
		GUISignals.receipt_log_requested.emit()


func _on_shop_button_pressed() -> void:
	_move_to_shop()


func _on_back_button_pressed() -> void:
	_move_to_bar()


func _on_brewery_button_pressed() -> void:
	if brewery_view.visible or shop_view.visible:
		return
	_move_to_brewery()


func _on_options_button_pressed() -> void:
	GUISignals.options_requested.emit()


func _on_close_day_button_pressed() -> void:
	if CustomerManager.has_active_customers():
		close_day_confirm_window.show()
	else:
		GUISignals.close_day_requested.emit()


## Only reputation is checked (ingredient min_reputation is the only
## unlock condition), and only for a genuine increase — an LVV raid's
## reputation penalty should never announce a "newly unlocked" hop that
## was actually already available before the drop.
func _on_brewery_state_changed(brewery : Brewery) -> void:
	var new_reputation : int = brewery.reputation
	if new_reputation <= _last_reputation_seen:
		_last_reputation_seen = new_reputation
		return

	for ingredient : IngredientData in IngredientDatabase.database.values():
		if ingredient.min_reputation > _last_reputation_seen and ingredient.min_reputation <= new_reputation:
			_show_toast(StringContainer.INGREDIENT_UNLOCKED_TOAST_FORMAT % ingredient.name)

	_last_reputation_seen = new_reputation


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


## Brewery.apply_early_close_cost() already computes these numbers whenever
## the player force-closes the day (see TimeManager.force_advance_day()) —
## without this, money/reputation just shift with no on-screen explanation
## of why, the same unexplained-stat-change problem the reputation popup's
## euro-suffix bug caused for a different stat (see playtest_notes_5/_6).
## Guards the same way dev_console.gd's own log handler for this signal
## does: skip the toast entirely on a close so late in the day that all
## three numbers rounded to zero.
func _on_early_day_close_applied(money_cost : float, reputation_cost : int, risk_relief : int, _close_count : int) -> void:
	if money_cost <= 0.0 and reputation_cost <= 0 and risk_relief <= 0:
		return
	_show_toast(EARLY_CLOSE_TOAST_FORMAT % [money_cost, reputation_cost, risk_relief])


## Mirrors _on_ingredient_purchase_underfunded() below — the shop UI
## already disables reputation-locked entries (see BrewerySignals.
## ingredient_purchase_locked's docstring), but the toast costs nothing
## and keeps both failure paths off Brewery consistently surfaced.
func _on_ingredient_purchase_locked(ingredient_name : String, required_reputation : int) -> void:
	_show_toast(INGREDIENT_LOCKED_TOAST_FORMAT % [ingredient_name, required_reputation])


## Previously a player clicking "Osta" with too little money just saw
## nothing happen (Brewery._on_buy_ingredient() only print()'d to console)
## — see the ingredient_purchase_underfunded signal's docstring.
func _on_ingredient_purchase_underfunded(ingredient_name : String, price : int, money : float) -> void:
	_show_toast(INGREDIENT_UNDERFUNDED_TOAST_FORMAT % [ingredient_name, price, money])


func _on_group_visit_announced(banner_text : String) -> void:
	_group_visit_banner.present(banner_text)


## The day's secretly-rolled forecast (see DayEventManager) — same flash/
## hold/fade shape as _on_group_visit_announced(), just its own timing/
## color so a themed day's announcement doesn't read as an in-the-moment
## crowd arrival.
##
## DayEventManager and DayRecapWindow both react to TimeManager.day_changed,
## so the banner used to fade in right on top of the recap and hide its
## lines. Wait a frame (so the recap's own handler has run), then hold the
## banner until the recap is dismissed.
func _on_day_event_announced(event : DayEventData) -> void:
	_day_event_announce_serial += 1
	var serial : int = _day_event_announce_serial

	await get_tree().process_frame
	if day_recap_window.visible:
		await day_recap_window.hidden
	if serial != _day_event_announce_serial:
		return

	_day_event_banner.present(event.announcement_text)


## Shown once at the start of a fresh run, while TimeManager.day_timer is
## still stopped (see its own _on_brewery_state_changed()) — explains why
## the clock isn't ticking and no customers are showing up yet, instead of
## that silently reading like a bug. Same flash/hold/fade shape as
## _on_group_visit_announced() above, just held far longer (a paragraph to
## read, not a one-liner) and with no trigger signal of its own — this is
## the trigger, called directly from _ready() when the clock hasn't
## started yet. Ends by pointing the player at DailyGoalsPanel
## (draw_attention()) — the banner explains WHY nothing's happening yet,
## the goals panel is WHERE to look for what to actually do about it
## (it's where the tutorial checklist lives), so one should hand off to
## the other instead of leaving the player to find it on their own.
func _show_first_brew_hint() -> void:
	_first_brew_hint.present(FIRST_BREW_HINT_TEXT)


## Cuts the hint short the moment the clock actually starts (first brew
## completed) — a purely passive banner like this has no button to
## dismiss it early, so without this it would sit onscreen for its full
## hold duration even after "doors are still closed" has stopped being
## true. One-shot: disconnects itself once the clock has started, since
## nothing past that point should ever touch this banner again. Still
## hands off to DailyGoalsPanel afterward, same as the natural fade-out —
## the player just brewed their first batch, so the goals panel (tutorial
## checklist, then daily goals once that's done) is exactly what they
## should look at next either way.
func _on_first_brew_hint_state_changed(_brewery : Brewery) -> void:
	if TimeManager.day_timer.is_stopped():
		return

	BrewerySignals.brewery_state_changed.disconnect(_on_first_brew_hint_state_changed)
	_first_brew_hint.dismiss_early()


func _show_toast(text : String) -> void:
	_discovery_toast.present(text)
