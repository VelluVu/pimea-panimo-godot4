class_name Inventory
extends Resource


@export var brew_batches : Array[BrewBatch] = []
## Cleanliness of every empty keg, see KegRules. A save made before kegs existed keeps
## the starting kegs set in _init(), on top of the batches it already holds.
@export var free_kegs : Array[float] = []

# Sisäkkäinen sanakirja: Key: Script (MaltData/HopData) -> Value: Dictionary (Key: int (ID) -> Value: InventoryItem)
@export var items : Dictionary = {}


## Godot also calls _init() when loading a save, then overwrites the exported fields.
func _init() -> void:
	free_kegs = KegRules.starting_kegs()


## Every keg the brewery owns: the empty ones and those holding a batch.
func total_kegs() -> int:
	return free_kegs.size() + brew_batches.size()


func has_free_keg() -> bool:
	return not free_kegs.is_empty()


func dirty_keg_count() -> int:
	return KegRules.dirty_count(free_kegs)


## Puts a new batch into the cleanest empty keg.
func add_batch(batch : BrewBatch) -> void:
	batch.keg_cleanliness = KegRules.take_cleanest(free_kegs)
	brew_batches.append(batch)


## Every way a batch leaves the cellar ends here, so its keg comes back dirty.
func remove_batch(batch : BrewBatch) -> void:
	if not brew_batches.has(batch):
		return
	brew_batches.erase(batch)
	return_dirty_kegs(1)


func return_dirty_kegs(count : int) -> void:
	if count <= 0:
		return
	for i : int in count:
		free_kegs.append(KegRules.DIRTY)
	BrewerySignals.kegs_emptied.emit(count)


func add_clean_kegs(count : int) -> void:
	for i : int in count:
		free_kegs.append(KegRules.CLEAN)


func add_amount(ingredient : IngredientData, amount : int) -> void:
	if amount <= 0:
		print(StringContainer.INVALID_ADD_AMOUNT_ERROR % [StringContainer.INVENTORY_STRING, amount, ingredient.id])
		return
	
	if not items.has(ingredient.type):
		items[ingredient.type] = {}
		
	if items[ingredient.type].has(ingredient.id):
		items[ingredient.type][ingredient.id].amount += amount
	else:
		var new_item := InventoryItem.new()
		new_item.ingredient_data = ingredient
		new_item.amount = amount
		items[ingredient.type][ingredient.id] = new_item


func get_item(ingredient : IngredientData) -> InventoryItem:
	if not has_item(ingredient):
		return null
		
	var item : InventoryItem = items[ingredient.type][ingredient.id]
	return item 


func withdraw_item(ingredient : IngredientData, amount : int) -> int:
	if amount <= 0:
		print(StringContainer.WITHDRAW_INVALID_AMOUNT_ERROR % [StringContainer.INVENTORY_STRING, amount])
		return 0
	
	if not has_item(ingredient) or amount <= 0:
		return 0
	
	var item : InventoryItem = items[ingredient.type][ingredient.id]
	
	if item.amount < amount:
		print(StringContainer.WITHDRAW_NO_STOCK_ERROR % [StringContainer.INVENTORY_STRING, ingredient.name])
		return 0 
		
	item.amount -= amount
	
	if item.amount == 0:
		items[ingredient.type].erase(ingredient.id)
		
	return amount


func has_item(ingredient : IngredientData) -> bool:
	if not items.has(ingredient.type) or not items[ingredient.type].has(ingredient.id):
		#print(StringContainer.INVALID_ID_ERROR % [StringContainer.INVENTORY_STRING , ingredient.id, StringContainer.LIST_STRING])
		return false
	return true


func has_item_by_id(id: int) -> bool:
	var ingredient : IngredientData = IngredientDatabase.get_item_by_id(id)
	if ingredient == null:
		return false
	
	if not items.has(ingredient.type) or not items[ingredient.type].has(id):
		#print(StringContainer.INVALID_ID_ERROR % [StringContainer.INVENTORY_STRING , id, StringContainer.LIST_STRING])
		return false
		
	return true


func get_item_by_id(id: int) -> InventoryItem:
	var ingredient: IngredientData = IngredientDatabase.get_item_by_id(id)
	if ingredient == null:
		return null
	
	if not has_item_by_id(id):
		return null
		
	return items[ingredient.type][id]


func withdraw_item_by_id(id : int, amount : int) -> int:
	if amount <= 0:
		print(StringContainer.WITHDRAW_INVALID_AMOUNT_ERROR % [StringContainer.INVENTORY_STRING, amount])
		return 0
	
	var ingredient : IngredientData = IngredientDatabase.get_item_by_id(id)
	if ingredient == null:
		return 0
		
	var item : InventoryItem = get_item_by_id(id)
	if item == null:
		return 0

	if item.amount < amount:
		print(StringContainer.WITHDRAW_NO_STOCK_ERROR % [StringContainer.INVENTORY_STRING, ingredient.name])
		return 0
	
	item.amount -= amount
	
	if item.amount == 0:
		items[ingredient.type].erase(id)
		
	return amount
	


func add_amount_by_id(id: int, amount: int) -> void:
	var ingredient : IngredientData = IngredientDatabase.get_item_by_id(id)
	if ingredient == null:
		return
		
	add_amount(ingredient, amount)


## Bottles across every batch in the cellar.
func count_bottles() -> int:
	var total : int = 0
	for batch : BrewBatch in brew_batches:
		total += batch.amount_bottles
	return total


## Batches customers can buy right now: servings left and not held in the cellar to
## age. Each one is a keg behind the counter with its own tap.
func batches_on_serve() -> Array[BrewBatch]:
	var serving : Array[BrewBatch] = []
	for batch : BrewBatch in brew_batches:
		if batch.amount_bottles > 0 and not batch.held:
			serving.append(batch)
	return serving


## Different styles customers can buy right now, see batches_on_serve().
func styles_on_tap() -> int:
	var styles : Dictionary = {}
	for batch : BrewBatch in batches_on_serve():
		styles[batch.beer_style.style] = true
	return styles.size()


## One aging tick for every batch in the cellar.
func age_batches() -> void:
	for batch : BrewBatch in brew_batches:
		batch.age_one_day()
