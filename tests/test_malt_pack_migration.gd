@tool
extends McpTestSuite

## Unit tests for MaltPackMigration: old saves' kilos of the packed malts become packs.

const MigrationScript := preload("res://src/brewery/malt_pack_migration.gd")

const CARAMEL_ID : int = 102
const PILSNER_ID : int = 100
const MUNICH_ID : int = 104


func suite_name() -> String:
	return "malt_pack_migration"


func test_a_recipe_keeps_its_weight() -> void:
	var contents : Dictionary = {PILSNER_ID: 4, CARAMEL_ID: 1, 200: 15}
	MigrationScript.scale(contents)
	assert_eq(contents, {PILSNER_ID: 4, CARAMEL_ID: 10, 200: 15}, "only the packed malts change")


func test_the_warehouse_keeps_its_weight() -> void:
	var caramel := InventoryItem.new()
	caramel.amount = 3
	var pilsner := InventoryItem.new()
	pilsner.amount = 5
	var items : Dictionary = {IngredientData.IngredientType.MALT: {CARAMEL_ID: caramel, PILSNER_ID: pilsner}}
	MigrationScript.scale_items(items)
	assert_eq(caramel.amount, 30)
	assert_eq(pilsner.amount, 5)


func test_the_packed_malts_are_sold_in_packs() -> void:
	for id : int in MigrationScript.PACKED_IDS:
		var malt : MaltData = load(_malt_path(id))
		assert_eq(malt.pack_grams, 100, "malt %d" % id)


func test_half_kilo_malts_double_in_old_saves() -> void:
	var contents : Dictionary = {PILSNER_ID: 4, MUNICH_ID: 3, CARAMEL_ID: 10}
	MigrationScript.scale(contents, MigrationScript.HALF_KILO_IDS, MigrationScript.HALF_KILO_PACKS)
	assert_eq(contents, {PILSNER_ID: 4, MUNICH_ID: 6, CARAMEL_ID: 10}, "3 kg of Münchenin is six 500 g packs")


func test_the_half_kilo_malts_are_sold_by_the_half_kilo() -> void:
	for id : int in MigrationScript.HALF_KILO_IDS:
		var malt : MaltData = load(_malt_path(id))
		assert_eq(malt.pack_grams, 500, "malt %d" % id)


func _malt_path(id : int) -> String:
	for file : String in DirAccess.get_files_at("res://src/resources/ingredients/malts/"):
		if file.ends_with(".tres"):
			var path : String = "res://src/resources/ingredients/malts/" + file
			if (load(path) as IngredientData).id == id:
				return path
	return ""
