@tool
extends EditorPlugin

## Adds "Tools > Luo ainesosa..." and "Tools > Luo asiakas..." menu items for
## quickly scaffolding new IngredientData/CustomerData .tres resources
## instead of hand-writing them — see ingredient_dialog.gd / customer_dialog.gd
## for the actual dialogs. Dialog instances are kept alive (hidden, not
## freed) between openings so field values survive a cancel.

const IngredientDialogScript = preload("res://addons/dev_resource_tools/ingredient_dialog.gd")
const CustomerDialogScript = preload("res://addons/dev_resource_tools/customer_dialog.gd")

const INGREDIENT_MENU_TEXT: String = "Luo ainesosa..."
const CUSTOMER_MENU_TEXT: String = "Luo asiakas..."

var _ingredient_dialog: ConfirmationDialog
var _customer_dialog: ConfirmationDialog


func _enter_tree() -> void:
	add_tool_menu_item(INGREDIENT_MENU_TEXT, _open_ingredient_dialog)
	add_tool_menu_item(CUSTOMER_MENU_TEXT, _open_customer_dialog)


func _exit_tree() -> void:
	remove_tool_menu_item(INGREDIENT_MENU_TEXT)
	remove_tool_menu_item(CUSTOMER_MENU_TEXT)
	if is_instance_valid(_ingredient_dialog):
		_ingredient_dialog.queue_free()
	if is_instance_valid(_customer_dialog):
		_customer_dialog.queue_free()


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
