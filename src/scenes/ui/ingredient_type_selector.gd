class_name IngredientTypeSelector
extends VBoxContainer

## Consolidates the malt/hop/yeast dropdowns into one shared OptionButton,
## switched by a TabBar above it — replaces three permanently-stacked
## selector rows with one, per the minimalism pass on BrewingView/ShopView.

const MALT_TAB_TEXT : String = "Mallas"
const HOP_TAB_TEXT : String = "Humala"
const YEAST_TAB_TEXT : String = "Hiiva"
const SPICE_TAB_TEXT : String = "Mauste"
## The icons' own size, so the pixels stay square; the tab sides are trimmed to
## TAB_SIDE_MARGIN so all four still fit the ~190 px panel without scroll arrows.
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
	# Icon-only tabs, name as tooltip: the panel is only ~140px wide, too
	# narrow for three text+icon tabs to fit without scrolling — and a wide
	# tab row here collides with the corner BackButton shared by this view
	# and ShopView. Left-aligned icon tabs stay clear of that corner.
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


## Called by BrewingView/ShopView whenever their view is actually opened
## (see GuiViewSwitcher) — without this, the
## malt/hop/yeast tab and the selected ingredient both just carry over
## from whatever GUISignals.active_ingredient_changed last touched
## globally (which the OTHER view's own selector also listens to and
## fires), rather than resetting to a known, predictable starting point
## every time the view is (re)entered. Calling _on_tab_changed(0)
## directly instead of just setting current_tab (TabBar only emits
## tab_changed on an actual change, so re-selecting an already-0 tab
## would otherwise silently skip the reset).
func reset_to_first_tab() -> void:
	tab_bar.current_tab = 0
	_on_tab_changed(0)


func step_ingredient(direction : int) -> void:
	OptionStepper.step(option_button, direction)


## Wraps around both ways; setting current_tab emits tab_changed, which repopulates.
func step_type(direction : int) -> void:
	tab_bar.current_tab = posmod(tab_bar.current_tab + direction, tab_bar.tab_count)


## Puts < and > beside the dropdown and moves `amount_label` (the shop's or brew view's
## amount text) to its own line below, so the arrows leave the names room.
func add_step_buttons(amount_label : Label) -> void:
	OptionStepper.wrap(option_button)
	amount_label.reparent(self)
	move_child(amount_label, ingredient_row.get_index() + 1)
