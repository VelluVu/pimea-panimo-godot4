class_name GUI
extends Control


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

var _views : GuiViewSwitcher
var _announcer : GuiAnnouncer

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


func _ready() -> void:
	_announcer = GuiAnnouncer.new()
	add_child(_announcer)
	_announcer.setup(discovery_toast, group_visit_banner, day_event_banner, first_brew_hint_banner, daily_goals_panel, day_recap_window)
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
	_announcer.start()


## The Scene dock's eye toggle is saved into the .tscn, so never trust the saved
## visibility of anything that should always start on: assert it here.
func _assert_default_visibility() -> void:
	dialog_view.show()
	top_panel_background.show()
	top_panel_resources.show()
	shop_entrance_panel.show()
	options_button.show()
	dev_console.show()
	group_visit_banner.show()
	first_brew_hint_banner.show()
	day_event_banner.show()
	daily_goals_panel.show()


## Global shortcuts: Esc (close whatever is open, else open the game menu) and the
## p/k/i/t/u view keys. _unhandled_input() so a focused Control (the console's
## LineEdit) consumes typing first. While Options is open the tree is paused and
## this is never called; see game_menu_window.gd's _input() for Esc there.
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


## Closes every open view and popup in one press; if none was open, opens the game menu.
func _handle_escape_pressed() -> void:
	if not _close_any_open_views():
		GUISignals.game_menu_requested.emit()


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
	GUISignals.game_menu_requested.emit()


func _on_close_day_button_pressed() -> void:
	if CustomerManager.has_active_customers():
		close_day_confirm_window.show()
	else:
		GUISignals.close_day_requested.emit()
