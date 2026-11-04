class_name NaughtyList
extends RefCounted

## Korvatunturi's racket: tontut mark every visit kiltti or tuhma and avenge a tuhma one;
## Joulupukki settles the marks on his own visit with gifts, a favour or a punishment.

const GIFT_POOL : ChristmasGiftPool = preload("res://src/resources/christmas/joulupukki_gift_pool.tres")

const KILTTI_NOTE : String = "Tonttu raapusti jotain pieneen kirjaansa ja nyökkäsi. Kiltti."
const FOOTPRINTS_NOTE : String = "Tiskillä on pieniä märkiä tassunjälkiä. Ei muuta. Vielä."
const HIDE_FORMAT : String = "Tontut veivät %s. Ehkä se löytyy huomenna. Ehkä ei."
const SOMETHING : String = "jotain"
const SIP_FORMAT : String = "Tontut kävivät maistamassa tynnyriä: %s väheni %d pulloa."
const STASH_RETURNED_NOTE : String = "Tontut palauttivat piilottamansa ainekset. Osa on vähän nuoltuja."
const FAVOUR_NOTE : String = "Joulupukki iski silmää: hän tuntee LVV:llä yhden jos toisenkin. Riski laski."
const PUNISHMENT_NOTE : String = "Joulupukki jätti tiskille koivurisun. Pian sen jälkeen LVV sai nimettömän vihjeen."
const NONE_NOTE : String = "Joulupukki selasi listaa pitkään ja hymyili. Se oli pahinta."
const GIFT_OPENED_FORMAT : String = "Paketista paljastui: %s."

var brewery : Brewery


func _init(owner : Brewery) -> void:
	brewery = owner


func connect_signals() -> void:
	BrewerySignals.korvatunturi_visit_ended.connect(_on_visit_ended)
	GUISignals.christmas_gift_chosen.connect(_on_gift_chosen)


func disconnect_signals() -> void:
	BrewerySignals.korvatunturi_visit_ended.disconnect(_on_visit_ended)
	GUISignals.christmas_gift_chosen.disconnect(_on_gift_chosen)


func _on_visit_ended(data : CustomerData, served : bool, got_favourite : bool) -> void:
	match data.korvatunturi_role:
		CustomerData.KorvatunturiRole.TONTTU:
			_mark(served)
		CustomerData.KorvatunturiRole.JOULUPUKKI:
			_settle(NaughtyListRules.verdict(brewery.naughty_list_kiltti, brewery.naughty_list_tuhma, served and got_favourite))


func _mark(kiltti : bool) -> void:
	if kiltti:
		brewery.naughty_list_kiltti += 1
		_narrate(tr(KILTTI_NOTE))
		return
	brewery.naughty_list_tuhma += 1
	_avenge()


func _avenge() -> void:
	var owned : Dictionary = _owned_ingredients()
	var batches : Array[BrewBatch] = brewery.inventory.batches_on_serve()
	match NaughtyListRules.mischief(not owned.is_empty(), not batches.is_empty(), randf()):
		NaughtyListRules.Mischief.HIDE_INGREDIENT:
			_hide_ingredient(owned)
		NaughtyListRules.Mischief.SIP_KEG:
			_sip(batches.pick_random())
		_:
			_narrate(tr(FOOTPRINTS_NOTE))


## In the store, not the brew being prepared.
func _owned_ingredients() -> Dictionary:
	var owned : Dictionary = {}
	for type_items : Dictionary in brewery.inventory.items.values():
		for id : int in type_items:
			var amount : int = (type_items[id] as InventoryItem).amount
			if amount > 0:
				owned[id] = amount
	return owned


func _hide_ingredient(owned : Dictionary) -> void:
	var id : int = owned.keys().pick_random()
	var taken : int = brewery.inventory.withdraw_item_by_id(id, NaughtyListRules.hidden_amount(owned[id]))
	brewery.tonttu_stash[id] = brewery.tonttu_stash.get(id, 0) + taken
	var ingredient : IngredientData = IngredientDatabase.get_item_by_id(id)
	var what : String = tr(SOMETHING)
	if ingredient != null:
		what = UiText.of(ingredient.name_partitive if not ingredient.name_partitive.is_empty() else ingredient.name)
	_narrate(tr(HIDE_FORMAT) % what)
	BrewerySignals.brewery_state_changed.emit(brewery)


func _sip(batch : BrewBatch) -> void:
	var bottles : int = mini(randi_range(1, NaughtyListRules.SIP_MAX_BOTTLES), batch.amount_bottles)
	batch.amount_bottles -= bottles
	if batch.amount_bottles <= 0:
		brewery.inventory.remove_batch(batch)
	_narrate(tr(SIP_FORMAT) % [BeerStyle.get_style_string_from_style(batch.beer_style.style), bottles])
	BrewerySignals.brewery_state_changed.emit(brewery)


## The next morning the tontut bring back what they hid; TimeManager calls this on a new day.
static func return_stash(owner : Brewery) -> void:
	if owner.tonttu_stash.is_empty():
		return
	for id : int in owner.tonttu_stash:
		owner.inventory.add_amount_by_id(id, owner.tonttu_stash[id])
	owner.tonttu_stash.clear()
	BrewerySignals.customer_sale_narrated.emit(UiText.of(STASH_RETURNED_NOTE))
	BrewerySignals.brewery_state_changed.emit(owner)


## The account starts over whatever the verdict.
func _settle(verdict : NaughtyListRules.Verdict) -> void:
	brewery.naughty_list_kiltti = 0
	brewery.naughty_list_tuhma = 0
	if verdict == NaughtyListRules.Verdict.GIFT:
		brewery.christmas_gifts = ChristmasGiftRules.roll(CellarUpgrades.all(), brewery.cellar_upgrade_levels, brewery.owned_machines, GIFT_POOL.perks, brewery.active_perks, NaughtyListRules.GIFT_COUNT)
		if not brewery.christmas_gifts.is_empty():
			BrewerySignals.christmas_gifts_offered.emit(brewery.christmas_gifts)
			return
		verdict = NaughtyListRules.Verdict.FAVOUR
	match verdict:
		NaughtyListRules.Verdict.FAVOUR:
			brewery.add_risk(-NaughtyListRules.FAVOUR_RISK_RELIEF)
			_narrate(tr(FAVOUR_NOTE))
		NaughtyListRules.Verdict.PUNISHMENT:
			brewery.inventory.add_amount_by_id(NaughtyListRules.KOIVURISU_ID, NaughtyListRules.KOIVURISU_AMOUNT)
			brewery.add_risk(NaughtyListRules.PUNISHMENT_RISK)
			_narrate(tr(PUNISHMENT_NOTE))
		_:
			_narrate(tr(NONE_NOTE))
	BrewerySignals.brewery_state_changed.emit(brewery)


func _on_gift_chosen(index : int) -> void:
	if index < 0 or index >= brewery.christmas_gifts.size():
		return
	var gift : ChristmasGift = brewery.christmas_gifts[index]
	brewery.christmas_gifts.clear()
	if gift.upgrade != null:
		CellarUpgradeShop.raise_level(brewery, gift.upgrade)
	else:
		brewery.apply_perk(gift.perk)
	_narrate(tr(GIFT_OPENED_FORMAT) % UiText.of(gift.display_name()))


func _narrate(text : String) -> void:
	BrewerySignals.customer_sale_narrated.emit(text)
