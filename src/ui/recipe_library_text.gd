class_name RecipeLibraryText
extends RefCounted

## The recipe book's text. A known style shows its whole recipe; a locked one gives hints
## instead of the exact ranges.

const INDEX_KNOWN_FORMAT : String = "%s\n%.1f %%"
const INDEX_RECIPES_FORMAT : String = "%s · reseptejä %d"
const INDEX_LOCKED_FORMAT : String = "???\n%.1f %%"
const LOCKED_TITLE : String = "???"
const KNOWN_HEADER_FORMAT : String = "Löydetyt tyylit (%d/%d)"
const LOCKED_HEADER_FORMAT : String = "Löytämättömät tyylit (%d)"
const SAVED_RECIPES_HEADER : String = "Tallennetut reseptit"
const NO_SAVED_RECIPES : String = "Ei tallennettuja reseptejä."

const STRENGTH_FORMAT : String = "Vahvuus: %s %% ABV"
const COLOR_FORMAT : String = "Väri: EBC %s"
const BITTERNESS_FORMAT : String = "Katkeruus: IBU %s"
const YEAST_FORMAT : String = "Hiiva: %s"
const BASE_MALT_FORMAT : String = "Pohjamallas: %s, vähintään %d %% maltaista"
const REQUIRED_MALT_FORMAT : String = "Vaatii: %s"
const REQUIRED_SPICE_FORMAT : String = "Vaatii myös: %s"
const CHARACTER_MALTS_FORMAT : String = "Tyylin maltaat (+%d %% laatua kukin): %s"
const HOP_HINT_FORMAT : String = "Suosikkihumalat: %s"
const AROMA_HOP_NEEDED : String = "Tarvitsee aromihumalan"
const PREFERRED_SPICES_FORMAT : String = "Sopivat mausteet: %s"
const PURITY_LAW_HINT : String = "Reinheitsgebot: ei mausteita"
const MASH_FORMAT : String = "Mäskäys: %s"
const MASH_STEP_FORMAT : String = "%d °C"
const HOPPING_FORMAT : String = "Humalointi: %s"
## The reference recipe needs more malt than the mash tun holds, see MashTun.
const MASH_UPGRADE_HINT : String = "Vaatii mäskipadan päivityksen"

const LOCKED_STRENGTH_FORMAT : String = "Vahvuus: noin %.1f %% ABV"
const COLOR_HINT_FORMAT : String = "Väri: %s"
const BITTERNESS_HINT_FORMAT : String = "Katkeruus: %s"
const MALT_BLEND_HINT : String = "Vaatii mallasseoksen"
const NEW_CUSTOMER_HINT : String = "Houkuttelee uuden asiakkaan"
const MASTER_HINT_FORMAT : String = "Aatun vinkki: EBC %s, IBU %s"

const BITTERING_ADDITION_TEXT : String = "katkero"
const FLAVOR_ADDITION_TEXT : String = "maku"
const AROMA_ADDITION_TEXT : String = "aromi"
const DRY_HOP_ADDITION_TEXT : String = "kuivahumala"
const LIST_SEPARATOR : String = ", "
const BASE_MALT_SEPARATOR : String = " / "
## BeerStyle's default max_ebc/max_ibu: the style sets no upper limit.
const NO_UPPER_LIMIT : int = 999


static func known_section_title(known_count : int, total_count : int) -> String:
	return UiText.of(KNOWN_HEADER_FORMAT) % [known_count, total_count]


static func locked_section_title(locked_count : int) -> String:
	return UiText.of(LOCKED_HEADER_FORMAT) % locked_count


## The index button: name and strength, and how many recipes are saved.
static func index_label(entry : RecipeBookEntry) -> String:
	if not entry.known:
		return UiText.of(INDEX_LOCKED_FORMAT) % entry.beer_style.abv
	var text : String = UiText.of(INDEX_KNOWN_FORMAT) % [UiText.of(entry.beer_style.style_name), entry.beer_style.abv]
	if entry.saved_recipe_count > 0:
		text = UiText.of(INDEX_RECIPES_FORMAT) % [text, entry.saved_recipe_count]
	return text


static func page_title(entry : RecipeBookEntry) -> String:
	return UiText.of(entry.beer_style.style_name) if entry.known else UiText.of(LOCKED_TITLE)


## A known style's page, one fact per line.
static func known_lines(entry : RecipeBookEntry) -> PackedStringArray:
	var style : BeerStyle = entry.beer_style
	var lines : PackedStringArray = []
	if not style.description.is_empty():
		lines.append(UiText.of(style.description))
	lines.append(UiText.of(STRENGTH_FORMAT) % abv_range(style.min_abv, style.max_abv))
	lines.append(UiText.of(COLOR_FORMAT) % value_range(style.min_ebc, style.max_ebc))
	lines.append(UiText.of(BITTERNESS_FORMAT) % value_range(style.min_ibu, style.max_ibu))
	lines.append(UiText.of(YEAST_FORMAT) % entry.yeast_name)
	if not entry.base_malt_names.is_empty():
		lines.append(UiText.of(BASE_MALT_FORMAT) % [BASE_MALT_SEPARATOR.join(entry.base_malt_names), roundi(style.min_base_share * 100.0)])
	_append_requirements(lines, entry)
	if not entry.character_malt_names.is_empty():
		lines.append(UiText.of(CHARACTER_MALTS_FORMAT) % [roundi(BrewQuality.MALT_MATCH_STEP * 100.0), LIST_SEPARATOR.join(entry.character_malt_names)])
	_append_hops(lines, style)
	if style.forbids_spices:
		lines.append(UiText.of(PURITY_LAW_HINT))
	elif not entry.preferred_spice_names.is_empty():
		lines.append(UiText.of(PREFERRED_SPICES_FORMAT) % LIST_SEPARATOR.join(entry.preferred_spice_names))
	lines.append(UiText.of(MASH_FORMAT) % mash_steps(style.mash_steps))
	if not style.hop_additions.is_empty():
		lines.append(UiText.of(HOPPING_FORMAT) % hop_additions(style.hop_additions))
	if entry.needs_mash_upgrade:
		lines.append(UiText.of(MASH_UPGRADE_HINT))
	return lines


## A locked style's page: hints, never the exact ranges unless the old master told them.
static func locked_lines(entry : RecipeBookEntry) -> PackedStringArray:
	var style : BeerStyle = entry.beer_style
	var lines : PackedStringArray = []
	if not style.locked_hint.is_empty():
		lines.append(UiText.of(style.locked_hint))
	lines.append_array([
		UiText.of(LOCKED_STRENGTH_FORMAT) % style.abv,
		UiText.of(COLOR_HINT_FORMAT) % UiText.of(BeerStyle.get_color_hint(style.min_ebc, style.max_ebc)),
		UiText.of(BITTERNESS_HINT_FORMAT) % UiText.of(BeerStyle.get_bitterness_hint(style.min_ibu, style.max_ibu)),
		UiText.of(YEAST_FORMAT) % entry.yeast_name,
	])
	_append_requirements(lines, entry)
	if style.required_malt_id == BrewMixture.NO_REQUIRED_MALT and entry.needs_malt_blend:
		lines.append(UiText.of(MALT_BLEND_HINT))
	_append_hops(lines, style)
	if entry.hinted:
		lines.append(UiText.of(MASTER_HINT_FORMAT) % [value_range(style.min_ebc, style.max_ebc), value_range(style.min_ibu, style.max_ibu)])
	if entry.needs_mash_upgrade:
		lines.append(UiText.of(MASH_UPGRADE_HINT))
	if entry.attracts_new_customer:
		lines.append(UiText.of(NEW_CUSTOMER_HINT))
	return lines


## "11-14", or "0+" when the style sets no upper limit.
static func value_range(min_value : int, max_value : int) -> String:
	if max_value >= NO_UPPER_LIMIT:
		return "%d+" % min_value
	return "%d-%d" % [min_value, max_value]


static func abv_range(min_abv : float, max_abv : float) -> String:
	return "%.1f-%.1f" % [min_abv, max_abv]


static func mash_steps(steps : Array[int]) -> String:
	var parts : PackedStringArray = []
	for temperature : int in steps:
		parts.append(MASH_STEP_FORMAT % temperature)
	return LIST_SEPARATOR.join(parts)


static func hop_additions(kinds : Array[HopAddition.Kind]) -> String:
	var parts : PackedStringArray = []
	for kind : HopAddition.Kind in kinds:
		var name : String = _addition_name(kind)
		if not name.is_empty():
			parts.append(UiText.of(name))
	return LIST_SEPARATOR.join(parts)


static func _addition_name(kind : HopAddition.Kind) -> String:
	match kind:
		HopAddition.Kind.BITTERING: return BITTERING_ADDITION_TEXT
		HopAddition.Kind.FLAVOR: return FLAVOR_ADDITION_TEXT
		HopAddition.Kind.AROMA: return AROMA_ADDITION_TEXT
		HopAddition.Kind.DRY_HOP: return DRY_HOP_ADDITION_TEXT
	return ""


static func _append_requirements(lines : PackedStringArray, entry : RecipeBookEntry) -> void:
	if not entry.required_malt_name.is_empty():
		lines.append(UiText.of(REQUIRED_MALT_FORMAT) % entry.required_malt_name)
	if not entry.required_spice_names.is_empty():
		lines.append(UiText.of(REQUIRED_SPICE_FORMAT) % LIST_SEPARATOR.join(entry.required_spice_names))


static func _append_hops(lines : PackedStringArray, style : BeerStyle) -> void:
	if not style.preferred_hop_profiles.is_empty():
		var names : PackedStringArray = []
		for profile : HopData.FlavorProfile in style.preferred_hop_profiles:
			names.append(HopData.get_flavor_profile_display_name(profile))
		lines.append(UiText.of(HOP_HINT_FORMAT) % LIST_SEPARATOR.join(names))
	if style.requires_aroma_hop:
		lines.append(UiText.of(AROMA_HOP_NEEDED))
