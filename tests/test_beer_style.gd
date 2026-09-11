@tool
extends McpTestSuite

## Unit tests for BeerStyle's pure style-name lookup, including the two
## non-alcoholic styles (Alkoholiton IPA/Lager) added this session and the
## "unknown style" fallback.


func suite_name() -> String:
	return "beer_style"


func test_get_style_string_for_known_style() -> void:
	assert_eq(BeerStyle.get_style_string_from_style(BeerStyle.Style.IPA), StringContainer.IPA)


func test_get_style_string_for_alkoholiton_ipa() -> void:
	assert_eq(BeerStyle.get_style_string_from_style(BeerStyle.Style.ALKOHOLITON_IPA), StringContainer.ALKOHOLITONIPA)


func test_get_style_string_for_alkoholiton_lager() -> void:
	assert_eq(BeerStyle.get_style_string_from_style(BeerStyle.Style.ALKOHOLITON_LAGER), StringContainer.ALKOHOLITONLAGER)


func test_get_style_string_falls_back_to_tuntematon_for_invalid_value() -> void:
	assert_eq(BeerStyle.get_style_string_from_style(9999 as BeerStyle.Style), StringContainer.TUNTEMATON)


func test_instance_method_matches_static_helper() -> void:
	var style := BeerStyle.new()
	style.style = BeerStyle.Style.HELLES
	assert_eq(style.get_style_string(), StringContainer.HELLES)
