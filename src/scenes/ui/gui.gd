class_name GUI
extends Control

## Gap between the options button and the unlock cards, and below the cards.
const UNLOCK_CARDS_MARGIN: float = 4.0
const UPGRADES_BUTTON_TEXT: String = "🔧"
const UPGRADES_TOOLTIP_FORMAT: String = "Kellarin parannukset (%s)"
const UPGRADES_ICON_FONT_SIZE: int = 32
## The first-brew hint's left anchor, right anchor and vertical centre: over the bar, or
## beside the open brewery or shop window (which ends at 0.57) and below the goals list.
const HINT_ANCHORS_AT_BAR: Vector3 = Vector3(0.1, 0.9, 0.5)
const HINT_ANCHORS_BESIDE_VIEWS: Vector3 = Vector3(0.6, 0.98, 0.62)

@onready var discovery_toast : Label = $DiscoveryToast
@onready var group_visit_banner : Label = $GroupVisitBanner
@onready var first_brew_hint_banner : Label = $FirstBrewHintBanner
@onready var day_event_banner : Label = $DayEventBanner
@onready var close_day_button : Button = $TopPanel_Resources/CloseDayButton
@onready var game_speed_button : GameSpeedButton = $TopPanel_Resources/GameSpeedButton
@onready var close_day_confirm_window : CloseDayConfirmWindow = $CloseDayConfirmWindow
@onready var dialog_view : Control = $DialogView
@onready var special_events_container : VBoxContainer = $DialogView/SpecialEventsContainer
@onready var top_panel_background : Panel = $TopPanelBackground
@onready var top_panel_resources : TopPanelResources = $TopPanel_Resources
@onready var options_button : Button = $OptionsButton
@onready var dev_console : DevConsole = $DevConsole
@onready var options_window : OptionsWindow = $OptionsWindow
@onready var run_effects_window : RunEffectsWindow = $RunEffectsWindow
@onready var cellar_upgrades_window : CellarUpgradesWindow = $CellarUpgradesWindow
@onready var sale_receipt_log_window : SaleReceiptLogWindow = $SaleReceiptLogWindow
@onready var customer_book_window : CustomerBookWindow = $CustomerBookWindow

var _views : GuiViewSwitcher
var _announcer : GuiAnnouncer
var _special_events : SpecialEventPresenter
## Built in code; made here so the first bind_brewery reaches it before it joins the tree.
var _brew_day_window : BrewDayWindow = BrewDayWindow.new()
## Built in code; Aatu's talk points at it.
var upgrades_button : TooltipButton
var _unlock_cards : PopupCardStack

@onready var shop_view : ShopView = $Left_ShopView
@onready var brewery_view : BrewingView = $Left_BrewingView
@onready var brew_preparation_panel : BrewPreparationPanel = $BrewPreparationPanel
@onready var joined_window_frame : Panel = $JoinedWindowFrame
@onready var warehouse_view : RightWarehouseView = $Right_WarehouseView
@onready var brewery_entrance_panel : BreweryEntrancePanel = $BreweryEntrancePanel
@onready var shop_entrance_panel : ShopEntrancePanel = $ShopEntrancePanel
@onready var recipe_library_window : RecipeLibraryWindow = $RecipeLibraryWindow
@onready var recipe_shelf_label : Label = $RecipeShelfLabel
@onready var lvv_raid_window : Control = $LvvRaidWindow
@onready var daily_goals_panel : DailyGoalsPanel = $DailyGoalsPanel
@onready var day_recap_window : DayRecapWindow = $DayRecapWindow


func _ready() -> void:
	# First, before any view opens and reads it.
	_bind_brewery(BrewEngine.current_brewery)
	BrewEngine.brewery_changed.connect(_bind_brewery)
	_announcer = GuiAnnouncer.new()
	add_child(_announcer)
	_announcer.setup(discovery_toast, group_visit_banner, day_event_banner, first_brew_hint_banner, daily_goals_panel, day_recap_window, _make_unlock_cards())
	_special_events = SpecialEventPresenter.new(special_events_container)
	_views = GuiViewSwitcher.new(shop_view, brewery_view, brew_preparation_panel, shop_entrance_panel, brewery_entrance_panel)
	_assert_default_visibility()
	brew_preparation_panel.close_requested.connect(_on_back_button_pressed)
	# One frame around the brewery or shop and the recipe panel, so they read as one window.
	brew_preparation_panel.visibility_changed.connect(func() -> void: joined_window_frame.visible = brew_preparation_panel.visible)
	# The first-brew hint steps aside while a view is open, instead of hiding behind it.
	GUISignals.bar_view_exited.connect(_place_hint.bind(HINT_ANCHORS_BESIDE_VIEWS))
	GUISignals.bar_view_entered.connect(_place_hint.bind(HINT_ANCHORS_AT_BAR))
	_add_upgrades_button()
	_add_next_step_guide()
	_add_shortcut_hints()
	add_child(TouchTooltip.new())
	add_child(PortraitNotice.new())
	add_child(_brew_day_window)
	add_child(KegWashWindow.new())
	add_child(FocusPause.new())
	var touch_hints := TouchHints.new()
	add_child(touch_hints)
	if DisplayServer.is_touchscreen_available():
		TouchHints.make_button(options_button).pressed.connect(func() -> void:
			if not _views.is_away_from_bar():
				touch_hints.toggle())
	# The goals panel and the passive banners go below the first panel, so open panels cover
	# them instead of colliding.
	for passive : Control in [daily_goals_panel, group_visit_banner, first_brew_hint_banner, day_event_banner]:
		move_child(passive, warehouse_view.get_index())
	await get_tree().process_frame
	_views.show_bar()
	GUISignals.brewery_view_requested.connect(_on_brewery_button_pressed)
	# A finished brew is the brewery's job done, so the player lands back at the bar to sell
	# it. Only on finishing: a cancelled brew day leaves the table and the view as they were.
	GUISignals.brew_day_finished.connect(_views.show_bar.unbind(1))
	lvv_raid_window.hide()
	recipe_library_window.hide()
	close_day_button.pressed.connect(_on_close_day_button_pressed)
	_announcer.start()
	InputManager.shortcut_pressed.connect(_on_shortcut_pressed)
	InputManager.cancel_pressed.connect(_on_cancel_pressed)


## The panels get the run's brewery from here instead of reading BrewEngine themselves.
## The top bar goes last: it broadcasts the brewery's starting values, which the others
## should hear already bound.
func _bind_brewery(brewery : Brewery) -> void:
	shop_view.bind_brewery(brewery)
	brewery_view.bind_brewery(brewery)
	brew_preparation_panel.bind_brewery(brewery)
	day_recap_window.bind_brewery(brewery)
	daily_goals_panel.bind_brewery(brewery)
	run_effects_window.bind_brewery(brewery)
	cellar_upgrades_window.bind_brewery(brewery)
	sale_receipt_log_window.bind_brewery(brewery)
	customer_book_window.bind_brewery(brewery)
	recipe_library_window.bind_brewery(brewery)
	_brew_day_window.bind_brewery(brewery)
	top_panel_resources.bind_brewery(brewery)


## The cellar upgrades sat in a corner of the shop where few found them; the top bar is
## always in sight.
func _add_upgrades_button() -> void:
	upgrades_button = TooltipButton.new()
	upgrades_button.text = UPGRADES_BUTTON_TEXT
	upgrades_button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	# At the default 16 the 9 px wrench read as a stray line; icons scale in steps of 16.
	upgrades_button.add_theme_font_size_override(&"font_size", UPGRADES_ICON_FONT_SIZE)
	upgrades_button.tooltip_text = tr(UPGRADES_TOOLTIP_FORMAT) % InputManager.get_binding_text(InputManager.ACTION_TOGGLE_UPGRADES)
	upgrades_button.focus_mode = Control.FOCUS_NONE
	var side : float = game_speed_button.get_combined_minimum_size().y
	upgrades_button.custom_minimum_size = Vector2(side, side)
	upgrades_button.pressed.connect(_toggle_cellar_upgrades_window)
	top_panel_resources.add_child(upgrades_button)
	top_panel_resources.move_child(upgrades_button, game_speed_button.get_index())


## Each cellar spot's hover label names its key, so the shortcuts are learned by pointing.
func _add_shortcut_hints() -> void:
	var labels : Dictionary = {
		InputManager.ACTION_TOGGLE_BREWERY: brewery_entrance_panel.brewery_label,
		InputManager.ACTION_TOGGLE_SHOP: shop_entrance_panel.shop_label,
		InputManager.ACTION_TOGGLE_WAREHOUSE: $WarehouseLabel,
		InputManager.ACTION_TOGGLE_RECIPE_LIBRARY: recipe_shelf_label,
		InputManager.ACTION_TOGGLE_BREWERY_BOOK: $CustomerBookLabel,
		InputManager.ACTION_TOGGLE_RECEIPT_LOG: $ReceiptMachineLabel,
		InputManager.ACTION_TOGGLE_RUN_EFFECTS: $ChalkboardLabel,
	}
	for action : StringName in labels:
		ShortcutHint.attach(labels[action], action)


## The pointer sits at least above the bar's views, so windows opened over them cover it;
## Aatu's speech box sits just under the pointer, so its frames draw over him.
func _add_next_step_guide() -> void:
	var views : Array[Control] = [shop_view, brewery_view, brew_preparation_panel, brewery_entrance_panel]
	var top_view : Control = views[0]
	for view : Control in views:
		if view.get_index() > top_view.get_index():
			top_view = view
	var pointer := NextStepPointer.new(top_view)
	pointer.name = "NextStepPointer"
	add_child(pointer)
	move_child(pointer, top_view.get_index() + 1)
	var speech := GuideSpeechBox.new()
	speech.name = "GuideSpeechBox"
	add_child(speech)
	move_child(speech, pointer.get_index())
	# Hidden until the guide's first line, so that showing it lifts the cards.
	speech.hide()
	speech.visibility_changed.connect(_lift_unlock_cards.bind(speech))
	var guide := NextStepGuide.new()
	var places : Dictionary = {brewery = brewery_entrance_panel, shop = shop_entrance_panel, recipe_shelf = recipe_shelf_label, brewery_book = $CustomerBookLabel, warehouse = $WarehouseLabel, upgrades = upgrades_button}
	guide.setup(pointer, speech, daily_goals_panel, places, recipe_library_window, brewery_view, shop_view, brew_preparation_panel)
	add_child(guide)


## `anchors` is the hint's left anchor, right anchor and vertical centre. It wraps, since
## the space beside the views is half the bar's.
func _place_hint(anchors : Vector3) -> void:
	first_brew_hint_banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# The scene's 540 px maximum set the wrap width too, so the text ran past the
	# narrow space; the anchors alone keep it in place.
	first_brew_hint_banner.custom_maximum_size = Vector2(-1, -1)
	first_brew_hint_banner.anchor_left = anchors.x
	first_brew_hint_banner.anchor_right = anchors.y
	first_brew_hint_banner.anchor_top = anchors.z
	first_brew_hint_banner.anchor_bottom = anchors.z
	# Growth from the wider unwrapped text stays in the offsets otherwise.
	first_brew_hint_banner.offset_left = 0.0
	first_brew_hint_banner.offset_right = 0.0


## Cards rise from the bottom left, beside the options button. Above the open panels, so an
## unlock while brewing still shows; below the console and the menus.
func _make_unlock_cards() -> PopupCardStack:
	var cards := PopupCardStack.new()
	cards.name = "UnlockCards"
	add_child(cards)
	move_child(cards, dev_console.get_index())
	cards.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	cards.offset_left = options_button.offset_right + UNLOCK_CARDS_MARGIN
	cards.offset_right = cards.offset_left
	cards.offset_top = -UNLOCK_CARDS_MARGIN
	cards.offset_bottom = -UNLOCK_CARDS_MARGIN
	_unlock_cards = cards
	return cards


## Aatu's box sits in the cards' corner, and the first brew's achievement arrives just as he
## starts talking: while he speaks, the cards rise from above his box.
func _lift_unlock_cards(speech : GuideSpeechBox) -> void:
	var bottom : float = -UNLOCK_CARDS_MARGIN
	if speech.visible:
		bottom = speech.position.y - size.y - UNLOCK_CARDS_MARGIN
	_unlock_cards.offset_top = bottom
	_unlock_cards.offset_bottom = bottom


## The editor's eye toggle is saved into the .tscn, so always-on nodes are forced on here.
func _assert_default_visibility() -> void:
	dialog_view.show()
	top_panel_background.show()
	top_panel_resources.show()
	shop_entrance_panel.show()
	options_button.show()
	# Typing commands needs a keyboard, and the button takes a corner of a small screen.
	# The console shows itself once its key is pressed (DevConsole.hidden_until_opened).
	if DisplayServer.is_touchscreen_available():
		dev_console.hide()
	group_visit_banner.show()
	first_brew_hint_banner.show()
	day_event_banner.show()
	daily_goals_panel.show()


## Shortcuts and Esc arrive as InputManager signals; never while a pausing window is open.
func _on_shortcut_pressed(action: StringName) -> void:
	if dev_console.is_console_active():
		return

	match action:
		InputManager.ACTION_TOGGLE_BREWERY:
			_views.toggle_brewery()
		InputManager.ACTION_TOGGLE_SHOP:
			_views.toggle_shop()
		InputManager.ACTION_TOGGLE_WAREHOUSE:
			_toggle_warehouse_view()
		InputManager.ACTION_TOGGLE_RUN_EFFECTS:
			_toggle_run_effects_window()
		InputManager.ACTION_TOGGLE_RECEIPT_LOG:
			_toggle_receipt_log_window()
		# These two pause the tree, so they close on their own key themselves.
		InputManager.ACTION_TOGGLE_RECIPE_LIBRARY:
			GUISignals.recipe_library_requested.emit()
		InputManager.ACTION_TOGGLE_BREWERY_BOOK:
			GUISignals.customer_book_requested.emit()
		InputManager.ACTION_TOGGLE_UPGRADES:
			_toggle_cellar_upgrades_window()
		# Not while the top bar is hidden, so the speed never changes unseen.
		InputManager.ACTION_GAME_SPEED:
			if game_speed_button.is_visible_in_tree():
				game_speed_button.cycle()


## Closes every open view and popup in one press; if none was open, opens the game menu.
func _on_cancel_pressed() -> void:
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
	if cellar_upgrades_window.visible:
		cellar_upgrades_window.hide()
		closed_something = true
	if sale_receipt_log_window.visible:
		sale_receipt_log_window.hide()
		closed_something = true
	if customer_book_window.visible:
		customer_book_window.hide()
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


func _toggle_cellar_upgrades_window() -> void:
	if cellar_upgrades_window.visible:
		cellar_upgrades_window.hide()
	else:
		GUISignals.cellar_upgrades_requested.emit()


func _toggle_receipt_log_window() -> void:
	if sale_receipt_log_window.visible:
		sale_receipt_log_window.hide()
	else:
		GUISignals.receipt_log_requested.emit()


func _on_shop_button_pressed() -> void:
	_views.toggle_shop()


func _on_back_button_pressed() -> void:
	if shop_view.visible:
		_views.close_shop()
	else:
		_views.show_bar()


func _on_brewery_button_pressed() -> void:
	if brewery_view.visible:
		_views.show_bar()
		return
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
