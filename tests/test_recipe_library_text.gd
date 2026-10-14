@tool
extends McpTestSuite

## Unit tests for RecipeLibraryText: the recipe book's index buttons and style pages.

const RecipeLibraryTextScript := preload("res://src/ui/recipe_library_text.gd")


func suite_name() -> String:
	return "recipe_library_text"


func _make_style() -> BeerStyle:
	var beer_style := BeerStyle.new()
	beer_style.style_name = "Testiolut"
	beer_style.abv = 4.5
	beer_style.min_abv = 4.0
	beer_style.max_abv = 5.5
	beer_style.min_ebc = 11
	beer_style.max_ebc = 14
	beer_style.min_ibu = 14
	beer_style.max_ibu = 20
	beer_style.mash_steps = [63, 72]
	var additions : Array[HopAddition.Kind] = [HopAddition.Kind.BITTERING, HopAddition.Kind.AROMA]
	beer_style.hop_additions = additions
	return beer_style


func _entry(known : bool = true) -> RecipeBookEntry:
	var entry := RecipeBookEntry.new()
	entry.beer_style = _make_style()
	entry.known = known
	entry.yeast_name = "Lagerhiiva"
	return entry


func _page(entry : RecipeBookEntry) -> String:
	var lines : PackedStringArray = RecipeLibraryTextScript.known_lines(entry) if entry.known else RecipeLibraryTextScript.locked_lines(entry)
	return "\n".join(lines)


func test_a_known_index_button_shows_name_strength_and_recipes() -> void:
	var entry := _entry()
	assert_eq(RecipeLibraryTextScript.index_label(entry), "Testiolut\n4.5 %")
	entry.saved_recipe_count = 2
	assert_eq(RecipeLibraryTextScript.index_label(entry), "Testiolut\n4.5 % · reseptejä 2")


func test_a_locked_index_button_hides_the_name() -> void:
	assert_eq(RecipeLibraryTextScript.index_label(_entry(false)), "???\n4.5 %")
	assert_eq(RecipeLibraryTextScript.page_title(_entry(false)), "???")


func test_a_known_page_shows_the_exact_recipe() -> void:
	var text : String = _page(_entry())
	assert_contains(text, "Vahvuus: 4.0-5.5 % ABV")
	assert_contains(text, "Väri: EBC 11-14")
	assert_contains(text, "Katkeruus: IBU 14-20")
	assert_contains(text, "Hiiva: Lagerhiiva")
	assert_contains(text, "Mäskäys: 63 °C, 72 °C")
	assert_contains(text, "Humalointi: katkero, aromi")


func test_a_known_page_names_base_malts_favourites_and_requirements() -> void:
	var entry := _entry()
	entry.beer_style.min_base_share = 0.5
	entry.base_malt_names = ["Münchenin mallas"]
	entry.favourite_malt_names = ["Münchenin mallas", "Vienna mallas"]
	entry.required_spice_name = "Laktoosi"
	var text : String = _page(entry)
	assert_contains(text, "Pohjamallas: Münchenin mallas, vähintään 50 % maltaista")
	assert_contains(text, "Suosikkimaltaat: Münchenin mallas, Vienna mallas")
	assert_contains(text, "Vaatii myös: Laktoosi")


func test_hops_are_listed_and_an_aroma_hop_noted() -> void:
	var entry := _entry()
	entry.beer_style.preferred_hop_profiles = [HopData.FlavorProfile.CITRUS]
	entry.beer_style.requires_aroma_hop = true
	var text : String = _page(entry)
	assert_contains(text, "Suosikkihumalat:")
	assert_contains(text, "Tarvitsee aromihumalan")


func test_the_purity_law_replaces_the_spices() -> void:
	var entry := _entry()
	entry.preferred_spice_names = ["Korianteri"]
	assert_contains(_page(entry), "Sopivat mausteet: Korianteri")
	entry.beer_style.forbids_spices = true
	assert_contains(_page(entry), "Reinheitsgebot: ei mausteita")
	assert_false(_page(entry).contains("Korianteri"))


func test_a_description_leads_the_page_when_written() -> void:
	var entry := _entry()
	assert_false(_page(entry).begins_with("Kuvaus"))
	entry.beer_style.description = "Kuvaus oluesta."
	assert_true(_page(entry).begins_with("Kuvaus oluesta."))


func test_a_locked_page_withholds_the_exact_ranges() -> void:
	var text : String = _page(_entry(false))
	assert_contains(text, "Vahvuus: noin 4.5 % ABV")
	assert_contains(text, "Väri: %s" % BeerStyle.get_color_hint(11, 14))
	assert_false(text.contains("EBC"), "the exact EBC range stays hidden")
	assert_false(text.contains("14-20"), "the exact IBU range stays hidden")


func test_the_old_master_reveals_the_ranges_of_a_locked_style() -> void:
	var entry := _entry(false)
	entry.hinted = true
	assert_contains(_page(entry), "Aatun vinkki: EBC 11-14, IBU 14-20")


func test_locked_hints_only_when_they_apply() -> void:
	var entry := _entry(false)
	assert_false(_page(entry).contains("Vaatii mallasseoksen"))
	assert_false(_page(entry).contains("Houkuttelee uuden asiakkaan"))
	entry.needs_malt_blend = true
	entry.attracts_new_customer = true
	assert_contains(_page(entry), "Vaatii mallasseoksen")
	assert_true(_page(entry).ends_with("Houkuttelee uuden asiakkaan"))


func test_a_style_too_heavy_for_the_mash_tun_says_so() -> void:
	for known : bool in [true, false]:
		var entry := _entry(known)
		assert_false(_page(entry).contains("mäskipadan"))
		entry.needs_mash_upgrade = true
		assert_contains(_page(entry), "Vaatii mäskipadan päivityksen")


func test_value_range_shows_an_open_upper_limit_as_plus() -> void:
	assert_eq(RecipeLibraryTextScript.value_range(11, 14), "11-14")
	assert_eq(RecipeLibraryTextScript.value_range(0, RecipeLibraryTextScript.NO_UPPER_LIMIT), "0+")


func test_section_titles_show_the_counts() -> void:
	assert_eq(RecipeLibraryTextScript.known_section_title(3, 27), "Löydetyt tyylit (3/27)")
	assert_eq(RecipeLibraryTextScript.locked_section_title(24), "Löytämättömät tyylit (24)")


func test_a_locked_page_leads_with_its_hint_and_never_the_description() -> void:
	var entry := _entry(false)
	entry.beer_style.description = "Kuvaus oluesta."
	assert_false(_page(entry).contains("Kuvaus oluesta."), "the description waits for the discovery")
	entry.beer_style.locked_hint = "Vihje oluesta."
	assert_true(_page(entry).begins_with("Vihje oluesta."))
	assert_false(_page(_entry()).contains("Vihje"), "a known page has no hint")
