class_name BarContactOptionButton
extends OptionButton

## One shared "ship to which bar" picker for every row, as there is no room for one per row.
## Locked bars show disabled, previewing what is coming.

const TOOLTIP_FORMAT : String = "%s\nMaksukerroin: x%.2f raaka-aineiden hinnasta\nLVV-riski per toimitus: +%d (alkoholittomat %+d)"


func _ready() -> void:
	clip_text = true
	fit_to_longest_item = false

	item_selected.connect(_on_item_selected)
	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)

	_rebuild_items()


## Rebuilds only on a reputation change, keeping the pick: brewery_state_changed fires too
## often to reset it every time.
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

		add_item(tr(StringContainer.INGREDIENT_LOCKED_LABEL) % bar.required_reputation if is_locked else tr(bar.bar_name))
		var new_item_index := get_item_count() - 1
		set_item_id(new_item_index, i)
		set_item_disabled(new_item_index, is_locked)
		get_popup().set_item_tooltip(new_item_index, tr(StringContainer.INGREDIENT_LOCKED_LABEL) % bar.required_reputation if is_locked else _build_tooltip(bar))

	_select_first_enabled()


func _select_first_enabled() -> void:
	for i in range(item_count):
		if not is_item_disabled(i):
			select(i)
			_sync_own_tooltip()
			return


func _on_item_selected(_index: int) -> void:
	_sync_own_tooltip()


## The closed button shows the selected bar's tooltip too.
func _sync_own_tooltip() -> void:
	var bar : BarContact = get_selected_bar()
	if bar != null:
		tooltip_text = _build_tooltip(bar)


func _build_tooltip(bar : BarContact) -> String:
	return tr(TOOLTIP_FORMAT) % [tr(bar.description), bar.price_multiplier, bar.risk_per_shipment, BarContact.ALCOHOL_FREE_SHIPMENT_RISK]


## Long bar descriptions would overflow Godot's default tooltip.
func _make_custom_tooltip(for_text: String) -> Object:
	return TooltipFactory.make_wrapped_tooltip(for_text)


func get_selected_bar() -> BarContact:
	if selected == -1:
		return null
	var pool_index : int = get_item_id(selected)
	if pool_index < 0 or pool_index >= CustomerRegistry.bar_contact_pool.size():
		return null
	return CustomerRegistry.bar_contact_pool[pool_index]
