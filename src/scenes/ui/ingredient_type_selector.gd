class_name IngredientTypeSelector
extends VBoxContainer

## One shared ingredient dropdown, switched by a TabBar of ingredient types.

const MALT_TAB_TEXT : String = "Mallas"
const HOP_TAB_TEXT : String = "Humala"
const YEAST_TAB_TEXT : String = "Hiiva"
const SPICE_TAB_TEXT : String = "Mauste"
## The icons' own size, so the pixels stay square; trimmed tab sides fit all four.
const TAB_ICON_WIDTH : int = 32
const TAB_SIDE_MARGIN : int = 6
const TAB_STYLES : Array[StringName] = [&"tab_selected", &"tab_unselected", &"tab_hovered", &"tab_disabled", &"tab_focus"]
const TAB_ICONS : Dictionary = {
	IngredientData.IngredientType.MALT: preload("res://assets/textures/malt.png"),
	IngredientData.IngredientType.HOP: preload("res://assets/textures/hop.png"),
	IngredientData.IngredientType.YEAST: preload("res://assets/textures/yeast.png"),
	IngredientData.IngredientType.SPICE: preload("res://assets/textures/spices.png"),
}

const TYPES_BY_TAB : Array[IngredientData.IngredientType] = [
	IngredientData.IngredientType.MALT,
	IngredientData.IngredientType.HOP,
	IngredientData.IngredientType.YEAST,
	IngredientData.IngredientType.SPICE,
]

@onready var tab_bar : TabBar = $TabBar
@onready var option_button : IngredientOptionButton = $IngredientRow/IngredientOptionButton
@onready var ingredient_row : HBoxContainer = $IngredientRow


func _ready() -> void:
	tab_bar.clear_tabs()
	tab_bar.add_theme_constant_override(&"icon_max_width", TAB_ICON_WIDTH)
	_trim_tab_sides()
	# Icon-only tabs, name as tooltip: text tabs would not fit the narrow panel and would
	# collide with the corner BackButton.
	_add_icon_tab(MALT_TAB_TEXT, IngredientData.IngredientType.MALT)
	_add_icon_tab(HOP_TAB_TEXT, IngredientData.IngredientType.HOP)
	_add_icon_tab(YEAST_TAB_TEXT, IngredientData.IngredientType.YEAST)
	_add_icon_tab(SPICE_TAB_TEXT, IngredientData.IngredientType.SPICE)
	tab_bar.current_tab = 0
	tab_bar.tab_changed.connect(_on_tab_changed)
	tab_bar.tab_changed.connect(GUISignals.tab_switched.emit.unbind(1))
	_on_tab_changed(0)


func _add_icon_tab(tab_name : String, ingredient_type : IngredientData.IngredientType) -> void:
	tab_bar.add_tab("", TAB_ICONS[ingredient_type])
	tab_bar.set_tab_tooltip(tab_bar.tab_count - 1, tab_name)


func _trim_tab_sides() -> void:
	for style_name : StringName in TAB_STYLES:
		var style : StyleBox = tab_bar.get_theme_stylebox(style_name)
		if style == null:
			continue
		style = style.duplicate()
		style.content_margin_left = TAB_SIDE_MARGIN
		style.content_margin_right = TAB_SIDE_MARGIN
		tab_bar.add_theme_stylebox_override(style_name, style)


func _on_tab_changed(tab_index : int) -> void:
	option_button.target_type = TYPES_BY_TAB[tab_index]
	option_button.populate_ingredient_option_menu()


## Each view opens on the first tab. Calls _on_tab_changed(0) itself, since TabBar emits
## nothing when the tab is already 0.
func reset_to_first_tab() -> void:
	tab_bar.current_tab = 0
	_on_tab_changed(0)


func step_ingredient(direction : int) -> void:
	OptionStepper.step(option_button, direction)


## Wraps around both ways; setting current_tab emits tab_changed, which repopulates.
func step_type(direction : int) -> void:
	tab_bar.current_tab = posmod(tab_bar.current_tab + direction, tab_bar.tab_count)


## Puts < and > beside the dropdown and moves `amount_label` to its own line below.
func add_step_buttons(amount_label : Label) -> void:
	OptionStepper.wrap(option_button)
	amount_label.reparent(self)
	move_child(amount_label, ingredient_row.get_index() + 1)
