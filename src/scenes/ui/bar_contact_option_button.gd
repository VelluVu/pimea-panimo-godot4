class_name BarContactOptionButton
extends OptionButton

## Shared "which bar am I shipping to" picker sitting once above
## BeerPatchPanel's batch rows — each row's own "Lähetä baariin" button
## ships to whatever this control currently has selected, rather than
## every row carrying its own full picker (no room for that in
## RightWarehouseView's narrow tabbed layout). Mirrors
## IngredientOptionButton's locked-item pattern: every BarContact in
## CustomerRegistry.bar_contact_pool is listed, the ones the player's
## reputation hasn't unlocked yet are shown disabled instead of hidden, so
## the picker itself previews what's coming.

const TOOLTIP_FORMAT : String = "%s\nMaksukerroin: x%.2f raaka-ainehinnasta\nLVV-riski per toimitus: +%d"


func _ready() -> void:
	clip_text = true
	fit_to_longest_item = false

	item_selected.connect(_on_item_selected)
	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)

	_rebuild_items()


## Same "only rebuild on an actual reputation change, keep the player's
## current pick" reasoning as IngredientOptionButton._on_brewery_state_
## changed() — a bulk-sell/ship/sale fires brewery_state_changed far too
## often to reset the selection on every one.
var _last_reputation_seen : int = -1

func _on_brewery_state_changed(brewery : Brewery) -> void:
	if brewery.reputation == _last_reputation_seen:
		return
	_last_reputation_seen = brewery.reputation

	var previously_selected : BarContact = get_selected_bar()
	_rebuild_items()

	if previously_selected != null:
		for i in range(item_count):
			if get_item_id(i) < CustomerRegistry.bar_contact_pool.size() and CustomerRegistry.bar_contact_pool[get_item_id(i)] == previously_selected and not is_item_disabled(i):
				select(i)
				_sync_own_tooltip()
				return

	_select_first_enabled()


func _rebuild_items() -> void:
	clear()
	var brewery := BrewEngine.current_brewery
	var reputation : int = brewery.reputation if brewery != null else 0
	_last_reputation_seen = reputation

	for i in range(CustomerRegistry.bar_contact_pool.size()):
		var bar : BarContact = CustomerRegistry.bar_contact_pool[i]
		var is_locked : bool = reputation < bar.required_reputation

		add_item(StringContainer.INGREDIENT_LOCKED_LABEL % bar.required_reputation if is_locked else bar.bar_name)
		var new_item_index := get_item_count() - 1
		set_item_id(new_item_index, i)
		set_item_disabled(new_item_index, is_locked)
		get_popup().set_item_tooltip(new_item_index, StringContainer.INGREDIENT_LOCKED_LABEL % bar.required_reputation if is_locked else _build_tooltip(bar))

	_select_first_enabled()


func _select_first_enabled() -> void:
	for i in range(item_count):
		if not is_item_disabled(i):
			select(i)
			_sync_own_tooltip()
			return


func _on_item_selected(_index: int) -> void:
	_sync_own_tooltip()


## Mirrors IngredientOptionButton._sync_own_tooltip() — puts the popup
## item's tooltip on the closed button too, so hovering the collapsed
## picker (not just an open popup item) already shows the selected bar's
## payout/risk.
func _sync_own_tooltip() -> void:
	var bar : BarContact = get_selected_bar()
	if bar != null:
		tooltip_text = _build_tooltip(bar)


func _build_tooltip(bar : BarContact) -> String:
	return TOOLTIP_FORMAT % [bar.description, bar.price_multiplier, bar.risk_per_shipment]


## A bar's description can run long enough to overflow Godot's default
## (non-wrapping) tooltip — see TooltipFactory.
func _make_custom_tooltip(for_text: String) -> Object:
	return TooltipFactory.make_wrapped_tooltip(for_text)


func get_selected_bar() -> BarContact:
	if selected == -1:
		return null
	var pool_index : int = get_item_id(selected)
	if pool_index < 0 or pool_index >= CustomerRegistry.bar_contact_pool.size():
		return null
	return CustomerRegistry.bar_contact_pool[pool_index]
