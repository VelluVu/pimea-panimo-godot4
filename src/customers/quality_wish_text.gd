class_name QualityWishText
extends RefCounted

## Shows customers' quality bars in the same percent the batch tooltip uses, so a
## quality rejection can be understood and avoided instead of feeling random.

const REJECT_SUFFIX_FORMAT : String = " (Laatu %d %%, toivoi %d %%)"
const TOO_WEAK_FORMAT : String = "Liian heikkoa: %s"
const TITLE_SEPARATOR : String = ", "


## Appended to a customer's reaction when the batch missed their bar; empty otherwise.
static func reject_suffix(quality : float, min_quality : float) -> String:
	if quality >= min_quality:
		return ""
	var wanted : int = roundi(min_quality * 100.0)
	# Rounding must not show a miss as equal to the bar (109.6 % vs 110 %).
	var got : int = mini(roundi(quality * 100.0), wanted - 1)
	return UiText.of(REJECT_SUFFIX_FORMAT) % [got, wanted]


## A tooltip line naming the customers whose bar `quality` misses, each title once;
## empty when the batch satisfies all of them.
static func too_weak_line(quality : float, customers : Array[CustomerData]) -> String:
	var titles : PackedStringArray = []
	for customer : CustomerData in customers:
		var title : String = UiText.of(customer.title) if not customer.title.is_empty() else customer.customer_name
		if quality < customer.min_quality and not titles.has(title):
			titles.append(title)
	if titles.is_empty():
		return ""
	return "\n" + UiText.of(TOO_WEAK_FORMAT) % TITLE_SEPARATOR.join(titles)
