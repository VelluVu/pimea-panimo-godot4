class_name GUI
extends Control


const DISCOVERY_TOAST_FORMAT: String = "Uusi oluttyyli löydetty: %s!"
const GOAL_REWARD_TOAST_FORMAT: String = "%s saavutettu: +%d € / +%d maine!"
const DISCOVERY_TOAST_FLASH_SECONDS: float = 0.15
const DISCOVERY_TOAST_HOLD_SECONDS: float = 2.0
const DISCOVERY_TOAST_FADE_SECONDS: float = 0.6

@onready var discovery_toast : Label = $DiscoveryToast
@onready var close_day_button : Button = $TopPanel_Resources/CloseDayButton
@onready var close_day_confirm_window : CloseDayConfirmWindow = $CloseDayConfirmWindow
@onready var dialog_view : Control = $DialogView
@onready var top_panel_background : Panel = $TopPanelBackground
@onready var top_panel_resources : Control = $TopPanel_Resources
@onready var options_button : Button = $OptionsButton
@onready var dev_console : Control = $DevConsole
var _discovery_toast_tween : Tween

@onready var shop_view : ShopView = $Left_ShopView
@onready var brewery_view : BrewingView = $Left_BrewingView
@onready var brew_preparation_panel : BrewPreparationPanel = $BrewPreparationPanel
@onready var warehouse_view : VBoxContainer = $Right_WarehouseView
@onready var brewery_entrance_panel : Control = $BreweryEntrancePanel
@onready var shop_entrance_panel : ShopEntrancePanel = $ShopEntrancePanel
@onready var recipe_library_window : Control = $RecipeLibraryWindow
@onready var AVI_raid_window : Control = $AviRaidWindow


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


func _move_to_shop() -> void:
	brewery_view.hide()
	brew_preparation_panel.hide()
	shop_entrance_panel.deactivate_shop_panel()
	brewery_entrance_panel.hide()
	shop_view.show()
	GUISignals.bar_view_exited.emit()


func _move_to_brewery() -> void:
	shop_view.hide()
	shop_entrance_panel.deactivate_shop_panel()
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


func _on_style_discovered(style : int) -> void:
	_show_toast(DISCOVERY_TOAST_FORMAT % BeerStyle.get_style_string_from_style(style))


func _on_daily_goal_reward_granted(goal_name : String, money : int, reputation : int) -> void:
	_show_toast(GOAL_REWARD_TOAST_FORMAT % [goal_name, money, reputation])


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
