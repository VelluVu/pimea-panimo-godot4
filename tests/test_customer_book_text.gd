@tool
extends McpTestSuite

## Unit tests for CustomerBookText: what the Asiakaskirja says about a customer.

const TextScript := preload("res://src/ui/customer_book_text.gd")

const NAMES : Dictionary = {
	BeerStyle.Style.KOTIKALJA: "Kotikalja",
	BeerStyle.Style.SESSION_ALE: "Session Ale",
	BeerStyle.Style.HELLES: "Helles",
}


func suite_name() -> String:
	return "customer_book_text"


func _customer(title : String) -> CustomerData:
	var data := CustomerData.new()
	data.title = title
	data.primary_style = BeerStyle.Style.KOTIKALJA
	data.secondary_style = BeerStyle.Style.SESSION_ALE
	data.min_quality = 0.3
	return data


func test_unmet_customer_hides_tastes() -> void:
	assert_eq(TextScript.lines(_customer("Opiskelija"), false, NAMES), PackedStringArray([TextScript.NOT_MET_TEXT]))


func test_met_customer_shows_favourites_and_quality() -> void:
	var lines : PackedStringArray = TextScript.lines(_customer("Opiskelija"), true, NAMES)
	assert_eq(lines, PackedStringArray(["Suosikki: Kotikalja", "Käy myös: Session Ale", "Laatutoive: vähintään 30 %"]))


func test_rerolling_customer_says_it_varies() -> void:
	var data := _customer("Kriitikko")
	data.randomizes_preference = true
	var lines : PackedStringArray = TextScript.lines(data, true, NAMES)
	assert_eq(lines[0], TextScript.VARYING_FAVOURITE_TEXT)
	assert_false(lines.has("Suosikki: Kotikalja"))


func test_strict_limits_are_listed() -> void:
	var data := _customer("Opiskelija")
	data.max_required_price = 2.5
	data.min_required_abv = 5.0
	data.accepted_styles = [BeerStyle.Style.HELLES]
	var lines : PackedStringArray = TextScript.lines(data, true, NAMES)
	assert_true(lines.has("Juo vain: Helles"))
	assert_true(lines.has("Vähintään 5.0 % alkoholia"))
	assert_true(lines.has("Enintään 2.50 € annokselta"))


func test_one_entry_per_title() -> void:
	var customers : Array[CustomerData] = [_customer("Hipsteri"), _customer("Hipsteri"), _customer("Munkki")]
	var unique : Array[CustomerData] = TextScript.unique_by_title(customers)
	assert_eq(unique.size(), 2)
	assert_eq(unique[1].title, "Munkki")


func test_locked_line_is_empty_when_all_known() -> void:
	assert_eq(TextScript.locked_line(0), "")
	assert_eq(TextScript.locked_line(3), "3 asiakastyyppiä vielä tuntematta.")


func test_also_liked_styles_join_the_second_line() -> void:
	var data := _customer("Mustanmetallinmies")
	data.also_likes = [BeerStyle.Style.HELLES]
	var lines : PackedStringArray = TextScript.lines(data, true, NAMES)
	assert_true(lines.has("Käy myös: Session Ale, Helles"))


func test_a_risk_lowering_favourite_is_mentioned() -> void:
	var plain := _customer("Raksamies")
	assert_false(TextScript.lines(plain, true, NAMES).has("Suosikki laskee LVV-riskiä"))
	var sober := _customer("Zgen")
	sober.risk_primary_style = -2
	assert_true(TextScript.lines(sober, true, NAMES).has("Suosikki laskee LVV-riskiä"))
