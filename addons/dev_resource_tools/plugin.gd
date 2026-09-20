@tool
extends EditorPlugin

## Adds "Tools > Luo ainesosa...", "Luo asiakas..." and "Luo perkki..." menu
## items for quickly scaffolding new IngredientData/CustomerData/RunPerk .tres
## resources instead of hand-writing them — see the *_dialog.gd files. Dialog instances are kept alive (hidden, not
## freed) between openings so field values survive a cancel.

const IngredientDialogScript = preload("res://addons/dev_resource_tools/ingredient_dialog.gd")
const CustomerDialogScript = preload("res://addons/dev_resource_tools/customer_dialog.gd")
const PerkDialogScript = preload("res://addons/dev_resource_tools/perk_dialog.gd")

const INGREDIENT_MENU_TEXT: String = "Luo ainesosa..."
const CUSTOMER_MENU_TEXT: String = "Luo asiakas..."
const PERK_MENU_TEXT: String = "Luo perkki..."

var _ingredient_dialog: ConfirmationDialog
var _customer_dialog: ConfirmationDialog
var _perk_dialog: ConfirmationDialog


func _enter_tree() -> void:
	add_tool_menu_item(INGREDIENT_MENU_TEXT, _open_ingredient_dialog)
	add_tool_menu_item(CUSTOMER_MENU_TEXT, _open_customer_dialog)
	add_tool_menu_item(PERK_MENU_TEXT, _open_perk_dialog)


func _exit_tree() -> void:
	remove_tool_menu_item(INGREDIENT_MENU_TEXT)
	remove_tool_menu_item(CUSTOMER_MENU_TEXT)
	remove_tool_menu_item(PERK_MENU_TEXT)
	if is_instance_valid(_ingredient_dialog):
		_ingredient_dialog.queue_free()
	if is_instance_valid(_customer_dialog):
		_customer_dialog.queue_free()
	if is_instance_valid(_perk_dialog):
		_perk_dialog.queue_free()


func _open_ingredient_dialog() -> void:
	if not is_instance_valid(_ingredient_dialog):
		_ingredient_dialog = IngredientDialogScript.new()
		get_editor_interface().get_base_control().add_child(_ingredient_dialog)
	_ingredient_dialog.refresh_id_suggestion()
	_ingredient_dialog.popup_centered()


func _open_customer_dialog() -> void:
	if not is_instance_valid(_customer_dialog):
		_customer_dialog = CustomerDialogScript.new()
		get_editor_interface().get_base_control().add_child(_customer_dialog)
	_customer_dialog.popup_centered()


func _open_perk_dialog() -> void:
	if not is_instance_valid(_perk_dialog):
		_perk_dialog = PerkDialogScript.new()
		get_editor_interface().get_base_control().add_child(_perk_dialog)
	_perk_dialog.popup_centered()
