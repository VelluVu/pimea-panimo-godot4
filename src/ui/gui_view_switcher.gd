class_name GuiViewSwitcher
extends RefCounted

## Switches between the bar, shop and brewery views, showing each view's panels and
## announcing bar_view_entered/exited so hover areas can gate input, and
## brewery_view_opened/closed.

var _shop_view: ShopView
var _brewery_view: BrewingView
var _brew_preparation_panel: BrewPreparationPanel
var _shop_entrance_panel: ShopEntrancePanel
var _brewery_entrance_panel: Control
## The shop was opened from the brewery, so closing it goes back there instead of the bar.
var _shop_returns_to_brewery: bool = false


func _init(shop_view: ShopView, brewery_view: BrewingView, brew_preparation_panel: BrewPreparationPanel, shop_entrance_panel: ShopEntrancePanel, brewery_entrance_panel: Control) -> void:
	_shop_view = shop_view
	_brewery_view = brewery_view
	_brew_preparation_panel = brew_preparation_panel
	_shop_entrance_panel = shop_entrance_panel
	_brewery_entrance_panel = brewery_entrance_panel


## True while the shop or the brewery view is showing (i.e. not the bar).
func is_away_from_bar() -> bool:
	return _brewery_view.visible or _shop_view.visible


func show_bar() -> void:
	_shop_returns_to_brewery = false
	_shop_view.hide()
	_hide_brewery()
	_brew_preparation_panel.hide()
	_shop_entrance_panel.activate_shop_panel()
	_brewery_entrance_panel.show()
	GUISignals.bar_view_entered.emit()


## The shop's spot stays active beside the open shop, so a second tap closes it. The recipe
## stays open too, so the player sees what they are buying for.
func show_shop() -> void:
	_shop_returns_to_brewery = _brewery_view.visible
	_hide_brewery()
	_brew_preparation_panel.set_brewing_shown(false)
	_brew_preparation_panel.show()
	_shop_entrance_panel.activate_shop_panel()
	_brewery_entrance_panel.hide()
	_shop_view.show()
	GUISignals.bar_view_exited.emit()


## The shop entrance stays active, so the brewery can click straight to the shop. Not the
## other way round, so a mid-shopping misclick never swaps views.
func show_brewery() -> void:
	_shop_returns_to_brewery = false
	_shop_view.hide()
	_shop_entrance_panel.activate_shop_panel()
	_brewery_entrance_panel.hide()
	_brewery_view.show()
	_brew_preparation_panel.set_brewing_shown(true)
	_brew_preparation_panel.show()
	GUISignals.bar_view_exited.emit()
	GUISignals.brewery_view_opened.emit()


func toggle_brewery() -> void:
	if _brewery_view.visible:
		show_bar()
	else:
		show_brewery()


func toggle_shop() -> void:
	if _shop_view.visible:
		close_shop()
	else:
		show_shop()


## Buying for a recipe is a trip from the brewery, so the shop hands the player back there.
func close_shop() -> void:
	if _shop_returns_to_brewery:
		show_brewery()
	else:
		show_bar()


func _hide_brewery() -> void:
	if _brewery_view.visible:
		_brewery_view.hide()
		GUISignals.brewery_view_closed.emit()
