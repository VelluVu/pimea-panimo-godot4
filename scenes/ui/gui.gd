class_name GUI
extends Control


const DISCOVERY_TOAST_FORMAT: String = "Uusi oluttyyli löydetty: %s!"
const GOAL_REWARD_TOAST_FORMAT: String = "%s saavutettu: +%d € / +%d maine!"
const EARLY_CLOSE_TOAST_FORMAT: String = "Ovet suljettu aikaisin: -%.1f €, mainetta -%d, AVI-riski -%d"
const DISCOVERY_TOAST_FLASH_SECONDS: float = 0.15
const DISCOVERY_TOAST_HOLD_SECONDS: float = 2.0
const DISCOVERY_TOAST_FADE_SECONDS: float = 0.6

const GROUP_VISIT_BANNER_FLASH_SECONDS: float = 0.2
const GROUP_VISIT_BANNER_HOLD_SECONDS: float = 4.0
const GROUP_VISIT_BANNER_FADE_SECONDS: float = 0.8

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
@onready var close_day_button : Button = $TopPanel_Resources/CloseDayButton
@onready var close_day_confirm_window : CloseDayConfirmWindow = $CloseDayConfirmWindow
@onready var dialog_view : Control = $DialogView
@onready var top_panel_background : Panel = $TopPanelBackground
@onready var top_panel_resources : Control = $TopPanel_Resources
@onready var options_button : Button = $OptionsButton
@onready var dev_console : Control = $DevConsole
var _discovery_toast_tween : Tween
var _group_visit_banner_tween : Tween
var _first_brew_hint_tween : Tween
## Tracked purely to detect an ingredient-unlock-worthy reputation increase
## in _on_brewery_state_changed() — separate from any similar cache
## top_panel_resources.gd keeps for its own money/reputation delta popups.
var _last_reputation_seen : int = -1

@onready var shop_view : ShopView = $Left_ShopView
@onready var brewery_view : BrewingView = $Left_BrewingView
@onready var brew_preparation_panel : BrewPreparationPanel = $BrewPreparationPanel
@onready var warehouse_view : VBoxContainer = $Right_WarehouseView
@onready var brewery_entrance_panel : Control = $BreweryEntrancePanel
@onready var shop_entrance_panel : ShopEntrancePanel = $ShopEntrancePanel
@onready var recipe_library_window : Control = $RecipeLibraryWindow
@onready var AVI_raid_window : Control = $AviRaidWindow
@onready var daily_goals_panel : DailyGoalsPanel = $DailyGoalsPanel


func _ready() -> void:
	_assert_default_visibility()
	await get_tree().process_frame
	_move_to_bar()
	GUISignals.brewery_view_requested.connect(_on_brewery_button_pressed)
	AVI_raid_window.hide()
	recipe_library_window.hide()
	close_day_button.pressed.connect(_on_close_day_button_pressed)
	BrewerySignals.style_discovered.connect(_on_style_discovered)
	BrewerySignals.daily_goal_reward_granted.connect(_on_daily_goal_reward_granted)
	BrewerySignals.early_day_close_applied.connect(_on_early_day_close_applied)
	BrewerySignals.group_visit_announced.connect(_on_group_visit_announced)
	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)

	var brewery := BrewEngine.current_brewery
	_last_reputation_seen = brewery.reputation if brewery != null else 0

	if TimeManager.day_timer.is_stopped():
		BrewerySignals.brewery_state_changed.connect(_on_first_brew_hint_state_changed)
		_show_first_brew_hint()


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
## unlock condition), and only for a genuine increase — an AVI raid's
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


func _on_daily_goal_reward_granted(goal_name : String, money : int, reputation : int) -> void:
	_show_toast(GOAL_REWARD_TOAST_FORMAT % [goal_name, money, reputation])


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


func _on_group_visit_announced(banner_text : String) -> void:
	group_visit_banner.text = banner_text

	if _group_visit_banner_tween:
		_group_visit_banner_tween.kill()

	group_visit_banner.modulate = Color(1.4, 1.4, 1.0, 0.0)

	_group_visit_banner_tween = create_tween()
	_group_visit_banner_tween.tween_property(group_visit_banner, "modulate", Color(1.4, 1.4, 1.0, 1.0), GROUP_VISIT_BANNER_FLASH_SECONDS)
	_group_visit_banner_tween.tween_property(group_visit_banner, "modulate", Color(1.0, 1.0, 1.0, 1.0), GROUP_VISIT_BANNER_FLASH_SECONDS)
	_group_visit_banner_tween.tween_interval(GROUP_VISIT_BANNER_HOLD_SECONDS)
	_group_visit_banner_tween.tween_property(group_visit_banner, "modulate:a", 0.0, GROUP_VISIT_BANNER_FADE_SECONDS)


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
	first_brew_hint_banner.text = FIRST_BREW_HINT_TEXT
	first_brew_hint_banner.modulate = Color(1.4, 1.4, 1.0, 0.0)

	_first_brew_hint_tween = create_tween()
	_first_brew_hint_tween.tween_property(first_brew_hint_banner, "modulate", Color(1.4, 1.4, 1.0, 1.0), FIRST_BREW_HINT_FLASH_SECONDS)
	_first_brew_hint_tween.tween_property(first_brew_hint_banner, "modulate", Color(1.0, 1.0, 1.0, 1.0), FIRST_BREW_HINT_FLASH_SECONDS)
	_first_brew_hint_tween.tween_interval(FIRST_BREW_HINT_HOLD_SECONDS)
	_first_brew_hint_tween.tween_property(first_brew_hint_banner, "modulate:a", 0.0, FIRST_BREW_HINT_FADE_SECONDS)
	_first_brew_hint_tween.tween_callback(daily_goals_panel.draw_attention)


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
	if _first_brew_hint_tween and _first_brew_hint_tween.is_running():
		_first_brew_hint_tween.kill()

	var quick_fade := create_tween()
	quick_fade.tween_property(first_brew_hint_banner, "modulate:a", 0.0, FIRST_BREW_HINT_FADE_SECONDS)
	quick_fade.tween_callback(daily_goals_panel.draw_attention)


func _show_toast(text : String) -> void:
	discovery_toast.text = text

	if _discovery_toast_tween:
		_discovery_toast_tween.kill()

	discovery_toast.modulate = Color(1.4, 1.4, 1.0, 0.0)

	_discovery_toast_tween = create_tween()
	_discovery_toast_tween.tween_property(discovery_toast, "modulate", Color(1.4, 1.4, 1.0, 1.0), DISCOVERY_TOAST_FLASH_SECONDS)
	_discovery_toast_tween.tween_property(discovery_toast, "modulate", Color(1.0, 1.0, 1.0, 1.0), DISCOVERY_TOAST_FLASH_SECONDS)
	_discovery_toast_tween.tween_interval(DISCOVERY_TOAST_HOLD_SECONDS)
	_discovery_toast_tween.tween_property(discovery_toast, "modulate:a", 0.0, DISCOVERY_TOAST_FADE_SECONDS)
