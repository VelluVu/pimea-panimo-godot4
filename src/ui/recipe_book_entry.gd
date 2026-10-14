class_name RecipeBookEntry
extends RefCounted

## One style as the recipe book shows it, with the ingredient names already looked up,
## so RecipeLibraryText stays free of the ingredient database.

var beer_style : BeerStyle
var known : bool = false
var yeast_name : String = ""
var base_malt_names : PackedStringArray = []
var required_malt_name : String = ""
var required_spice_name : String = ""
## The reference recipe's malts, most used first.
var favourite_malt_names : PackedStringArray = []
var preferred_spice_names : PackedStringArray = []
var saved_recipe_count : int = 0
var needs_mash_upgrade : bool = false
## Locked styles only.
var needs_malt_blend : bool = false
var attracts_new_customer : bool = false
var hinted : bool = false
