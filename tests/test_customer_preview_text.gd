@tool
extends McpTestSuite

## Unit tests for CustomerPreviewText: the customer's line before the sale.

const CustomerPreviewTextScript := preload("res://src/ui/customer_preview_text.gd")


func suite_name() -> String:
	return "customer_preview_text"


func _data() -> CustomerData:
	var data := CustomerData.new()
	data.dialogue_preview_format = "Otan %s."
	data.dialogue_nothing_available = "Ei mitään."
	return data


func test_one_style_is_named() -> void:
	assert_eq(CustomerPreviewTextScript.line(_data(), PackedStringArray(["Pilsner"])), "Otan Pilsner.")


func test_several_styles_are_joined() -> void:
	assert_eq(CustomerPreviewTextScript.line(_data(), PackedStringArray(["Pilsner", "Helles"])), "Otan Pilsner ja Helles.")


func test_no_styles_means_nothing_suits() -> void:
	assert_eq(CustomerPreviewTextScript.line(_data(), PackedStringArray()), "Ei mitään.")


func test_a_browser_never_names_a_style() -> void:
	var data := _data()
	data.browses_only = true
	assert_eq(CustomerPreviewTextScript.line(data, PackedStringArray(["Pilsner"])), "Ei mitään.")
