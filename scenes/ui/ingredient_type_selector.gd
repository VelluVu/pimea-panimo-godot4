class_name IngredientTypeSelector
extends VBoxContainer

## Consolidates the malt/hop/yeast dropdowns into one shared OptionButton,
## switched by a TabBar above it — replaces three permanently-stacked
## selector rows with one, per the minimalism pass on BrewingView/ShopView.

const MALT_TAB_TEXT : String = "Mallas"
const HOP_TAB_TEXT : String = "Humala"
const YEAST_TAB_TEXT : String = "Hiiva"
const TAB_ICON_SIZE : int = 10

const TYPES_BY_TAB : Array[IngredientData.IngredientType] = [
	IngredientData.IngredientType.MALT,
	IngredientData.IngredientType.HOP,
	IngredientData.IngredientType.YEAST,
]

@onready var tab_bar : TabBar = $TabBar
@onready var option_button : IngredientOptionButton = $IngredientRow/IngredientOptionButton


func _ready() -> void:
	tab_bar.clear_tabs()
	# Icon-only tabs, name as tooltip: the panel is only ~140px wide, too
	# narrow for three text+icon tabs to fit without scrolling — and a wide
	# tab row here collides with the corner BackButton shared by this view
	# and ShopView. Left-aligned icon tabs stay clear of that corner.
	_add_icon_tab(MALT_TAB_TEXT, IngredientData.IngredientType.MALT)
	_add_icon_tab(HOP_TAB_TEXT, IngredientData.IngredientType.HOP)
	_add_icon_tab(YEAST_TAB_TEXT, IngredientData.IngredientType.YEAST)
	tab_bar.current_tab = 0
	tab_bar.tab_changed.connect(_on_tab_changed)
	_on_tab_changed(0)


func _add_icon_tab(tab_name : String, ingredient_type : IngredientData.IngredientType) -> void:
	tab_bar.add_tab("", _make_swatch_texture(IngredientData.get_color_for_type(ingredient_type)))
	tab_bar.set_tab_tooltip(tab_bar.tab_count - 1, tab_name)


func _on_tab_changed(tab_index : int) -> void:
	option_button.target_type = TYPES_BY_TAB[tab_index]
	option_button.populate_ingredient_option_menu()


func _make_swatch_texture(color : Color) -> ImageTexture:
	var image : Image = Image.create(TAB_ICON_SIZE, TAB_ICON_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)
