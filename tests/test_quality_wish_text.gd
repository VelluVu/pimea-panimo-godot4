@tool
extends McpTestSuite

## Unit tests for QualityWishText: the reject suffix and the too-weak tooltip line.

const TextScript := preload("res://src/customers/quality_wish_text.gd")


func suite_name() -> String:
	return "quality_wish_text"


func _customer(title : String, min_quality : float) -> CustomerData:
	var data := CustomerData.new()
	data.title = title
	data.min_quality = min_quality
	return data


func test_no_suffix_when_bar_is_met() -> void:
	assert_eq(TextScript.reject_suffix(1.1, 1.1), "")
	assert_eq(TextScript.reject_suffix(1.3, 1.1), "")


func test_suffix_shows_quality_and_bar_in_percent() -> void:
	assert_eq(TextScript.reject_suffix(0.98, 1.1), " (Laatu 98 %, toivoi 110 %)")


func test_near_miss_never_rounds_up_to_the_bar() -> void:
	assert_eq(TextScript.reject_suffix(1.096, 1.1), " (Laatu 109 %, toivoi 110 %)")


func test_too_weak_line_lists_missed_titles_once() -> void:
	var customers : Array[CustomerData] = [
		_customer("Kriitikko", 1.15),
		_customer("Hipsteri", 1.1),
		_customer("Hipsteri", 1.1),
		_customer("Opiskelija", 0.05),
	]
	assert_eq(TextScript.too_weak_line(1.0, customers), "\nLiian heikkoa: Kriitikko, Hipsteri")


func test_too_weak_line_empty_when_all_satisfied() -> void:
	var customers : Array[CustomerData] = [_customer("Kriitikko", 1.15)]
	assert_eq(TextScript.too_weak_line(1.2, customers), "")


func test_untitled_customer_uses_its_name() -> void:
	var data := _customer("", 1.0)
	data.customer_name = "Pertti"
	var customers : Array[CustomerData] = [data]
	assert_eq(TextScript.too_weak_line(0.5, customers), "\nLiian heikkoa: Pertti")
