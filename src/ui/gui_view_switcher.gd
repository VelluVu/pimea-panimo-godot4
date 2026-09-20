class_name GuiViewSwitcher
extends RefCounted

## Switches the GUI between its three main views: bar (neutral), shop and
## brewery. GUI owns the nodes and hands them in; this owns which panels each
## view shows and announces bar_view_entered/exited so hover areas can gate input.

var _shop_view: ShopView
var _brewery_view: BrewingView
var _brew_preparation_panel: BrewPreparationPanel
var _shop_entrance_panel: ShopEntrancePanel
var _brewery_entrance_panel: Control


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
	_shop_view.hide()
	_brewery_view.hide()
	_brew_preparation_panel.hide()
	_shop_entrance_panel.activate_shop_panel()
	_brewery_entrance_panel.show()
	GUISignals.bar_view_entered.emit()


func show_shop() -> void:
	_brewery_view.hide()
	_brew_preparation_panel.hide()
	_shop_entrance_panel.deactivate_shop_panel()
	_brewery_entrance_panel.hide()
	_shop_view.show()
	GUISignals.bar_view_exited.emit()


## The shop entrance stays active here, unlike show_shop(): from the brewery the
## player can click straight through to the shop. Deliberately not symmetric:
## BreweryHoverArea only accepts input in the bar view, so there is no click from
## the shop straight to the brewery, avoiding an accidental swap mid-shopping.
func show_brewery() -> void:
	_shop_view.hide()
	_shop_entrance_panel.activate_shop_panel()
	_brewery_entrance_panel.hide()
	_brewery_view.show()
	_brew_preparation_panel.show()
	GUISignals.bar_view_exited.emit()


func toggle_brewery() -> void:
	if _brewery_view.visible:
		show_bar()
	else:
		show_brewery()


func toggle_shop() -> void:
	if _shop_view.visible:
		show_bar()
	else:
		show_shop()
